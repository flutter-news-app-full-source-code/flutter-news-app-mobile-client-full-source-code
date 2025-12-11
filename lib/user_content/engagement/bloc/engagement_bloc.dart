import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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
  })  : _entityId = entityId,
        _entityType = entityType,
        _engagementRepository = engagementRepository,
        _contentLimitationService = contentLimitationService,
        _appBloc = appBloc,
        _logger = logger ?? Logger('EngagementBloc'),
        super(const EngagementState()) {
    on<EngagementStarted>(_onEngagementStarted);
    on<EngagementReactionUpdated>(_onEngagementReactionUpdated);
    on<EngagementCommentPosted>(_onEngagementCommentPosted);
    on<EngagementCommentUpdated>(_onEngagementCommentUpdated);
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

    final preCheckStatus = await _contentLimitationService.checkAction(
      ContentAction.reactToContent,
    );
    if (preCheckStatus != LimitationStatus.allowed) {
      emit(
        state.copyWith(
          status: EngagementStatus.success, // Keep UI stable
          limitationStatus: preCheckStatus,
        ),
      );
      return;
    }

    emit(state.copyWith(status: EngagementStatus.actionInProgress));
    try {
      if (state.userEngagement != null) {
        // User is updating or removing their reaction.
        final isTogglingOff = event.reactionType == null ||
            state.userEngagement!.reaction?.reactionType == event.reactionType;

        if (isTogglingOff) {
          // Optimistically remove the reaction.
          final engagementToDelete = state.userEngagement!;
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              clearUserEngagement: true,
            ),
          );
          // If the engagement only had a reaction, delete it.
          // Otherwise, just remove the reaction field.
          if (engagementToDelete.comment == null) {
            await _engagementRepository.delete(
              id: engagementToDelete.id,
              userId: userId,
            );
          } else {
            final updated = engagementToDelete.copyWith(
              reaction: const ValueWrapper(null),
            );
            await _engagementRepository.update(
              id: updated.id,
              item: updated,
              userId: userId,
            );
          }
        } else {
          // Optimistically update the reaction.
          final updatedEngagement = state.userEngagement!.copyWith(
            reaction: ValueWrapper(Reaction(reactionType: event.reactionType!)),
          );
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              userEngagement: updatedEngagement,
              // Also update the main list for immediate UI feedback.
              engagements: state.engagements
                  .map(
                    (e) => e.id == updatedEngagement.id ? updatedEngagement : e,
                  )
                  .toList(),
            ),
          );
          await _engagementRepository.update(
            id: state.userEngagement!.id,
            item: updatedEngagement,
            userId: userId,
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
            engagements: [...state.engagements, newEngagement],
          ),
        );
        final created = await _engagementRepository.create(
          item: newEngagement,
          userId: userId,
        );
        // Update state with the server-confirmed object.
        emit(
          state.copyWith(
            userEngagement: created,
            engagements: state.engagements
                .map((e) => e.id == newEngagement.id ? created : e)
                .toList(),
          ),
        );
      }
      _appBloc.add(AppPositiveInteractionOcurred(context: event.context));
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

    final preCheckStatus = await _contentLimitationService.checkAction(
      ContentAction.postComment,
    );
    if (preCheckStatus != LimitationStatus.allowed) {
      emit(
        state.copyWith(
          status: EngagementStatus.success, // Keep UI stable
          limitationStatus: preCheckStatus,
        ),
      );
      return;
    }

    emit(state.copyWith(status: EngagementStatus.actionInProgress));
    try {
      final newComment = Comment(language: language, content: event.content);
      Engagement engagementToUpsert;

      if (state.userEngagement != null) {
        // User has an existing engagement (e.g., a reaction), so update it.
        engagementToUpsert = state.userEngagement!.copyWith(
          comment: ValueWrapper(newComment),
        );
        await _engagementRepository.update(
          id: engagementToUpsert.id,
          item: engagementToUpsert,
          userId: userId,
        );
      } else {
        // No existing engagement, create a new one with just the comment.
        engagementToUpsert = Engagement(
          id: const Uuid().v4(),
          userId: userId,
          entityId: _entityId,
          entityType: _entityType,
          comment: newComment,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _engagementRepository.create(
          item: engagementToUpsert,
          userId: userId,
        );
      }

      // Instead of a full re-fetch, which is inefficient, we perform an
      // optimistic update on the local state. This ensures the UI updates
      // instantly and correctly reflects the new comment.
      final updatedEngagements = List<Engagement>.from(state.engagements);
      final existingIndex =
          updatedEngagements.indexWhere((e) => e.userId == userId);

      if (existingIndex != -1) {
        updatedEngagements[existingIndex] = engagementToUpsert;
      } else {
        updatedEngagements.add(engagementToUpsert);
      }

      emit(
        state.copyWith(
          status: EngagementStatus.success,
          engagements: updatedEngagements,
          userEngagement: engagementToUpsert,
        ),
      );
      _appBloc.add(AppPositiveInteractionOcurred(context: event.context));
    } on HttpException catch (e, s) {
      _logger.severe('Failed to post comment', e, s);
      var limitationStatus = LimitationStatus.allowed;
      if (e is ForbiddenException) {
        limitationStatus = LimitationStatus.standardUserLimitReached;
      }
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          error: e,
          limitationStatus: limitationStatus,
        ),
      );
      // Re-throw to be caught by BlocListener in UI for snackbar.
      rethrow;
    }
  }

  Future<void> _onEngagementCommentUpdated(
    EngagementCommentUpdated event,
    Emitter<EngagementState> emit,
  ) async {
    final userId = _appBloc.state.user?.id;
    final language = _appBloc.state.settings?.language;
    if (userId == null ||
        language == null ||
        state.userEngagement?.comment == null) {
      return;
    }

    try {
      emit(state.copyWith(status: EngagementStatus.actionInProgress));

      final updatedComment = state.userEngagement!.comment!.copyWith(
        content: event.content,
      );
      final updatedEngagement = state.userEngagement!.copyWith(
        comment: ValueWrapper(updatedComment),
      );

      await _engagementRepository.update(
        id: updatedEngagement.id,
        item: updatedEngagement,
        userId: userId,
      );

      final updatedEngagements =
          List<Engagement>.from(state.engagements).map((e) {
        if (e.userId == userId) {
          return updatedEngagement;
        }
        return e;
      }).toList();

      emit(
        state.copyWith(
          status: EngagementStatus.success,
          engagements: updatedEngagements,
          userEngagement: updatedEngagement,
        ),
      );
      _appBloc.add(AppPositiveInteractionOcurred(context: event.context));
    } on HttpException catch (e, s) {
      _logger.severe('Failed to update comment', e, s);
      var limitationStatus = LimitationStatus.allowed;
      if (e is ForbiddenException) {
        limitationStatus = LimitationStatus.standardUserLimitReached;
      }
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          error: e,
          limitationStatus: limitationStatus,
        ),
      );
      // Re-throw to be caught by BlocListener in UI for snackbar.
      rethrow;
    }
  }
}
