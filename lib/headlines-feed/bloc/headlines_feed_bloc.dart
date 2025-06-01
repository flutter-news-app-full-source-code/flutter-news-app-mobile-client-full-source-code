import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_main/app/bloc/app_bloc.dart'; // Added
import 'package:ht_main/headlines-feed/models/headline_filter.dart';
import 'package:ht_main/shared/services/feed_injector_service.dart'; // Added
import 'package:ht_shared/ht_shared.dart'; // Updated for FeedItem, AppConfig, User

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
    required FeedInjectorService feedInjectorService, // Added
    required AppBloc appBloc, // Added
  })  : _headlinesRepository = headlinesRepository,
        _feedInjectorService = feedInjectorService, // Added
        _appBloc = appBloc, // Added
        super(HeadlinesFeedInitial()) {
    on<HeadlinesFeedFetchRequested>(
      _onHeadlinesFeedFetchRequested,
      transformer:
          sequential(), // Ensures fetch requests are processed one by one
    );
    on<HeadlinesFeedRefreshRequested>(
      _onHeadlinesFeedRefreshRequested,
      transformer:
          restartable(), // Ensures only the latest refresh is processed
    );
    on<HeadlinesFeedFiltersApplied>(_onHeadlinesFeedFiltersApplied);
    on<HeadlinesFeedFiltersCleared>(_onHeadlinesFeedFiltersCleared);
  }

  final HtDataRepository<Headline> _headlinesRepository;
  final FeedInjectorService _feedInjectorService; // Added
  final AppBloc _appBloc; // Added

  /// The number of headlines to fetch per page during pagination or initial load.
  static const _headlinesFetchLimit = 10;

  /// Handles the [HeadlinesFeedFiltersApplied] event.
  ///
  /// Emits [HeadlinesFeedLoading] state, then fetches the first page of
  /// headlines using the filters provided in the event. Updates the state
  /// with the new headlines and the applied filter. Emits [HeadlinesFeedError]
  /// if fetching fails.
  Future<void> _onHeadlinesFeedFiltersApplied(
    HeadlinesFeedFiltersApplied event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(HeadlinesFeedLoading()); // Show loading for filter application
    try {
      final queryParams = <String, dynamic>{};
      if (event.filter.categories?.isNotEmpty ?? false) {
        queryParams['categories'] = event.filter.categories!
            .map((c) => c.id)
            .join(',');
      }
      if (event.filter.sources?.isNotEmpty ?? false) {
        queryParams['sources'] = event.filter.sources!
            .map((s) => s.id)
            .join(',');
      }

      final headlineResponse = await _headlinesRepository.readAllByQuery(
        queryParams,
        limit: _headlinesFetchLimit,
      );

      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        // AppConfig is crucial for injection rules.
        emit(const HeadlinesFeedError(message: 'App configuration not available.'));
        return;
      }

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
        currentFeedItemCount: 0, // Initial load for filters
      );

      emit(
        HeadlinesFeedLoaded(
          feedItems: processedFeedItems, // Changed
          hasMore: headlineResponse.hasMore, // Based on original headline fetch
          cursor: headlineResponse.cursor,
          filter: event.filter, // Store the applied filter
        ),
      );
    } on HtHttpException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (e, st) {
      // Log the error and stack trace for unexpected errors
      // Consider using a proper logging framework
      print('Unexpected error in _onHeadlinesFeedFiltersApplied: $e\n$st');
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }

  /// Handles clearing all applied filters.
  ///
  /// Fetches the first page of headlines without any filters.
  Future<void> _onHeadlinesFeedFiltersCleared(
    HeadlinesFeedFiltersCleared event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(HeadlinesFeedLoading()); // Show loading indicator
    try {
      // Fetch the first page with no filters
      final headlineResponse = await _headlinesRepository.readAll(
        limit: _headlinesFetchLimit,
      );

      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(const HeadlinesFeedError(message: 'App configuration not available.'));
        return;
      }

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
        currentFeedItemCount: 0,
      );

      emit(
        HeadlinesFeedLoaded(
          feedItems: processedFeedItems, // Changed
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
        ),
      );
    } on HtHttpException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (e, st) {
      // Log the error and stack trace for unexpected errors
      print('Unexpected error in _onHeadlinesFeedFiltersCleared: $e\n$st');
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }

  /// Handles the [HeadlinesFeedFetchRequested] event for initial load and pagination.
  ///
  /// Determines if it's an initial load or pagination based on the current state
  /// and the presence of a cursor in the event. Fetches headlines using the
  /// currently active filter stored in the state. Emits appropriate loading
  /// states ([HeadlinesFeedLoading] or [HeadlinesFeedLoadingSilently]) and
  /// updates the state with fetched headlines or an error.
  Future<void> _onHeadlinesFeedFetchRequested(
    HeadlinesFeedFetchRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    // Determine current filter and cursor based on state
    var currentFilter = const HeadlineFilter();
    String? currentCursorForFetch = event.cursor;
    List<FeedItem> currentFeedItems = [];
    bool isPaginating = false;
    int currentFeedItemCountForInjector = 0;

    if (state is HeadlinesFeedLoaded) {
      final loadedState = state as HeadlinesFeedLoaded;
      currentFilter = loadedState.filter;
      currentFeedItems = loadedState.feedItems;
      currentFeedItemCountForInjector = loadedState.feedItems.length;

      if (event.cursor != null) { // Explicit pagination request
        if (!loadedState.hasMore) return; // No more items to fetch
        isPaginating = true;
        currentCursorForFetch = loadedState.cursor; // Use BLoC's cursor for safety
      } else { // Initial fetch or refresh (event.cursor is null)
        currentFeedItems = []; // Reset for non-pagination
        currentFeedItemCountForInjector = 0;
      }
    } else if (state is HeadlinesFeedLoading || state is HeadlinesFeedLoadingSilently) {
      if (event.cursor == null) return; // Avoid concurrent initial fetches
    }
    // For initial load or if event.cursor is null, currentCursorForFetch remains null.

    emit(isPaginating ? HeadlinesFeedLoadingSilently() : HeadlinesFeedLoading());

    try {
      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(const HeadlinesFeedError(message: 'App configuration not available.'));
        return;
      }

      final queryParams = <String, dynamic>{};
      if (currentFilter.categories?.isNotEmpty ?? false) {
        queryParams['categories'] = currentFilter.categories!
            .map((c) => c.id)
            .join(',');
      }
      if (currentFilter.sources?.isNotEmpty ?? false) {
        queryParams['sources'] = currentFilter.sources!
            .map((s) => s.id)
            .join(',');
      }

      final headlineResponse = await _headlinesRepository.readAllByQuery(
        queryParams,
        limit: _headlinesFetchLimit,
        startAfterId: currentCursorForFetch,
      );

      final newProcessedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
        currentFeedItemCount: currentFeedItemCountForInjector,
      );

      emit(
        HeadlinesFeedLoaded(
          feedItems: isPaginating
              ? (List.of(currentFeedItems)..addAll(newProcessedFeedItems))
              : newProcessedFeedItems,
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
          filter: currentFilter,
        ),
      );
    } on HtHttpException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (e, st) {
      print('Unexpected error in _onHeadlinesFeedFetchRequested: $e\n$st');
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }

  /// Handles [HeadlinesFeedRefreshRequested] events for pull-to-refresh.
  ///
  /// Fetches the first page of headlines using the currently applied filter (if any).
  /// Uses `restartable` transformer to ensure only the latest request is processed.
  Future<void> _onHeadlinesFeedRefreshRequested(
    HeadlinesFeedRefreshRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(HeadlinesFeedLoading()); // Show loading indicator for refresh

    var currentFilter = const HeadlineFilter();
    if (state is HeadlinesFeedLoaded) {
      currentFilter = (state as HeadlinesFeedLoaded).filter;
    }

    try {
      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(const HeadlinesFeedError(message: 'App configuration not available.'));
        return;
      }

      final queryParams = <String, dynamic>{};
      if (currentFilter.categories?.isNotEmpty ?? false) {
        queryParams['categories'] =
            currentFilter.categories!.map((c) => c.id).join(',');
      }
      if (currentFilter.sources?.isNotEmpty ?? false) {
        queryParams['sources'] =
            currentFilter.sources!.map((s) => s.id).join(',');
      }

      final headlineResponse = await _headlinesRepository.readAllByQuery(
        queryParams,
        limit: _headlinesFetchLimit,
      );

      final List<Headline> headlinesToInject = headlineResponse.items;
      final User? userForInjector = currentUser;
      final AppConfig configForInjector = appConfig;
      const int itemCountForInjector = 0;

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlinesToInject,
        user: userForInjector,
        appConfig: configForInjector,
        currentFeedItemCount: itemCountForInjector,
      );

      emit(
        HeadlinesFeedLoaded(
          feedItems: processedFeedItems,
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
          filter: currentFilter,
        ),
      );
    } on HtHttpException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (e, st) {
      print('Unexpected error in _onHeadlinesFeedRefreshRequested: $e\n$st');
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }
}
