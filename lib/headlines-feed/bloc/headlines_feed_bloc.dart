import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/cached_feed.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/feed_decorator_service.dart';
import 'package:logging/logging.dart';

part 'headlines_feed_event.dart';
part 'headlines_feed_state.dart';

/// {@template headlines_feed_bloc}
/// Manages the state for the headlines feed feature.
///
/// This BLoC is the central orchestrator for the news feed. Its core
/// responsibilities include:
/// - Fetching, filtering, and displaying headlines from a [DataRepository].
/// - Injecting dynamic content such as ads and promotional items using the
///   [FeedDecoratorService].
/// - Implementing a robust, session-based in-memory caching strategy via
///   [FeedCacheService] to provide a highly responsive user experience.
///
/// ### Feed Decoration and Ad Injection:
/// On major feed loads (initial load, refresh, or new filter), this BLoC
/// uses the [FeedDecoratorService] to intersperse the headline content with
/// other `FeedItem` types, such as ads and promotional call-to-action items.
///
/// ### Caching and Data Flow Scenarios:
///
/// 1.  **Cache Miss (Initial Load / New Filter):** When a filter is applied for
///     the first time, the BLoC fetches data from the [DataRepository],
///     decorates it using [FeedDecoratorService], and stores the result in the
///     cache before emitting the `success` state.
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
/// 4.  **Pull-to-Refresh (Prepending):** On a pull-to-refresh action, the BLoC
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
    required AppBloc appBloc,
    required InlineAdCacheService inlineAdCacheService,
    required FeedCacheService feedCacheService,
    UserContentPreferences? initialUserContentPreferences,
  })  : _headlinesRepository = headlinesRepository,
        _feedDecoratorService = feedDecoratorService,
        _appBloc = appBloc,
        _inlineAdCacheService = inlineAdCacheService,
        _feedCacheService = feedCacheService,
        _logger = Logger('HeadlinesFeedBloc'),
        super(
          HeadlinesFeedState(
            savedFilters:
                initialUserContentPreferences?.savedFilters ?? const [],
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
      if (appState.userContentPreferences != null &&
          state.savedFilters != appState.userContentPreferences!.savedFilters) {
        add(
          _AppContentPreferencesChanged(
            preferences: appState.userContentPreferences!,
          ),
        );
      }
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
    on<_AppContentPreferencesChanged>(_onAppContentPreferencesChanged);
    on<SavedFilterSelected>(_onSavedFilterSelected, transformer: restartable());
    on<AllFilterSelected>(_onAllFilterSelected, transformer: restartable());
    on<FollowedFilterSelected>(
      _onFollowedFilterSelected,
      transformer: restartable(),
    );
  }

  final DataRepository<Headline> _headlinesRepository;
  final FeedDecoratorService _feedDecoratorService;
  final AppBloc _appBloc;
  final InlineAdCacheService _inlineAdCacheService;
  final FeedCacheService _feedCacheService;
  final Logger _logger;

  /// Subscription to the AppBloc's state stream.
  late final StreamSubscription<AppState> _appBlocSubscription;

  /// The number of headlines to fetch per page.
  static const _headlinesFetchLimit = 10;

  /// The duration to wait before allowing another pull-to-refresh request
  /// for the same filter.
  static const _refreshThrottleDuration = Duration(seconds: 30);

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
    if (filter.eventCountries?.isNotEmpty ?? false) {
      queryFilter['eventCountry.id'] = {
        r'$in': filter.eventCountries!.map((c) => c.id).toList(),
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
  String _generateFilterKey(String activeFilterId, HeadlineFilter filter) {
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

      // For pagination, only inject ad placeholders, not feed actions.
      final newProcessedFeedItems =
          await _feedDecoratorService.injectAdPlaceholders(
        feedItems: headlineResponse.items,
        user: currentUser,
        adConfig: remoteConfig.adConfig,
        imageStyle:
            _appBloc.state.settings!.feedPreferences.headlineImageStyle,
        adThemeStyle: event.adThemeStyle,
        processedContentItemCount:
            cachedFeed.feedItems.whereType<Headline>().length,
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
      final timeSinceLastRefresh =
          DateTime.now().difference(cachedFeed.lastRefreshedAt);
      if (timeSinceLastRefresh < _refreshThrottleDuration) {
        _logger.info(
          'Refresh throttled for filter "$filterKey". '
          'Time since last: $timeSinceLastRefresh.',
        );
        return; // Ignore the request.
      }
    }

    // On a full refresh, clear the ad cache for the current context to ensure
    // fresh ads are loaded.
    _inlineAdCacheService.clearAdsForContext(contextKey: filterKey);
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
          final matchIndex =
              newHeadlines.indexWhere((h) => h.id == firstCachedHeadlineId);

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

      // Use user content preferences from AppBloc for followed items.
      _logger.info(
        'Refresh: Performing full decoration for filter "$filterKey".',
      );
      final userPreferences = _appBloc.state.userContentPreferences;

      // For a major load, use the full decoration pipeline.
      final decorationResult = await _feedDecoratorService.decorateFeed(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: appConfig,
        followedTopicIds:
            userPreferences?.followedTopics.map((t) => t.id).toList() ?? [],
        followedSourceIds:
            userPreferences?.followedSources.map((s) => s.id).toList() ?? [],
        imageStyle: _appBloc.state.settings!.feedPreferences.headlineImageStyle,
        adThemeStyle: event.adThemeStyle,
      );

      final newCachedFeed = CachedFeed(
        feedItems: decorationResult.decoratedItems,
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

      // If a feed decorator was injected, notify AppBloc to update its status.
      final injectedDecorator = decorationResult.injectedDecorator;
      if (injectedDecorator != null && currentUser?.id != null) {
        if (injectedDecorator is CallToActionItem) {
          _appBloc.add(
            AppUserFeedDecoratorShown(
              userId: currentUser!.id,
              feedDecoratorType: injectedDecorator.decoratorType,
            ),
          );
        } else if (injectedDecorator is ContentCollectionItem) {
          _appBloc.add(
            AppUserFeedDecoratorShown(
              userId: currentUser!.id,
              feedDecoratorType: injectedDecorator.decoratorType,
            ),
          );
        }
      }
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlinesFeedStatus.failure, error: e));
    }
  }

  Future<void> _onHeadlinesFeedFiltersApplied(
    HeadlinesFeedFiltersApplied event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    String newActiveFilterId;

    // Prioritize the explicitly passed savedFilter to prevent race conditions.
    if (event.savedFilter != null) {
      newActiveFilterId = event.savedFilter!.id;
    } else {
      final matchingSavedFilter = state.savedFilters.firstWhereOrNull(
        (savedFilter) {
          final appliedTopics = event.filter.topics?.toSet() ?? {};
          final savedTopics = savedFilter.topics.toSet();
          final appliedSources = event.filter.sources?.toSet() ?? {};
          final savedSources = savedFilter.sources.toSet();
          final appliedCountries = event.filter.eventCountries?.toSet() ?? {};
          final savedCountries = savedFilter.countries.toSet();

          return const SetEquality<Topic>()
                  .equals(appliedTopics, savedTopics) &&
              const SetEquality<Source>()
                  .equals(appliedSources, savedSources) &&
              const SetEquality<Country>().equals(
                appliedCountries,
                savedCountries,
              );
        },
      );

      newActiveFilterId = matchingSavedFilter?.id ?? 'custom';
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

      final userPreferences = _appBloc.state.userContentPreferences;

      final decorationResult = await _feedDecoratorService.decorateFeed(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: appConfig,
        followedTopicIds:
            userPreferences?.followedTopics.map((t) => t.id).toList() ?? [],
        followedSourceIds:
            userPreferences?.followedSources.map((s) => s.id).toList() ?? [],
        imageStyle: _appBloc.state.settings!.feedPreferences.headlineImageStyle,
        adThemeStyle: event.adThemeStyle,
      );

      final newCachedFeed = CachedFeed(
        feedItems: decorationResult.decoratedItems,
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

      final injectedDecorator = decorationResult.injectedDecorator;
      if (injectedDecorator != null && currentUser?.id != null) {
        if (injectedDecorator is CallToActionItem) {
          _appBloc.add(
            AppUserFeedDecoratorShown(
              userId: currentUser!.id,
              feedDecoratorType: injectedDecorator.decoratorType,
            ),
          );
        } else if (injectedDecorator is ContentCollectionItem) {
          _appBloc.add(
            AppUserFeedDecoratorShown(
              userId: currentUser!.id,
              feedDecoratorType: injectedDecorator.decoratorType,
            ),
          );
        }
      }
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
          filter: const HeadlineFilter(),
          activeFilterId: 'all',
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
    const newFilter = HeadlineFilter();
    emit(
      state.copyWith(
        status: HeadlinesFeedStatus.loading,
        filter: newFilter,
        activeFilterId: 'all',
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

      final userPreferences = _appBloc.state.userContentPreferences;

      final decorationResult = await _feedDecoratorService.decorateFeed(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: appConfig,
        followedTopicIds:
            userPreferences?.followedTopics.map((t) => t.id).toList() ?? [],
        followedSourceIds:
            userPreferences?.followedSources.map((s) => s.id).toList() ?? [],
        imageStyle: _appBloc.state.settings!.feedPreferences.headlineImageStyle,
        adThemeStyle: event.adThemeStyle,
      );

      final newCachedFeed = CachedFeed(
        feedItems: decorationResult.decoratedItems,
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

      final injectedDecorator = decorationResult.injectedDecorator;
      if (injectedDecorator != null && currentUser?.id != null) {
        if (injectedDecorator is CallToActionItem) {
          _appBloc.add(
            AppUserFeedDecoratorShown(
              userId: currentUser!.id,
              feedDecoratorType: injectedDecorator.decoratorType,
            ),
          );
        } else if (injectedDecorator is ContentCollectionItem) {
          _appBloc.add(
            AppUserFeedDecoratorShown(
              userId: currentUser!.id,
              feedDecoratorType: injectedDecorator.decoratorType,
            ),
          );
        }
      }
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
    emit(state.copyWith(clearNavigationUrl: true));
  }

  void _onAppContentPreferencesChanged(
    _AppContentPreferencesChanged event,
    Emitter<HeadlinesFeedState> emit,
  ) {
    emit(state.copyWith(savedFilters: event.preferences.savedFilters));
  }

  Future<void> _onSavedFilterSelected(
    SavedFilterSelected event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    final filterKey = event.filter.id;
    final cachedFeed = _feedCacheService.getFeed(filterKey);
    final newFilter = HeadlineFilter(
      topics: event.filter.topics,
      sources: event.filter.sources,
      eventCountries: event.filter.countries,
    );

    if (cachedFeed != null) {
      _logger.info(
        'Saved Filter Selected: Cache HIT for key "$filterKey". '
        'Emitting cached state.',
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
      // Only trigger a background refresh if the cache is older than the
      // throttle duration.
      if (DateTime.now().difference(cachedFeed.lastRefreshedAt) >
          _refreshThrottleDuration) {
        add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      }
      return;
    }

    _logger.info(
      'Saved Filter Selected: Cache MISS for key "$filterKey". '
      'Delegating to filter application.',
    );
    emit(state.copyWith(activeFilterId: event.filter.id));
    add(
      HeadlinesFeedFiltersApplied(
        filter: newFilter,
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
          filter: const HeadlineFilter(),
        ),
      );
      return;
    }

    _logger.info(
      '"All" Filter Selected: Cache MISS. Delegating to filter clear.',
    );
    emit(state.copyWith(activeFilterId: 'all', filter: const HeadlineFilter()));
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

    final newFilter = HeadlineFilter(
      topics: userPreferences.followedTopics,
      sources: userPreferences.followedSources,
      eventCountries: userPreferences.followedCountries,
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

  @override
  Future<void> close() {
    _appBlocSubscription.cancel();
    return super.close();
  }
}
