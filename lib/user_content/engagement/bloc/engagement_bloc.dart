import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

part 'engagement_event.dart';
part 'engagement_state.dart';

/// {@template engagement_bloc}
/// Manages the state for user engagement (reactions and comments) on a
/// single engageable entity, such as a headline.
/// {@endtemplate}
class EngagementBloc extends Bloc<EngagementEvent, EngagementState> {
  /// {@macro engagement_bloc}
  EngagementBloc({
    required String entityId,
    required EngageableType entityType,
    required DataRepository<Engagement> engagementRepository,
    required ContentLimitationService contentLimitationService,
    required AppBloc appBloc,
    Logger? logger,
  }) : _entityId = entityId,
       _entityType = entityType,
       _engagementRepository = engagementRepository,
       _contentLimitationService = contentLimitationService,
       _appBloc = appBloc,
       _logger = logger ?? Logger('EngagementBloc'),
       super(const EngagementState()) {
    on<EngagementStarted>(_onEngagementStarted);
    on<EngagementReactionUpdated>(_onEngagementReactionUpdated);
    on<EngagementCommentPosted>(_onEngagementCommentPosted);
    on<EngagementQuickReactionToggled>(_onEngagementQuickReactionToggled);
  }

  final String _entityId;
  final EngageableType _entityType;
  final DataRepository<Engagement> _engagementRepository;
  final ContentLimitationService _contentLimitationService;
  final AppBloc _appBloc;
  final Logger _logger;

  Future<void> _onEngagementStarted(
    EngagementStarted event,
    Emitter<EngagementState> emit,
  ) async {
    emit(state.copyWith(status: EngagementStatus.loading));
    final userId = _appBloc.state.user?.id;
    try {
      final response = await _engagementRepository.readAll(
        filter: {'entityId': _entityId},
        userId: userId,
      );
      final engagements = response.items;
      final userEngagement = engagements.firstWhereOrNull(
        (e) => e.userId == userId,
      );

      emit(
        state.copyWith(
          status: EngagementStatus.success,
          engagements: engagements,
          userEngagement: userEngagement,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('Failed to fetch engagements', e, s);
      emit(state.copyWith(status: EngagementStatus.failure, error: e));
    }
  }

  Future<void> _onEngagementReactionUpdated(
    EngagementReactionUpdated event,
    Emitter<EngagementState> emit,
  ) async {
    final userId = _appBloc.state.user?.id;
    final originalUserEngagement = state.userEngagement;
    if (userId == null) return;

    emit(state.copyWith(status: EngagementStatus.actionInProgress));

    final preCheckStatus = await _contentLimitationService.checkAction(
      ContentAction.reactToContent,
    );
    if (preCheckStatus != LimitationStatus.allowed) {
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          limitationStatus: preCheckStatus,
        ),
      );
      return;
    }
    try {
      if (state.userEngagement != null) {
        // User is updating or removing their reaction.
        final isTogglingOff =
            event.reactionType == null ||
            state.userEngagement!.reaction?.reactionType == event.reactionType;

        Engagement? updatedEngagement;
        if (isTogglingOff) {
          // Optimistically remove the reaction from the UI.
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              clearUserEngagement: true,
            ),
          );
          await _engagementRepository.delete(id: state.userEngagement!.id);
        } else {
          // Optimistically update the reaction in the UI.
          updatedEngagement = state.userEngagement!.copyWith(
            reaction: ValueWrapper(Reaction(reactionType: event.reactionType!)),
          );
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              userEngagement: updatedEngagement,
            ),
          );
          await _engagementRepository.update(
            id: updatedEngagement.id,
            item: updatedEngagement,
          );
        }
      } else if (event.reactionType != null) {
        // User is adding a new reaction.
        final newEngagement = Engagement(
          id: const Uuid().v4(),
          userId: userId,
          entityId: _entityId,
          entityType: _entityType,
          reaction: Reaction(reactionType: event.reactionType!),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // Optimistically add the new reaction to the UI.
        emit(
          state.copyWith(
            status: EngagementStatus.success,
            userEngagement: newEngagement,
          ),
        );
        final created = await _engagementRepository.create(item: newEngagement);
        // Update the state with the server-confirmed engagement, which might
        // have a different ID or timestamps.
        emit(
          state.copyWith(
            status: EngagementStatus.success,
            userEngagement: created,
          ),
        );
      }
    } on HttpException catch (e, s) {
      _logger.severe('Failed to update reaction', e, s);
      var limitationStatus = LimitationStatus.allowed;
      if (e is ForbiddenException) {
        limitationStatus = LimitationStatus.standardUserLimitReached;
      }
      // On failure, roll back to the original state.
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          error: e,
          userEngagement: originalUserEngagement,
          // Reset the main status to success if it's just a limit issue
          // to allow the UI to recover.
          limitationStatus: limitationStatus,
        ),
      );
    }
  }

  Future<void> _onEngagementCommentPosted(
    EngagementCommentPosted event,
    Emitter<EngagementState> emit,
  ) async {
    final userId = _appBloc.state.user?.id;
    final language = _appBloc.state.settings?.language;
    if (userId == null || language == null) {
      return; // Cannot post a comment without a user or language.
    }

    emit(state.copyWith(status: EngagementStatus.actionInProgress));

    final preCheckStatus = await _contentLimitationService.checkAction(
      ContentAction.postComment,
    );
    if (preCheckStatus != LimitationStatus.allowed) {
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          limitationStatus: preCheckStatus,
        ),
      );
      return;
    }

    try {
      final newComment = Comment(language: language, content: event.content);
      Engagement updatedEngagement;

      if (state.userEngagement != null) {
        // User has an existing engagement (e.g., a reaction), so update it.
        updatedEngagement = state.userEngagement!.copyWith(
          comment: ValueWrapper(newComment),
        );

        emit(state.copyWith(status: EngagementStatus.success));

        await _engagementRepository.update(
          id: updatedEngagement.id,
          item: updatedEngagement,
        );
      } else {
        // No existing engagement, create a new one with just the comment.
        updatedEngagement = Engagement(
          id: const Uuid().v4(),
          userId: userId,
          entityId: _entityId,
          entityType: _entityType,
          comment: newComment,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        emit(state.copyWith(status: EngagementStatus.success));
        await _engagementRepository.create(
          item: updatedEngagement,
          userId: userId,
        );
      }

      // Re-fetch to get the full list with the new comment included.
      final response = await _engagementRepository.readAll(
        filter: {'entityId': _entityId},
        userId: userId,
      );
      emit(
        state.copyWith(
          engagements: response.items,
          userEngagement: response.items.firstWhereOrNull(
            (e) => e.userId == userId,
          ),
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('Failed to post comment', e, s);
      var limitationStatus = LimitationStatus.allowed;
      if (e is ForbiddenException) {
        limitationStatus = LimitationStatus.standardUserLimitReached;
      }
      // On failure, we can simply show an error. The optimistic update will
      // be corrected on the next full refresh.
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          error: e,
          limitationStatus: limitationStatus,
        ),
      );
    }
  }

  Future<void> _onEngagementQuickReactionToggled(
    EngagementQuickReactionToggled event,
    Emitter<EngagementState> emit,
  ) async {
    final userId = _appBloc.state.user?.id;
    final originalUserEngagement = state.userEngagement;
    if (userId == null) return;

    emit(state.copyWith(status: EngagementStatus.actionInProgress));

    final preCheckStatus = await _contentLimitationService.checkAction(
      ContentAction.reactToContent,
    );
    if (preCheckStatus != LimitationStatus.allowed) {
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          limitationStatus: preCheckStatus,
        ),
      );
      return;
    }

    try {
      if (state.userEngagement != null) {
        // User has an existing engagement.
        final isTogglingOff =
            state.userEngagement!.reaction?.reactionType == event.reactionType;

        if (isTogglingOff) {
          // Optimistically remove the reaction.
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              clearUserEngagement: true,
            ),
          );
          await _engagementRepository.delete(id: state.userEngagement!.id);
        } else {
          // Optimistically update to the new reaction.
          final updated = state.userEngagement!.copyWith(
            reaction: ValueWrapper(Reaction(reactionType: event.reactionType)),
          );
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              userEngagement: updated,
            ),
          );
          await _engagementRepository.update(id: updated.id, item: updated);
        }
      } else {
        // No existing engagement, create a new one.
        final newEngagement = Engagement(
          id: const Uuid().v4(),
          userId: userId,
          entityId: _entityId,
          entityType: _entityType,
          reaction: Reaction(reactionType: event.reactionType),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // Optimistically add the new reaction.
        emit(
          state.copyWith(
            status: EngagementStatus.success,
            userEngagement: newEngagement,
          ),
        );
        final created = await _engagementRepository.create(item: newEngagement);
        // Update state with the server-confirmed object.
        emit(state.copyWith(userEngagement: created));
      }
    } on HttpException catch (e, s) {
      _logger.severe('Failed to toggle quick reaction', e, s);
      var limitationStatus = LimitationStatus.allowed;
      if (e is ForbiddenException) {
        limitationStatus = LimitationStatus.standardUserLimitReached;
      }
      // On failure, roll back to the original state.
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          error: e,
          userEngagement: originalUserEngagement,
          // Reset the main status to success if it's just a limit issue
          // to allow the UI to recover.
          limitationStatus: limitationStatus,
        ),
      );
    }
  }
}
