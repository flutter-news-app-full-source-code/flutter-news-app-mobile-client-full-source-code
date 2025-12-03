import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
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
    required AppBloc appBloc,
    Logger? logger,
  }) : _entityId = entityId,
       _entityType = entityType,
       _engagementRepository = engagementRepository,
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
  final AppBloc _appBloc;
  final Logger _logger;

  Future<void> _onEngagementStarted(
    EngagementStarted event,
    Emitter<EngagementState> emit,
  ) async {
    emit(state.copyWith(status: EngagementStatus.loading));
    try {
      final response = await _engagementRepository.readAll(
        filter: {'entityId': _entityId},
      );
      final engagements = response.items;
      final userId = _appBloc.state.user?.id;
      final userEngagement = engagements.firstWhere(
        (e) => e.userId == userId,
        orElse: () => Engagement(
          id: '',
          userId: '',
          entityId: '',
          entityType: _entityType,
          reaction: const Reaction(reactionType: ReactionType.like),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      emit(
        state.copyWith(
          status: EngagementStatus.success,
          engagements: engagements,
          userEngagement: userEngagement.id.isNotEmpty ? userEngagement : null,
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

    try {
      if (state.userEngagement != null) {
        // User is updating or removing their reaction.
        final isTogglingOff =
            event.reactionType == null ||
            state.userEngagement!.reaction.reactionType == event.reactionType;

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
          final updatedEngagement = state.userEngagement!.copyWith(
            reaction: Reaction(reactionType: event.reactionType!),
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
      // On failure, roll back to the original state.
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          error: e,
          userEngagement: originalUserEngagement,
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
    if (userId == null || state.userEngagement == null || language == null) {
      return; // Cannot post a comment without a user, reaction, or language.
    }

    emit(state.copyWith(status: EngagementStatus.actionInProgress));

    try {
      final newComment = Comment(language: language, content: event.content);

      final updatedEngagement = state.userEngagement!.copyWith(
        comment: newComment,
      );

      // Optimistically add the comment to the UI.
      final optimisticEngagements = List<Engagement>.from(state.engagements)
        ..removeWhere((e) => e.id == state.userEngagement!.id)
        ..insert(0, updatedEngagement);

      emit(
        state.copyWith(
          status: EngagementStatus.success,
          userEngagement: updatedEngagement,
          engagements: optimisticEngagements,
        ),
      );

      await _engagementRepository.update(
        id: updatedEngagement.id,
        item: updatedEngagement,
      );
    } on HttpException catch (e, s) {
      _logger.severe('Failed to post comment', e, s);
      // On failure, we can simply show an error. The optimistic update will
      // be corrected on the next full refresh.
      emit(state.copyWith(status: EngagementStatus.failure, error: e));
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

    try {
      if (state.userEngagement != null) {
        // User has an existing engagement.
        final isTogglingOff =
            state.userEngagement!.reaction.reactionType == event.reactionType;

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
            reaction: Reaction(reactionType: event.reactionType),
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
      // On failure, roll back to the original state.
      emit(
        state.copyWith(
          status: EngagementStatus.failure,
          error: e,
          userEngagement: originalUserEngagement,
        ),
      );
    }
  }
}
