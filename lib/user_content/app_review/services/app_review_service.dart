import 'dart:async';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/native_review_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/view/provide_feedback_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/view/rate_app_bottom_sheet.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template app_review_service}
/// A service that encapsulates the business logic for the app review funnel.
///
/// This service manages when and how to prompt the user for a review,
/// handles their responses, and interacts with the native review APIs.
/// {@endtemplate}
class AppReviewService {
  /// {@macro app_review_service}
  AppReviewService({
    required DataRepository<AppReview> appReviewRepository,
    required NativeReviewService nativeReviewService,
    required KVStorageService kvStorageService,
    Logger? logger,
  }) : _appReviewRepository = appReviewRepository,
       _nativeReviewService = nativeReviewService,
       _kvStorageService = kvStorageService,
       _logger = logger ?? Logger('AppReviewService');

  final DataRepository<AppReview> _appReviewRepository;
  final NativeReviewService _nativeReviewService;
  final KVStorageService _kvStorageService;
  final Logger _logger;

  static const _positiveInteractionCountKey = 'positive_interaction_count_key';

  /// Increments the count of positive user interactions.
  ///
  /// This count is persisted in [KVStorageService] and is used to determine
  /// eligibility for the review prompt based on the `positiveInteractionThreshold`.
  Future<void> incrementPositiveInteractionCount() async {
    try {
      final currentCount =
          await _kvStorageService.readInt(key: _positiveInteractionCountKey) ??
          0;
      await _kvStorageService.writeInt(
        key: _positiveInteractionCountKey,
        value: currentCount + 1,
      );
      _logger.fine(
        'Positive interaction count incremented to ${currentCount + 1}.',
      );
    } catch (e, s) {
      _logger.severe('Failed to increment positive interaction count.', e, s);
    }
  }

  /// Checks if the user is eligible for a review prompt and, if so, triggers it.
  ///
  /// This method is the main entry point for the review funnel. It should be
  /// called after a positive user interaction (e.g., saving an article).
  Future<void> checkEligibilityAndTrigger({
    required BuildContext context,
  }) async {
    final appState = context.read<AppBloc>().state;
    final user = appState.user;
    final remoteConfig = appState.remoteConfig;

    if (user == null || remoteConfig == null) {
      _logger.warning(
        'Cannot check eligibility: user or remoteConfig is null.',
      );
      return;
    }

    final appReviewConfig = remoteConfig.features.community.appReview;
    if (!appReviewConfig.enabled) {
      _logger.fine('App review feature is disabled.');
      return;
    }

    // Check if the user has already completed the rateApp decorator.
    final decoratorStatus = user.feedDecoratorStatus[FeedDecoratorType.rateApp];
    if (decoratorStatus?.isCompleted == true) {
      _logger.fine('User has already completed the review funnel.');
      return;
    }

    // Check initial cooldown.
    final daysSinceCreation = DateTime.now().difference(user.createdAt).inDays;
    if (daysSinceCreation < appReviewConfig.initialPromptCooldownDays) {
      _logger.fine(
        'User is within the initial cooldown period ($daysSinceCreation/${appReviewConfig.initialPromptCooldownDays} days).',
      );
      return;
    }

    // Check positive interaction threshold.
    final interactionCount =
        await _kvStorageService.readInt(key: _positiveInteractionCountKey) ?? 0;
    if (interactionCount < appReviewConfig.positiveInteractionThreshold ||
        interactionCount % appReviewConfig.positiveInteractionThreshold != 0) {
      _logger.fine(
        'Interaction count ($interactionCount) does not meet threshold '
        '(${appReviewConfig.positiveInteractionThreshold}).',
      );
      return;
    }

    _logger.info('User is eligible for review prompt. Showing bottom sheet.');
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => RateAppBottomSheet(
          onResponse: (isPositive) => _handleInitialPromptResponse(
            context: context,
            isPositive: isPositive,
          ),
        ),
      ),
    );
  }

  /// Handles the user's response from the initial "Enjoying the app?" prompt.
  Future<void> _handleInitialPromptResponse({
    required BuildContext context,
    required bool isPositive,
  }) async {
    final appBloc = context.read<AppBloc>();
    final userId = appBloc.state.user?.id;
    if (userId == null) return;

    if (isPositive) {
      _logger.info('User responded positively. Requesting native review.');

      // Create the AppReview record first to log the positive interaction.
      final review = AppReview(
        id: const Uuid().v4(),
        userId: userId,
        feedback: AppReviewFeedback.positive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _appReviewRepository.create(item: review, userId: userId);

      // Now, request the native review prompt.
      final wasRequested = await _nativeReviewService.requestReview();

      // If the OS-level prompt was successfully requested, update our record.
      if (wasRequested) {
        await _appReviewRepository.update(
          id: review.id,
          item: review.copyWith(wasStoreReviewRequested: true),
          userId: userId,
        );
      }

      // Mark the funnel as complete for this user, regardless of whether the
      // OS showed the prompt, to respect the user's interaction.
      appBloc.add(
        AppUserFeedDecoratorShown(
          userId: userId,
          feedDecoratorType: FeedDecoratorType.rateApp,
          isCompleted: true,
        ),
      );
    } else {
      _logger.info('User responded negatively. Showing feedback sheet.');
      // Create the AppReview record first to log the negative interaction.
      final review = AppReview(
        id: const Uuid().v4(),
        userId: userId,
        feedback: AppReviewFeedback.negative,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _appReviewRepository.create(item: review, userId: userId);

      // Show the detailed feedback bottom sheet.
      // Guard against using context across async gaps.
      if (!context.mounted) return;
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => ProvideFeedbackBottomSheet(
            onFeedbackSubmitted: (details) => _handleNegativeFeedback(
              reviewId: review.id,
              userId: userId,
              details: details,
            ),
          ),
        ),
      );
    }
  }

  /// Handles the submission of detailed negative feedback.
  Future<void> _handleNegativeFeedback({
    required String reviewId,
    required String userId,
    required String details,
  }) async {
    _logger.info('User submitted negative feedback: "$details"');
    try {
      // Read the existing review record that was created when the user
      // responded "No".
      final existingReview = await _appReviewRepository.read(
        id: reviewId,
        userId: userId,
      );

      // Update the existing record with the feedback details.
      await _appReviewRepository.update(
        id: reviewId,
        item: existingReview.copyWith(
          feedbackDetails: details,
          updatedAt: DateTime.now(),
        ),
        userId: userId,
      );
      _logger.fine('Negative feedback persisted for user $userId.');
    } catch (e, s) {
      _logger.severe('Failed to persist negative feedback.', e, s);
    }
  }
}
