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
/// Handles fetching headlines, applying filters, pagination, and refreshing
/// the feed using the provided [DataRepository]. It uses [FeedDecoratorService]
/// to inject ads and account actions into the feed.
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
  }) : _headlinesRepository = headlinesRepository,
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
    on<FeedDecoratorDismissed>(
      _onFeedDecoratorDismissed,
      transformer: sequential(),
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
      final newProcessedFeedItems = await _feedDecoratorService
          .injectAdPlaceholders(
            feedItems: headlineResponse.items,
            user: currentUser,
            adConfig: remoteConfig.adConfig,
            imageStyle:
                _appBloc.state.settings!.feedPreferences.headlineImageStyle,
            adThemeStyle: event.adThemeStyle,
            processedContentItemCount: cachedFeed.feedItems
                .whereType<Headline>()
                .length,
          );

      final updatedFeedItems = List.of(cachedFeed.feedItems)
        ..addAll(newProcessedFeedItems);

      final updatedCachedFeed = cachedFeed.copyWith(
        feedItems: updatedFeedItems,
        hasMore: headlineResponse.hasMore,
        cursor: headlineResponse.cursor,
      );

      _feedCacheService.updateFeed(filterKey, updatedCachedFeed);

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
        return; // Ignore the request.
      }
    }

    // On a full refresh, clear the ad cache to ensure fresh ads are loaded.
    _inlineAdCacheService.clearAllAds();
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
            final itemsToPrepend = newHeadlines.sublist(0, matchIndex);
            if (itemsToPrepend.isNotEmpty) {
              final updatedFeedItems = List<FeedItem>.from(itemsToPrepend)
                ..addAll(cachedFeed.feedItems);

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
            }
          }
        }
      }

      // Use user content preferences from AppBloc for followed items.
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
      final matchingSavedFilter = state.savedFilters.firstWhereOrNull((
        savedFilter,
      ) {
        final appliedTopics = event.filter.topics?.toSet() ?? {};
        final savedTopics = savedFilter.topics.toSet();
        final appliedSources = event.filter.sources?.toSet() ?? {};
        final savedSources = savedFilter.sources.toSet();
        final appliedCountries = event.filter.eventCountries?.toSet() ?? {};
        final savedCountries = savedFilter.countries.toSet();

        return const SetEquality<Topic>().equals(appliedTopics, savedTopics) &&
            const SetEquality<Source>().equals(appliedSources, savedSources) &&
            const SetEquality<Country>().equals(
              appliedCountries,
              savedCountries,
            );
      });

      newActiveFilterId = matchingSavedFilter?.id ?? 'custom';
    }

    final filterKey = _generateFilterKey(newActiveFilterId, event.filter);
    final cachedFeed = _feedCacheService.getFeed(filterKey);

    if (cachedFeed != null) {
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
      // Trigger a background refresh if the cache might be stale.
      add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      return;
    }

    _inlineAdCacheService.clearAllAds();
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
      add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      return;
    }

    const newFilter = HeadlineFilter();
    _inlineAdCacheService.clearAllAds();
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

  Future<void> _onFeedDecoratorDismissed(
    FeedDecoratorDismissed event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    final currentUser = _appBloc.state.user;
    if (currentUser == null) return;

    _appBloc.add(
      AppUserFeedDecoratorShown(
        userId: currentUser.id,
        feedDecoratorType: event.feedDecoratorType,
        isCompleted: true,
      ),
    );
    final newFeedItems = List<FeedItem>.from(state.feedItems)
      ..removeWhere((item) {
        if (item is CallToActionItem) {
          return item.decoratorType == event.feedDecoratorType;
        }
        if (item is ContentCollectionItem) {
          return item.decoratorType == event.feedDecoratorType;
        }
        return false;
      });

    emit(state.copyWith(feedItems: newFeedItems));
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
      add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      return;
    }

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
      add(HeadlinesFeedRefreshRequested(adThemeStyle: event.adThemeStyle));
      return;
    }

    _inlineAdCacheService.clearAllAds();
    emit(
      state.copyWith(
        status: HeadlinesFeedStatus.loading,
        filter: newFilter,
        activeFilterId: 'followed',
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

      final decorationResult = await _feedDecoratorService.decorateFeed(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: appConfig,
        followedTopicIds: userPreferences.followedTopics
            .map((t) => t.id)
            .toList(),
        followedSourceIds: userPreferences.followedSources
            .map((s) => s.id)
            .toList(),
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

  @override
  Future<void> close() {
    _appBlocSubscription.cancel();
    return super.close();
  }
}
