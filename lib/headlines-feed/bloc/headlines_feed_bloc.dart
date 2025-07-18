import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/headlines-feed/models/headline_filter.dart';
import 'package:ht_main/shared/services/feed_injector_service.dart';
import 'package:ht_shared/ht_shared.dart';

part 'headlines_feed_event.dart';
part 'headlines_feed_state.dart';

/// {@template headlines_feed_bloc}
/// Manages the state for the headlines feed feature.
///
/// Handles fetching headlines, applying filters, pagination, and refreshing
/// the feed using the provided [HtDataRepository]. It uses [FeedInjectorService]
/// to inject ads and account actions into the feed.
/// {@endtemplate}
class HeadlinesFeedBloc extends Bloc<HeadlinesFeedEvent, HeadlinesFeedState> {
  /// {@macro headlines_feed_bloc}
  ///
  /// Requires repositories and services for its operations.
  HeadlinesFeedBloc({
    required HtDataRepository<Headline> headlinesRepository,
    required FeedInjectorService feedInjectorService,
    required AppBloc appBloc,
  })  : _headlinesRepository = headlinesRepository,
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

  final HtDataRepository<Headline> _headlinesRepository;
  final FeedInjectorService _feedInjectorService;
  final AppBloc _appBloc;

  /// The number of headlines to fetch per page.
  static const _headlinesFetchLimit = 10;

  Map<String, dynamic> _buildFilter(HeadlineFilter filter) {
    final queryFilter = <String, dynamic>{};
    if (filter.topics?.isNotEmpty ?? false) {
      queryFilter['topic.id'] = {
        '\$in': filter.topics!.map((t) => t.id).toList(),
      };
    }
    if (filter.sources?.isNotEmpty ?? false) {
      queryFilter['source.id'] = {
        '\$in': filter.sources!.map((s) => s.id).toList(),
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
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: _buildFilter(state.filter),
        pagination: PaginationOptions(
          limit: _headlinesFetchLimit,
          cursor: state.cursor,
        ),
      );

      final newProcessedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
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
            feedActionType: (newProcessedFeedItems
                    .firstWhere((item) => item is FeedAction) as FeedAction)
                .feedActionType,
            isCompleted: false,
          ),
        );
      }
    } on HtHttpException catch (e) {
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
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: _buildFilter(state.filter),
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
      );

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
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
            feedActionType: (processedFeedItems
                    .firstWhere((item) => item is FeedAction) as FeedAction)
                .feedActionType,
            isCompleted: false,
          ),
        );
      }
    } on HtHttpException catch (e) {
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
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: _buildFilter(event.filter),
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
      );

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
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
            feedActionType: (processedFeedItems
                    .firstWhere((item) => item is FeedAction) as FeedAction)
                .feedActionType,
            isCompleted: false,
          ),
        );
      }
    } on HtHttpException catch (e) {
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
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(state.copyWith(status: HeadlinesFeedStatus.failure));
        return;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
      );

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
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
        // TODO(ht-development): Implement correct event dispatching
        // _appBloc.add(AppUserFeedActionShown(userId: currentUser!.id));
      }
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }
}
