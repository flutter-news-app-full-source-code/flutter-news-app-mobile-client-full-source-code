import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/cached_feed.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:logging/logging.dart';

part 'headlines_feed_event.dart';
part 'headlines_feed_state.dart';

/// {@template headlines_feed_bloc}
/// Manages the state for the headlines feed feature.
///
/// This BLoC is the central orchestrator for the news feed. Its core
/// responsibilities include:
/// - Fetching, filtering, and displaying headlines from a `DataRepository`.
/// - Injecting dynamic content placeholders for ads and decorators
///   using the `AdService` and the new `FeedDecoratorService`.
/// - Implementing a session-based in-memory caching strategy via
///   [FeedCacheService] to provide a responsive user experience.
///
/// ### Feed Decoration and Ad Injection:
/// On major feed loads (initial load, refresh, or new filter), this BLoC
/// uses a two-step process:
/// 1. The new `FeedDecoratorService` injects a single `DecoratorPlaceholder`.
/// 2. The `AdService` then injects multiple `AdPlaceholder` items.
/// The UI is then responsible for rendering loader widgets for these placeholders.
///
/// ### Caching and Data Flow Scenarios:
///
/// 1.  **Cache Miss (Initial Load / New Filter):** When a filter is applied for
///     the first time, the BLoC fetches data from the [DataRepository],
///     decorates it using [FeedDecoratorService], and stores the result in the
///     cache before emitting the `success` state with the decorated feed.
///
/// 2.  **Cache Hit (Switching Filters):** When switching to a previously viewed
///     filter, the BLoC instantly emits the cached data. If the cached data is
///     older than a defined throttle duration, a background refresh is
///     triggered to fetch fresh content without a loading indicator.
///
/// 3.  **Pagination (Infinite Scroll):** When the user scrolls to the end of the
///     feed, the BLoC fetches the next page of headlines and **appends** them
///     to the existing cached list, ensuring a seamless infinite scroll.
///
/// 4.  **Pull-to-Refresh:** On a pull-to-refresh action, the BLoC
///     fetches the latest headlines and intelligently **prepends** only the new
///     items to the top of the cached list, avoiding full reloads.
/// {@endtemplate}
class HeadlinesFeedBloc extends Bloc<HeadlinesFeedEvent, HeadlinesFeedState> {
  /// {@macro headlines_feed_bloc}
  ///
  /// Requires repositories and services for its operations.
  /// The [initialUserContentPreferences] are used to "seed" the bloc with the
  /// current user's saved filters, preventing a race condition on navigation.
  HeadlinesFeedBloc({
    required DataRepository<Headline> headlinesRepository,
    required FeedDecoratorService feedDecoratorService,
    required DataRepository<Engagement> engagementRepository,
    required AdService adService,
    required AppBloc appBloc,
    required InlineAdCacheService inlineAdCacheService,
    required FeedCacheService feedCacheService,
    UserContentPreferences? initialUserContentPreferences,
  }) : _headlinesRepository = headlinesRepository,
       _feedDecoratorService = feedDecoratorService,
       _engagementRepository = engagementRepository,
       _adService = adService,
       _appBloc = appBloc,
       _inlineAdCacheService = inlineAdCacheService,
       _feedCacheService = feedCacheService,
       _logger = Logger('HeadlinesFeedBloc'),
       super(
         HeadlinesFeedState(
           savedHeadlineFilters:
               initialUserContentPreferences?.savedHeadlineFilters ?? const [],
         ),
       ) {
    // Subscribe to AppBloc to react to global state changes, primarily for
    // keeping the feed's list of saved filters synchronized with the global
    // app state.
    _appBlocSubscription = _appBloc.stream.listen((appState) {
      // This subscription is now responsible for handling *updates* to the
      // user's preferences while the bloc is active. The initial state is
      // handled by the constructor.
      // This subscription's responsibility is to listen for changes in user
      // preferences (like adding/removing a saved filter) from other parts
      // of the app and update this BLoC's state accordingly.
      if (appState.userContentPreferences?.savedHeadlineFilters != null &&
          state.savedHeadlineFilters !=
              appState.userContentPreferences!.savedHeadlineFilters) {
        add(
          _AppContentPreferencesChanged(
            preferences: appState.userContentPreferences!,
          ),
        );
      }
    });

    // Listen to the engagement repository's update stream.
    // When an engagement is created, updated, or deleted, this BLoC will
    // re-fetch the specific headline to update its comment count and reaction
    // state, ensuring the UI is always in sync.
    _engagementRepositorySubscription = _engagementRepository.entityUpdated
        .listen((_) {
          // The adThemeStyle is required for a refresh. If it's not in the state
          // yet (e.g., no UI event has occurred), we can't trigger the refresh.
          if (state.adThemeStyle == null) return;
          add(HeadlinesFeedRefreshRequested(adThemeStyle: state.adThemeStyle!));
        });

    on<HeadlinesFeedStarted>(
      _onHeadlinesFeedStarted,
      transformer: restartable(),
    );
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
    on<CallToActionTapped>(_onCallToActionTapped, transformer: sequential());
    on<NavigationHandled>(_onNavigationHandled, transformer: sequential());
    on<_AppContentPreferencesChanged>(
      _onAppContentPreferencesChanged,
      transformer: sequential(),
    );
    on<SavedFilterSelected>(_onSavedFilterSelected, transformer: restartable());
    on<AllFilterSelected>(_onAllFilterSelected, transformer: restartable());
    on<FollowedFilterSelected>(
      _onFollowedFilterSelected,
      transformer: restartable(),
    );
    on<HeadlinesFeedEngagementTapped>(
      _onHeadlinesFeedEngagementTapped,
      transformer: sequential(),
    );
  }

  final DataRepository<Headline> _headlinesRepository;
  final FeedDecoratorService _feedDecoratorService;
  final DataRepository<Engagement> _engagementRepository;
  final AdService _adService;
  final AppBloc _appBloc;
  final InlineAdCacheService _inlineAdCacheService;
  final FeedCacheService _feedCacheService;
  final Logger _logger;

  /// Subscription to the AppBloc's state stream.
  late final StreamSubscription<AppState> _appBlocSubscription;
  late final StreamSubscription<Type> _engagementRepositorySubscription;

  static const _allFilterId = 'all';

  /// The number of headlines to fetch per page.
  static const _headlinesFetchLimit = 10;

  /// The duration to wait before allowing another pull-to-refresh request
  /// for the same filter.
  static const _refreshThrottleDuration = Duration(seconds: 30);

  Map<String, dynamic> _buildFilter(HeadlineFilterCriteria filter) {
    final queryFilter = <String, dynamic>{};
    if (filter.topics.isNotEmpty) {
      queryFilter['topic.id'] = {
        r'$in': filter.topics.map((t) => t.id).toList(),
      };
    }
    if (filter.sources.isNotEmpty) {
      queryFilter['source.id'] = {
        r'$in': filter.sources.map((s) => s.id).toList(),
      };
    }
    if (filter.countries.isNotEmpty) {
      queryFilter['eventCountry.id'] = {
        r'$in': filter.countries.map((c) => c.id).toList(),
      };
    }
    // Always filter for active content.
    queryFilter['status'] = ContentStatus.active.name;
    // Note: The `selectedSourceCountryIsoCodes` and `selectedSourceSourceTypes`
    // fields are used exclusively for UI-side filtering on the `SourceFilterPage`
    // and are not included in the backend query for headlines. Source filtering
    // is performed solely by `source.id` when specific sources are selected.
    return queryFilter;
  }

  /// Generates a deterministic cache key based on the active filter.
  String _generateFilterKey(
    String activeFilterId,
    HeadlineFilterCriteria filter,
  ) {
    // For built-in filters, use their static names.
    if (activeFilterId == 'all' || activeFilterId == 'followed') {
      return activeFilterId;
    }
    // For saved filters, their ID is the key.
    if (activeFilterId != 'custom') {
      return activeFilterId;
    }
    // For one-off "custom" filters, generate a key from its contents.
    return 'custom_${filter.hashCode}';
  }

  /// Handles the explicit start event to kick off the initial feed load.
  ///
  /// This handler's job is to simply delegate to the standard refresh process,
  /// ensuring the feed loads its content as soon as the UI is ready.
  Future<void> _onHeadlinesFeedStarted(
    HeadlinesFeedStarted event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    // Persist the ad theme style in the state for background processes.
    emit(state.copyWith(adThemeStyle: event.adThemeStyle));
    add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
  }

  Future<void> _onHeadlinesFeedFetchRequested(
    HeadlinesFeedFetchRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    if (state.status == HeadlinesFeedStatus.loadingMore || !state.hasMore) {
      return;
    }

    final filterKey = _generateFilterKey(state.activeFilterId!, state.filter);
    final cachedFeed = _feedCacheService.getFeed(filterKey);

    // This should ideally not happen if the cache is managed correctly,
    // but as a safeguard, if there's no cached feed during pagination,
    // we should not proceed.
    if (cachedFeed == null) {
      _logger.warning(
        'Pagination attempted with no cached feed for key "$filterKey".',
      );
      return;
    }

    _logger.info(
      'Pagination: Fetching next page for filter "$filterKey" with cursor '
      '"${cachedFeed.cursor}".',
    );
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
          cursor: cachedFeed.cursor,
        ),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      // For pagination, only inject ad placeholders.
      final newProcessedFeedItems = await _adService.injectFeedAdPlaceholders(
        feedItems: headlineResponse.items,
        user: currentUser,
        remoteConfig: remoteConfig,
        imageStyle: _appBloc.state.settings!.feedSettings.feedItemImageStyle,
        adThemeStyle: event.adThemeStyle,
        processedContentItemCount: cachedFeed.feedItems
            .whereType<Headline>()
            .length,
      );

      _logger.fine(
        'Pagination: Appending ${newProcessedFeedItems.length} new items to '
        'the feed.',
      );

      final updatedFeedItems = List.of(cachedFeed.feedItems)
        ..addAll(newProcessedFeedItems);

      final updatedCachedFeed = cachedFeed.copyWith(
        feedItems: updatedFeedItems,
        hasMore: headlineResponse.hasMore,
        cursor: headlineResponse.cursor,
      );

      _feedCacheService.updateFeed(filterKey, updatedCachedFeed);
      _logger.fine(
        'Pagination: Cache updated for filter "$filterKey". New total items: '
        '${updatedFeedItems.length}.',
      );

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: updatedFeedItems,
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onHeadlinesFeedRefreshRequested(
    HeadlinesFeedRefreshRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    final filterKey = _generateFilterKey(state.activeFilterId!, state.filter);
    final cachedFeed = _feedCacheService.getFeed(filterKey);

    // Apply throttling logic.
    if (cachedFeed != null) {
      final timeSinceLastRefresh = DateTime.now().difference(
        cachedFeed.lastRefreshedAt,
      );
      if (timeSinceLastRefresh < _refreshThrottleDuration) {
        _logger.info(
          'Refresh throttled for filter "$filterKey". '
          'Time since last: $timeSinceLastRefresh.',
        );
        return;
      }
    }

    // On a full refresh, clear the ad cache for the current context to ensure
    // fresh ads are loaded.
    _inlineAdCacheService.clearAdsForContext(contextKey: filterKey);
    emit(
      state.copyWith(
        status: HeadlinesFeedStatus.loading,
        adThemeStyle: event.adThemeStyle,
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
        filter: _buildFilter(state.filter),
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      _logger.info(
        'Refresh: Fetched ${headlineResponse.items.length} latest headlines '
        'for filter "$filterKey".',
      );
      // If there's an existing cache, perform the intelligent prepend.
      if (cachedFeed != null) {
        final newHeadlines = headlineResponse.items;
        final cachedHeadlines = cachedFeed.feedItems.whereType<Headline>();

        if (cachedHeadlines.isNotEmpty) {
          final firstCachedHeadlineId = cachedHeadlines.first.id;
          final matchIndex = newHeadlines.indexWhere(
            (h) => h.id == firstCachedHeadlineId,
          );

          if (matchIndex != -1) {
            // Prepend only the new items found before the match.
            _logger.fine(
              'Refresh: Found a match with cached content at index $matchIndex.',
            );
            final itemsToPrepend = newHeadlines.sublist(0, matchIndex);
            if (itemsToPrepend.isNotEmpty) {
              final updatedFeedItems = List<FeedItem>.from(itemsToPrepend)
                ..addAll(cachedFeed.feedItems);
              _logger.info(
                'Refresh: Prepending ${itemsToPrepend.length} new items to '
                'the feed.',
              );

              // Update cache and state, then return.
              final updatedCachedFeed = cachedFeed.copyWith(
                feedItems: updatedFeedItems,
                lastRefreshedAt: DateTime.now(),
              );
              _feedCacheService.updateFeed(filterKey, updatedCachedFeed);
              emit(
                state.copyWith(
                  status: HeadlinesFeedStatus.success,
                  feedItems: updatedFeedItems,
                ),
              );
              return;
            } else {
              _logger.info(
                'Refresh: No new items to prepend. Emitting existing cached '
                'state.',
              );
              // If there are no new items, just emit the success state with
              // the existing cached items to dismiss the loading indicator.
              emit(
                state.copyWith(
                  status: HeadlinesFeedStatus.success,
                  feedItems: cachedFeed.feedItems,
                ),
              );
              // This early return is critical. It prevents the BLoC from
              // proceeding to the full re-decoration step when no new content
              // is available, which would unnecessarily clear and reload all
              // ads.
              return;
            }
          } else {
            _logger.warning(
              'Refresh: No match found between new and cached headlines. '
              'Proceeding with a full refresh.',
            );
          }
        }
      }

      _logger.info(
        'Refresh: Performing full decoration for filter "$filterKey".',
      );
      final settings = _appBloc.state.settings;

      // Step 1: Inject the decorator placeholder.
      final feedWithDecorator = _feedDecoratorService.decorateFeed(
        feedItems: headlineResponse.items,
        remoteConfig: appConfig,
      );

      // Step 2: Inject ad placeholders into the resulting list.
      final fullyDecoratedFeed = await _adService.injectFeedAdPlaceholders(
        feedItems: feedWithDecorator,
        user: currentUser,
        remoteConfig: appConfig,
        imageStyle: settings!.feedSettings.feedItemImageStyle,
        adThemeStyle: event.adThemeStyle,
      );

      final newCachedFeed = CachedFeed(
        feedItems: fullyDecoratedFeed,
        hasMore: headlineResponse.hasMore,
        cursor: headlineResponse.cursor,
        lastRefreshedAt: DateTime.now(),
      );

      _feedCacheService.setFeed(filterKey, newCachedFeed);

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: newCachedFeed.feedItems,
          hasMore: newCachedFeed.hasMore,
          cursor: newCachedFeed.cursor,
          filter: state.filter,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onHeadlinesFeedFiltersApplied(
    HeadlinesFeedFiltersApplied event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    String newActiveFilterId;

    // Determine the active filter ID based on the applied criteria.
    // This logic is crucial for correctly highlighting the filter chip in the UI.

    // Case 1: A new filter was just saved ("Save & Apply").
    // The `savedHeadlineFilter` is passed explicitly to prevent a race condition
    // where the `state.savedHeadlineFilters` might not have updated yet.
    // We only care about it if it's pinned.
    if (event.savedHeadlineFilter != null) {
      if (event.savedHeadlineFilter!.isPinned) {
        newActiveFilterId = event.savedHeadlineFilter!.id;
        _logger.fine('Filter applied via "Save & Apply" with a pinned filter.');
      } else {
        // If saved but not pinned, it's treated as a one-time custom filter.
        newActiveFilterId = 'custom';
        _logger.fine(
          'Filter applied via "Save & Apply" with an un-pinned filter. '
          'Treating as "custom".',
        );
      }
    } else {
      // Case 2: A filter was applied from the filter page ("Apply Only") or
      // by applying an un-pinned saved filter.
      // We check if the criteria match any *pinned* saved filter.
      final matchingPinnedFilter = state.savedHeadlineFilters.firstWhereOrNull((
        savedFilter,
      ) {
        // Only consider pinned filters for direct ID matching.
        if (!savedFilter.isPinned) return false;

        // Compare the criteria of the applied filter with the saved one.
        return savedFilter.criteria == event.filter;
      });

      if (matchingPinnedFilter != null) {
        // If it matches a pinned filter, use its ID.
        newActiveFilterId = matchingPinnedFilter.id;
        _logger.fine('Applied filter matches a pinned saved filter.');
      } else {
        // Otherwise, it's a "custom" filter application.
        newActiveFilterId = 'custom';
        _logger.fine('Applied filter is a one-time "custom" filter.');
      }
    }

    final filterKey = _generateFilterKey(newActiveFilterId, event.filter);
    final cachedFeed = _feedCacheService.getFeed(filterKey);

    if (cachedFeed != null) {
      _logger.info(
        'Filter Applied: Cache HIT for key "$filterKey". Emitting cached state.',
      );
      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: cachedFeed.feedItems,
          hasMore: cachedFeed.hasMore,
          cursor: cachedFeed.cursor,
          filter: event.filter,
          activeFilterId: newActiveFilterId,
        ),
      );
      // Only trigger a background refresh if the cache is older than the
      // throttle duration.
      if (DateTime.now().difference(cachedFeed.lastRefreshedAt) >
          _refreshThrottleDuration) {
        _logger.info('Cached data is stale, triggering background refresh.');
        add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      }
      return;
    }

    _logger.info(
      'Filter Applied: Cache MISS for key "$filterKey". Fetching new data.',
    );
    emit(
      state.copyWith(
        filter: event.filter,
        activeFilterId: newActiveFilterId,
        status: HeadlinesFeedStatus.loading,
        adThemeStyle: event.adThemeStyle,
        feedItems: [],
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

      final settings = _appBloc.state.settings;

      // Step 1: Inject the decorator placeholder.
      final feedWithDecorator = _feedDecoratorService.decorateFeed(
        feedItems: headlineResponse.items,
        remoteConfig: appConfig,
      );

      // Step 2: Inject ad placeholders into the resulting list.
      final fullyDecoratedFeed = await _adService.injectFeedAdPlaceholders(
        feedItems: feedWithDecorator,
        user: currentUser,
        remoteConfig: appConfig,
        imageStyle: settings!.feedSettings.feedItemImageStyle,
        adThemeStyle: event.adThemeStyle,
      );

      final newCachedFeed = CachedFeed(
        feedItems: fullyDecoratedFeed,
        hasMore: headlineResponse.hasMore,
        cursor: headlineResponse.cursor,
        lastRefreshedAt: DateTime.now(),
      );

      _feedCacheService.setFeed(filterKey, newCachedFeed);

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: newCachedFeed.feedItems,
          hasMore: newCachedFeed.hasMore,
          cursor: newCachedFeed.cursor,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onHeadlinesFeedFiltersCleared(
    HeadlinesFeedFiltersCleared event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    const filterKey = 'all';
    final cachedFeed = _feedCacheService.getFeed(filterKey);

    if (cachedFeed != null) {
      _logger.info(
        'Filters Cleared: Cache HIT for "all" filter. Emitting cached state.',
      );
      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: cachedFeed.feedItems,
          hasMore: cachedFeed.hasMore,
          cursor: cachedFeed.cursor,
          filter: const HeadlineFilterCriteria(
            topics: [],
            sources: [],
            countries: [],
          ),
          activeFilterId: _allFilterId,
        ),
      );
      // Only trigger a background refresh if the cache is older than the
      // throttle duration.
      if (DateTime.now().difference(cachedFeed.lastRefreshedAt) >
          _refreshThrottleDuration) {
        add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      }
      return;
    }
    _logger.info(
      'Filters Cleared: Cache MISS for "all" filter. Fetching new data.',
    );
    const newFilter = HeadlineFilterCriteria(
      topics: [],
      sources: [],
      countries: [],
    );
    emit(
      state.copyWith(
        status: HeadlinesFeedStatus.loading,
        filter: newFilter,
        activeFilterId: _allFilterId,
        adThemeStyle: event.adThemeStyle,
        feedItems: [],
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
        filter: _buildFilter(newFilter),
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      final settings = _appBloc.state.settings;

      // Step 1: Inject the decorator placeholder.
      final feedWithDecorator = _feedDecoratorService.decorateFeed(
        feedItems: headlineResponse.items,
        remoteConfig: appConfig,
      );

      // Step 2: Inject ad placeholders into the resulting list.
      final fullyDecoratedFeed = await _adService.injectFeedAdPlaceholders(
        feedItems: feedWithDecorator,
        user: currentUser,
        remoteConfig: appConfig,
        imageStyle: settings!.feedSettings.feedItemImageStyle,
        adThemeStyle: event.adThemeStyle,
      );

      final newCachedFeed = CachedFeed(
        feedItems: fullyDecoratedFeed,
        hasMore: headlineResponse.hasMore,
        cursor: headlineResponse.cursor,
        lastRefreshedAt: DateTime.now(),
      );

      _feedCacheService.setFeed(filterKey, newCachedFeed);

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: newCachedFeed.feedItems,
          hasMore: newCachedFeed.hasMore,
          cursor: newCachedFeed.cursor,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onCallToActionTapped(
    CallToActionTapped event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(state.copyWith(navigationUrl: event.url));
  }

  void _onNavigationHandled(
    NavigationHandled event,
    Emitter<HeadlinesFeedState> emit,
  ) {
    emit(
      state.copyWith(clearNavigationUrl: true, clearNavigationArguments: true),
    );
  }

  void _onAppContentPreferencesChanged(
    _AppContentPreferencesChanged event,
    Emitter<HeadlinesFeedState> emit,
  ) {
    emit(
      state.copyWith(
        savedHeadlineFilters: event.preferences.savedHeadlineFilters,
      ),
    );
  }

  Future<void> _onSavedFilterSelected(
    SavedFilterSelected event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    final filterKey = event.filter.id;
    final newFilter = event.filter.criteria;

    // If the selected filter is pinned, we can attempt a cache hit and set
    // its ID as the active one directly.
    if (event.filter.isPinned) {
      final cachedFeed = _feedCacheService.getFeed(filterKey);
      if (cachedFeed != null) {
        _logger.info(
          'Pinned Filter Selected: Cache HIT for key "$filterKey". Emitting cached state.',
        );
        emit(
          state.copyWith(
            status: HeadlinesFeedStatus.success,
            feedItems: cachedFeed.feedItems,
            hasMore: cachedFeed.hasMore,
            cursor: cachedFeed.cursor,
            activeFilterId: filterKey,
            filter: newFilter,
          ),
        );
        // Trigger a background refresh if the cache is stale.
        if (DateTime.now().difference(cachedFeed.lastRefreshedAt) >
            _refreshThrottleDuration) {
          add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
        }
        return;
      }
    }

    // For un-pinned filters, or a cache miss on a pinned filter, delegate
    // to the standard `HeadlinesFeedFiltersApplied` handler. This ensures
    // consistent logic for loading and setting the active filter state
    // (which will be 'custom' for un-pinned filters).
    _logger.info(
      'Saved Filter Selected: Delegating to filter application for key "$filterKey".',
    );
    add(
      HeadlinesFeedFiltersApplied(
        filter: newFilter,
        savedHeadlineFilter: event.filter.isPinned ? null : event.filter,
        adThemeStyle: event.adThemeStyle,
      ),
    );
  }

  Future<void> _onAllFilterSelected(
    AllFilterSelected event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    const filterKey = 'all';
    final cachedFeed = _feedCacheService.getFeed(filterKey);

    if (cachedFeed != null) {
      _logger.info('"All" Filter Selected: Cache HIT. Emitting cached state.');
      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: cachedFeed.feedItems,
          hasMore: cachedFeed.hasMore,
          cursor: cachedFeed.cursor,
          activeFilterId: 'all',
          filter: const HeadlineFilterCriteria(
            topics: [],
            sources: [],
            countries: [],
          ),
        ),
      );
      return;
    }

    _logger.info(
      '"All" Filter Selected: Cache MISS. Delegating to filters cleared.',
    );
    emit(
      state.copyWith(
        activeFilterId: 'all',
        filter: const HeadlineFilterCriteria(
          topics: [],
          sources: [],
          countries: [],
        ),
      ),
    );
    add(HeadlinesFeedFiltersCleared(adThemeStyle: event.adThemeStyle));
  }

  Future<void> _onFollowedFilterSelected(
    FollowedFilterSelected event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    const filterKey = 'followed';
    final cachedFeed = _feedCacheService.getFeed(filterKey);
    final userPreferences = _appBloc.state.userContentPreferences;

    if (userPreferences == null) {
      return;
    }

    final newFilter = HeadlineFilterCriteria(
      topics: userPreferences.followedTopics,
      sources: userPreferences.followedSources,
      countries: userPreferences.followedCountries,
    );

    if (cachedFeed != null) {
      _logger.info(
        '"Followed" Filter Selected: Cache HIT. Emitting cached state.',
      );
      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: cachedFeed.feedItems,
          hasMore: cachedFeed.hasMore,
          cursor: cachedFeed.cursor,
          activeFilterId: 'followed',
          filter: newFilter,
        ),
      );
      // Only trigger a background refresh if the cache is older than the
      // throttle duration.
      if (DateTime.now().difference(cachedFeed.lastRefreshedAt) >
          _refreshThrottleDuration) {
        add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      }
      return;
    }

    _logger.info(
      '"Followed" Filter Selected: Cache MISS. Triggering full refresh.',
    );
    // If it's a cache miss, set the state and trigger a full refresh.
    emit(state.copyWith(activeFilterId: 'followed', filter: newFilter));
    add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
  }

  void _onHeadlinesFeedEngagementTapped(
    HeadlinesFeedEngagementTapped event,
    Emitter<HeadlinesFeedState> emit,
  ) {
    // The UI will listen for this state change and trigger navigation.
    emit(
      state.copyWith(
        navigationUrl:
            '${Routes.feed}/${Routes.engagement.replaceFirst(':', '')}${event.headline.id}',
        navigationArguments: event.headline,
      ),
    );
  }

  @override
  Future<void> close() {
    _appBlocSubscription.cancel();
    _engagementRepositorySubscription.cancel();
    return super.close();
  }
}
