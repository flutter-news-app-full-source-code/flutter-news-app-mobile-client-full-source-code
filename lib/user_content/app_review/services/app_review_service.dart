import 'dart:async';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/native_review_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/view/provide_feedback_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/view/rate_app_bottom_sheet.dart';
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
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : _appReviewRepository = appReviewRepository,
       _nativeReviewService = nativeReviewService,
       _analyticsService = analyticsService,
       _logger = logger ?? Logger('AppReviewService');

  final DataRepository<AppReview> _appReviewRepository;
  final NativeReviewService _nativeReviewService;
  final AnalyticsService _analyticsService;
  final Logger _logger;

  /// Checks if the user is eligible for a review prompt and, if so, triggers it.
  ///
  /// This method is the main entry point for the review funnel. It should be
  /// called after a positive user interaction (e.g., saving an article).
  Future<void> checkEligibilityAndTrigger({
    required BuildContext context,
    required int positiveInteractionCount,
  }) async {
    final appState = context.read<AppBloc>().state;
    final user = appState.user;
    final userContext = appState.userContext;
    final environment = context.read<AppEnvironment>();
    final remoteConfig = appState.remoteConfig;

    if (user == null || userContext == null || remoteConfig == null) {
      _logger.warning(
        'Cannot check eligibility: user or userContext or remoteConfig is null.',
      );
      return;
    }

    final communityConfig = remoteConfig.features.community;
    // The app review feature should be disabled if the entire community
    // feature set is disabled.
    if (!communityConfig.enabled) {
      _logger.fine(
        'App review feature is disabled because the parent '
        'community feature is disabled.',
      );
      return;
    }
    if (!communityConfig.appReview.enabled) {
      _logger.fine('App review feature is disabled by its own config.');
      return;
    }

    // Check if the user has already completed the rateApp decorator.
    final decoratorStatus =
        userContext.feedDecoratorStatus[FeedDecoratorType.rateApp];
    if (decoratorStatus?.isCompleted == true) {
      _logger.fine('User has already completed the review funnel.');
      return;
    }

    final appReviewConfig = communityConfig.appReview;
    // Check initial cooldown.
    final daysSinceCreation = DateTime.now().difference(user.createdAt).inDays;
    // For the demo environment, we ignore the initial cooldown period.
    if (environment != AppEnvironment.demo) {
      if (daysSinceCreation < appReviewConfig.initialPromptCooldownDays) {
        _logger.fine(
          'User is within the initial cooldown period ($daysSinceCreation/${appReviewConfig.initialPromptCooldownDays} days).',
        );
        return;
      }
    }

    // Check positive interaction threshold.
    if (positiveInteractionCount == 0 ||
        positiveInteractionCount % appReviewConfig.interactionCycleThreshold !=
            0) {
      _logger.fine(
        'Interaction count ($positiveInteractionCount) does not meet threshold '
        'cycle of ${appReviewConfig.interactionCycleThreshold}.',
      );
      return;
    }

    _logger.info('User is eligible for review prompt. Showing bottom sheet.');
    // Use unawaited to explicitly ignore the future returned by showModalBottomSheet.
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

    // Determine if this is the first time the user is seeing the prompt by
    // checking if the decorator status for 'rateApp' has been recorded yet.
    final isFirstPrompt =
        appBloc.state.userContext?.feedDecoratorStatus[FeedDecoratorType
            .rateApp] ==
        null;

    if (isPositive) {
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.appReviewPromptResponded,
          payload: AppReviewPromptRespondedPayload(
            feedback: AppReviewFeedback.positive,
            isFirstPrompt: isFirstPrompt,
          ),
        ),
      );
      _logger.info('User responded positively. Requesting native review.');

      // Create the AppReview record first to log the positive interaction.
      final review = AppReview(
        id: const Uuid().v4(),
        userId: userId,
        feedback: AppReviewFeedback.positive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      unawaited(_appReviewRepository.create(item: review, userId: userId));

      // Now, request the native review prompt.
      final wasRequested = await _nativeReviewService.requestReview();

      // If the OS-level prompt was successfully requested, update our record.
      if (wasRequested) {
        unawaited(
          _analyticsService.logEvent(AnalyticsEvent.appReviewStoreRequested),
        );
        unawaited(
          _appReviewRepository.update(
            id: review.id,
            item: review.copyWith(wasStoreReviewRequested: true),
            userId: userId,
          ),
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
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.appReviewPromptResponded,
          payload: AppReviewPromptRespondedPayload(
            feedback: AppReviewFeedback.negative,
            isFirstPrompt: isFirstPrompt,
          ),
        ),
      );
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
          feedbackDetails: ValueWrapper(details),
          updatedAt: DateTime.now(),
        ),
        userId: userId,
      );
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.appReviewPromptResponded,
          payload: AppReviewPromptRespondedPayload(
            feedback: AppReviewFeedback.negative,
            // This is a follow-up, so it's never the first prompt interaction.
            isFirstPrompt: false,
            feedbackDetails: details,
          ),
        ),
      );
      _logger.fine('Negative feedback persisted for user $userId.');
    } catch (e, s) {
      _logger.severe('Failed to persist negative feedback.', e, s);
    }
  }
}
