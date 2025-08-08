import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/feed_decorator_service.dart';

part 'headlines_feed_event.dart';
part 'headlines_feed_state.dart';

/// {@template headlines_feed_bloc}
/// Manages the state for the headlines feed feature.
///
/// Handles fetching headlines, applying filters, pagination, and refreshing
/// the feed using the provided [DataRepository]. It uses [FeedInjectorService]
/// to inject ads and account actions into the feed.
/// {@endtemplate}
class HeadlinesFeedBloc extends Bloc<HeadlinesFeedEvent, HeadlinesFeedState> {
  /// {@macro headlines_feed_bloc}
  ///
  /// Requires repositories and services for its operations.
  HeadlinesFeedBloc({
    required DataRepository<Headline> headlinesRepository,
    required FeedInjectorService feedInjectorService,
    required AppBloc appBloc,
  }) : _headlinesRepository = headlinesRepository,
       _feedInjectorService = feedInjectorService,
       _appBloc = appBloc,
       super(const HeadlinesFeedState()) {
    on<HeadlinesFeedFetchRequested>(
      _onHeadlinesFeedFetchRequested,
      transformer: droppable(),
    );
    on<HeadlinesFeedRefreshRequested>(
      _onHeadlinesFeedRefreshRequested,
      transformer: restartable(),
    );
    on<HeadlinesFeedFiltersApplied>(
      _onHeadlinesFeedFiltersApplied,
      transformer: restartable(),
    );
    on<HeadlinesFeedFiltersCleared>(
      _onHeadlinesFeedFiltersCleared,
      transformer: restartable(),
    );
  }

  final DataRepository<Headline> _headlinesRepository;
  final FeedInjectorService _feedInjectorService;
  final AppBloc _appBloc;

  /// The number of headlines to fetch per page.
  static const _headlinesFetchLimit = 10;

  Map<String, dynamic> _buildFilter(HeadlineFilter filter) {
    final queryFilter = <String, dynamic>{};
    if (filter.topics?.isNotEmpty ?? false) {
      queryFilter['topic.id'] = {
        r'$in': filter.topics!.map((t) => t.id).toList(),
      };
    }
    if (filter.sources?.isNotEmpty ?? false) {
      queryFilter['source.id'] = {
        r'$in': filter.sources!.map((s) => s.id).toList(),
      };
    }
    return queryFilter;
  }

  Future<void> _onHeadlinesFeedFetchRequested(
    HeadlinesFeedFetchRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    if (state.status == HeadlinesFeedStatus.loading || !state.hasMore) return;

    emit(state.copyWith(status: HeadlinesFeedStatus.loadingMore));

    try {
      final currentUser = _appBloc.state.user;
      final remoteConfig = _appBloc.state.remoteConfig;

      if (remoteConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: _buildFilter(state.filter),
        pagination: PaginationOptions(
          limit: _headlinesFetchLimit,
          cursor: state.cursor,
        ),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      final newProcessedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: remoteConfig,
        currentFeedItemCount: state.feedItems.length,
      );

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: List.of(state.feedItems)..addAll(newProcessedFeedItems),
          hasMore: headlineResponse.cursor != null,
          cursor: headlineResponse.cursor,
        ),
      );

      if (newProcessedFeedItems.any((item) => item is FeedAction) &&
          currentUser?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(
            userId: currentUser!.id,
            feedActionType:
                (newProcessedFeedItems.firstWhere((item) => item is FeedAction)
                        as FeedAction)
                    .feedActionType,
            isCompleted: false,
          ),
        );
      }
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onHeadlinesFeedRefreshRequested(
    HeadlinesFeedRefreshRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(state.copyWith(status: HeadlinesFeedStatus.loading));
    try {
      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.remoteConfig;

      if (appConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: _buildFilter(state.filter),
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: appConfig,
        currentFeedItemCount: 0,
      );

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: processedFeedItems,
          hasMore: headlineResponse.cursor != null,
          cursor: headlineResponse.cursor,
          filter: state.filter,
        ),
      );

      if (processedFeedItems.any((item) => item is FeedAction) &&
          currentUser?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(
            userId: currentUser!.id,
            feedActionType:
                (processedFeedItems.firstWhere((item) => item is FeedAction)
                        as FeedAction)
                    .feedActionType,
            isCompleted: false,
          ),
        );
      }
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onHeadlinesFeedFiltersApplied(
    HeadlinesFeedFiltersApplied event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HeadlinesFeedStatus.loading,
        filter: event.filter,
        feedItems: [],
        cursor: null,
        clearCursor: true,
      ),
    );
    try {
      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.remoteConfig;

      if (appConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: _buildFilter(event.filter),
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: appConfig,
        currentFeedItemCount: 0,
      );

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: processedFeedItems,
          hasMore: headlineResponse.cursor != null,
          cursor: headlineResponse.cursor,
        ),
      );

      if (processedFeedItems.any((item) => item is FeedAction) &&
          currentUser?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(
            userId: currentUser!.id,
            feedActionType:
                (processedFeedItems.firstWhere((item) => item is FeedAction)
                        as FeedAction)
                    .feedActionType,
            isCompleted: false,
          ),
        );
      }
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onHeadlinesFeedFiltersCleared(
    HeadlinesFeedFiltersCleared event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HeadlinesFeedStatus.loading,
        filter: const HeadlineFilter(),
        feedItems: [],
        cursor: null,
        clearCursor: true,
      ),
    );
    try {
      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.remoteConfig;

      if (appConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: appConfig,
        currentFeedItemCount: 0,
      );

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: processedFeedItems,
          hasMore: headlineResponse.cursor != null,
          cursor: headlineResponse.cursor,
        ),
      );

      if (processedFeedItems.any((item) => item is FeedAction) &&
          currentUser?.id != null) {
        // TODO(fulleni): Implement correct event dispatching
        // _appBloc.add(AppUserFeedActionShown(userId: currentUser!.id));
      }
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }
}
