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
    if (userId == null) return;

    emit(state.copyWith(status: EngagementStatus.actionInProgress));

    try {
      if (state.userEngagement != null) {
        // User is updating or removing their reaction.
        if (event.reactionType == null ||
            state.userEngagement!.reaction.reactionType == event.reactionType) {
          // Remove reaction.
          await _engagementRepository.delete(id: state.userEngagement!.id);
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              clearUserEngagement: true,
            ),
          );
        } else {
          // Update reaction.
          final updatedEngagement = state.userEngagement!.copyWith(
            reaction: Reaction(reactionType: event.reactionType!),
          );
          await _engagementRepository.update(
            id: updatedEngagement.id,
            item: updatedEngagement,
          );
          emit(
            state.copyWith(
              status: EngagementStatus.success,
              userEngagement: updatedEngagement,
            ),
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
        final created = await _engagementRepository.create(item: newEngagement);
        emit(
          state.copyWith(
            status: EngagementStatus.success,
            userEngagement: created,
          ),
        );
      }
      add(const EngagementStarted()); // Refresh the list
    } on HttpException catch (e, s) {
      _logger.severe('Failed to update reaction', e, s);
      emit(state.copyWith(status: EngagementStatus.failure, error: e));
    }
  }

  Future<void> _onEngagementCommentPosted(
    EngagementCommentPosted event,
    Emitter<EngagementState> emit,
  ) async {
    // Logic to post a comment, which requires a reaction.
    // This will be implemented in a subsequent phase.
  }

  Future<void> _onEngagementQuickReactionToggled(
    EngagementQuickReactionToggled event,
    Emitter<EngagementState> emit,
  ) async {
    final userId = _appBloc.state.user?.id;
    if (userId == null) return;

    emit(state.copyWith(status: EngagementStatus.actionInProgress));

    try {
      final existingEngagement = state.engagements.firstWhere(
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

      if (existingEngagement.id.isNotEmpty) {
        // User has an existing engagement.
        if (existingEngagement.reaction.reactionType == event.reactionType) {
          // Toggling off the same reaction.
          await _engagementRepository.delete(id: existingEngagement.id);
        } else {
          // Changing to a new quick reaction.
          final updated = existingEngagement.copyWith(
            reaction: Reaction(reactionType: event.reactionType),
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
        await _engagementRepository.create(item: newEngagement);
      }
      add(const EngagementStarted()); // Refresh the list
    } on HttpException catch (e, s) {
      _logger.severe('Failed to toggle quick reaction', e, s);
      emit(state.copyWith(status: EngagementStatus.failure, error: e));
    }
  }
}
