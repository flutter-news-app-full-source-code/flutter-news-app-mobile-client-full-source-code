import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_main/headlines-feed/models/headline_filter.dart';
import 'package:ht_shared/ht_shared.dart'
    show
        Category,
        // Country, // Removed as it's no longer used for headline filtering
        Headline,
        HtHttpException,
        Source; // Shared models and standardized exceptions

part 'headlines_feed_event.dart';
part 'headlines_feed_state.dart';

/// {@template headlines_feed_bloc}
/// Manages the state for the headlines feed feature.
///
/// Handles fetching headlines, applying filters, pagination, and refreshing
/// the feed using the provided [HtDataRepository].
/// {@endtemplate}
class HeadlinesFeedBloc extends Bloc<HeadlinesFeedEvent, HeadlinesFeedState> {
  /// {@macro headlines_feed_bloc}
  ///
  /// Requires a [HtDataRepository<Headline>] to interact with the data layer.
  HeadlinesFeedBloc({required HtDataRepository<Headline> headlinesRepository})
    : _headlinesRepository = headlinesRepository,
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
      final response = await _headlinesRepository.readAllByQuery({
        if (event.filter.categories?.isNotEmpty ?? false)
          'categories':
              event.filter.categories!
                  .whereType<Category>()
                  .map((c) => c.id)
                  .toList(),
        if (event.filter.sources?.isNotEmpty ?? false)
          'sources':
              event.filter.sources!
                  .whereType<Source>()
                  .map((s) => s.id)
                  .toList(),
      }, limit: _headlinesFetchLimit);
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
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
      final response = await _headlinesRepository.readAll(
        limit: _headlinesFetchLimit,
      );
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          filter: const HeadlineFilter(), // Clear all filter aspects
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
    var currentCursor =
        event.cursor; // Use event's cursor if provided (for pagination)
    var currentHeadlines = <Headline>[];
    var isPaginating = false;

    if (state is HeadlinesFeedLoaded) {
      final loadedState = state as HeadlinesFeedLoaded;
      currentFilter = loadedState.filter;
      // Only use state's cursor if event's cursor is null (i.e., not explicit pagination request)
      currentCursor ??= loadedState.cursor;
      currentHeadlines = loadedState.headlines;
      // Check if we should paginate
      isPaginating = event.cursor != null && loadedState.hasMore;
      if (isPaginating && state is HeadlinesFeedLoadingSilently) {
        return; // Avoid concurrent pagination
      }
      if (!loadedState.hasMore && event.cursor != null) {
        return; // Don't fetch if no more items
      }
    } else if (state is HeadlinesFeedLoading ||
        state is HeadlinesFeedLoadingSilently) {
      // Avoid concurrent fetches if already loading, unless it's explicit pagination
      if (event.cursor == null) return;
    }

    // Emit appropriate loading state
    if (isPaginating) {
      emit(HeadlinesFeedLoadingSilently());
    } else {
      // Initial load or load after error/clear
      emit(HeadlinesFeedLoading());
      currentHeadlines = []; // Reset headlines on non-pagination fetch
    }

    try {
      final response = await _headlinesRepository.readAllByQuery(
        {
          if (currentFilter.categories?.isNotEmpty ?? false)
            'categories':
                currentFilter.categories!
                    .whereType<Category>()
                    .map((c) => c.id)
                    .toList(),
          if (currentFilter.sources?.isNotEmpty ?? false)
            'sources':
                currentFilter.sources!
                    .whereType<Source>()
                    .map((s) => s.id)
                    .toList(),
        },
        limit: _headlinesFetchLimit,
        startAfterId: currentCursor, // Use determined cursor
      );
      emit(
        HeadlinesFeedLoaded(
          // Append if paginating, otherwise replace
          headlines:
              isPaginating ? currentHeadlines + response.items : response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          filter: currentFilter, // Preserve the filter
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

    // Determine the filter currently applied in the state
    var currentFilter = const HeadlineFilter();
    if (state is HeadlinesFeedLoaded) {
      currentFilter = (state as HeadlinesFeedLoaded).filter;
    }

    try {
      // Fetch the first page using the current filter
      final response = await _headlinesRepository.readAllByQuery({
        if (currentFilter.categories?.isNotEmpty ?? false)
          'categories':
              currentFilter.categories!
                  .whereType<Category>()
                  .map((c) => c.id)
                  .toList(),
        if (currentFilter.sources?.isNotEmpty ?? false)
          'sources':
              currentFilter.sources!
                  .whereType<Source>()
                  .map((s) => s.id)
                  .toList(),
      }, limit: _headlinesFetchLimit);
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items, // Replace headlines on refresh
          hasMore: response.hasMore,
          cursor: response.cursor,
          filter: currentFilter, // Preserve the filter
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
