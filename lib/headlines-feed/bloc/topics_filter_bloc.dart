import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

part 'topics_filter_event.dart';
part 'topics_filter_state.dart';

/// {@template topics_filter_bloc}
/// Manages the state for fetching and displaying topics for filtering.
///
/// Handles initial fetching and pagination of topics using the
/// provided [DataRepository].
/// {@endtemplate}
class TopicsFilterBloc extends Bloc<TopicsFilterEvent, TopicsFilterState> {
  /// {@macro topics_filter_bloc}
  ///
  /// Requires a [DataRepository<Topic>] to interact with the data layer.
  TopicsFilterBloc({
    required DataRepository<Topic> topicsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required AppBloc appBloc,
  }) : _topicsRepository = topicsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _appBloc = appBloc,
       super(const TopicsFilterState()) {
    on<TopicsFilterRequested>(
      _onTopicsFilterRequested,
      transformer: restartable(),
    );
    on<TopicsFilterLoadMoreRequested>(
      _onTopicsFilterLoadMoreRequested,
      transformer: droppable(),
    );
    on<TopicsFilterApplyFollowedRequested>(
      _onTopicsFilterApplyFollowedRequested,
      transformer: restartable(),
    );
  }

  final DataRepository<Topic> _topicsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final AppBloc _appBloc;

  /// Number of topics to fetch per page.
  static const _topicsLimit = 20;

  /// Handles the initial request to fetch topics.
  Future<void> _onTopicsFilterRequested(
    TopicsFilterRequested event,
    Emitter<TopicsFilterState> emit,
  ) async {
    // Prevent fetching if already loading or successful (unless forced refresh)
    if (state.status == TopicsFilterStatus.loading ||
        state.status == TopicsFilterStatus.success) {
      // Optionally add logic here for forced refresh if needed
      return;
    }

    emit(state.copyWith(status: TopicsFilterStatus.loading));

    try {
      final response = await _topicsRepository.readAll(
        pagination: const PaginationOptions(limit: _topicsLimit),
        sort: [const SortOption('name', SortOrder.asc)],
      );
      emit(
        state.copyWith(
          status: TopicsFilterStatus.success,
          topics: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: TopicsFilterStatus.failure, error: e));
    }
  }

  /// Handles the request to load more topics for pagination.
  Future<void> _onTopicsFilterLoadMoreRequested(
    TopicsFilterLoadMoreRequested event,
    Emitter<TopicsFilterState> emit,
  ) async {
    // Only proceed if currently successful and has more items
    if (state.status != TopicsFilterStatus.success || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: TopicsFilterStatus.loadingMore));

    try {
      final response = await _topicsRepository.readAll(
        pagination: PaginationOptions(
          limit: _topicsLimit,
          cursor: state.cursor,
        ),
        sort: [const SortOption('name', SortOrder.asc)],
      );
      emit(
        state.copyWith(
          status: TopicsFilterStatus.success,
          // Append new topics to the existing list
          topics: List.of(state.topics)..addAll(response.items),
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } on HttpException catch (e) {
      // Keep existing data but indicate failure
      emit(state.copyWith(status: TopicsFilterStatus.failure, error: e));
    }
  }

  /// Handles the request to apply the user's followed topics as filters.
  Future<void> _onTopicsFilterApplyFollowedRequested(
    TopicsFilterApplyFollowedRequested event,
    Emitter<TopicsFilterState> emit,
  ) async {
    emit(state.copyWith(followedTopicsStatus: TopicsFilterStatus.loading));

    final currentUser = _appBloc.state.user!;

    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: currentUser.id,
        userId: currentUser.id,
      );

      if (preferences.followedTopics.isEmpty) {
        emit(
          state.copyWith(
            followedTopicsStatus: TopicsFilterStatus.success,
            followedTopics: const [],
            clearError: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          followedTopicsStatus: TopicsFilterStatus.success,
          followedTopics: preferences.followedTopics,
          clearFollowedTopicsError: true,
        ),
      );
    } on HttpException catch (e) {
      emit(
        state.copyWith(
          followedTopicsStatus: TopicsFilterStatus.failure,
          error: e,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          followedTopicsStatus: TopicsFilterStatus.failure,
          error: UnknownException(e.toString()),
        ),
      );
    }
  }
}
