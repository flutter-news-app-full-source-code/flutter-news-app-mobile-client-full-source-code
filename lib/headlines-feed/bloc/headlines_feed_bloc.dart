import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/feed_decorator_service.dart';
import 'package:ui_kit/ui_kit.dart';

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
  HeadlinesFeedBloc({
    required DataRepository<Headline> headlinesRepository,
    required FeedDecoratorService feedDecoratorService,
    required AppBloc appBloc,
    required InlineAdCacheService inlineAdCacheService,
    UserContentPreferences? initialUserContentPreferences,
  }) : _headlinesRepository = headlinesRepository,
       _feedDecoratorService = feedDecoratorService,
       _appBloc = appBloc,
       _inlineAdCacheService = inlineAdCacheService,
       super(
         HeadlinesFeedState(
           // Initialize the state with saved filters from the AppBloc's
           // current state. This prevents a race condition where the
           // feed bloc is created after the AppBloc has already loaded
           // the user's preferences, ensuring the UI has the data
           // from the very beginning.
           savedFilters:
               initialUserContentPreferences?.savedFilters ?? const [],
         ),
       ) {
    // Subscribe to AppBloc to react to global state changes.
    _appBlocSubscription = _appBloc.stream.listen((appState) {
      // 1. Trigger the initial feed fetch.
      // This is the new, robust way to start the feed. We wait until the
      // AppBloc confirms that all user data is loaded and the app is in a
      // stable 'running' state. This prevents race conditions where the
      // feed would try to load before its dependencies (like remote config
      // or user settings) are ready.
      if (!_isInitialFetchDispatched && appState.status.isRunning) {
        // The `adThemeStyle` is derived from the theme, which in turn is
        // derived from the now-guaranteed-to-be-loaded app settings.
        final theme = _appBloc.state.themeMode == ThemeMode.dark
            ? darkTheme(
                scheme: _appBloc.state.flexScheme,
                appTextScaleFactor: _appBloc.state.appTextScaleFactor,
                appFontWeight: _appBloc.state.appFontWeight,
              )
            : lightTheme(
                scheme: _appBloc.state.flexScheme,
                appTextScaleFactor: _appBloc.state.appTextScaleFactor,
                appFontWeight: _appBloc.state.appFontWeight,
              );

        add(
          HeadlinesFeedRefreshRequested(
            adThemeStyle: AdThemeStyle.fromTheme(theme),
          ),
        );
        _isInitialFetchDispatched = true;
      }

      // 2. Handle subsequent updates to user preferences.
      // This ensures that if the user adds or removes a saved filter on
      // another screen, the filter bar in the feed updates accordingly.
      if (appState.userContentPreferences != null &&
          state.savedFilters != appState.userContentPreferences!.savedFilters) {
        add(
          _AppContentPreferencesChanged(
            preferences: appState.userContentPreferences!,
          ),
        );
      }
    });

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

  /// Subscription to the AppBloc's state stream.
  late final StreamSubscription<AppState> _appBlocSubscription;

  /// A flag to ensure the initial fetch is dispatched only once.
  bool _isInitialFetchDispatched = false;

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

      // For pagination, only inject ad placeholders, not feed actions.
      //
      // This method injects stateless `AdPlaceholder` markers into the feed.
      // The full ad loading and lifecycle is managed by the UI layer.
      // See `FeedDecoratorService` for a detailed explanation.
      final newProcessedFeedItems = await _feedDecoratorService.injectAdPlaceholders(
        feedItems: headlineResponse.items,
        user: currentUser,
        adConfig: remoteConfig.adConfig,
        imageStyle: _appBloc.state.settings!.feedPreferences.headlineImageStyle,
        adThemeStyle: event.adThemeStyle,
        // Calculate the count of actual content items (headlines) already in the
        // feed. This is crucial for the FeedDecoratorService to correctly apply
        // ad placement rules across paginated loads.
        processedContentItemCount: state.feedItems.whereType<Headline>().length,
      );

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: List.of(state.feedItems)..addAll(newProcessedFeedItems),
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

      // Use user content preferences from AppBloc for followed items.
      final userPreferences = _appBloc.state.userContentPreferences;

      // For a major load, use the full decoration pipeline, which includes
      // injecting a high-priority decorator and stateless ad placeholders.
      // See `FeedDecoratorService` for a detailed explanation of the ad architecture.
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

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: decorationResult.decoratedItems,
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
          filter: state.filter,
        ),
      );

      // If a feed decorator was injected, notify AppBloc to update its status.
      final injectedDecorator = decorationResult.injectedDecorator;
      if (injectedDecorator != null && currentUser?.id != null) {
        // Notify AppBloc that a decorator was shown, so its status can be persisted.
        // Safely cast to access decoratorType, as it's guaranteed to be one of these types.
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
    // This is crucial for the "save and apply" flow, where the AppBloc might
    // not have updated the savedFilters list in this bloc's state yet.
    if (event.savedFilter != null) {
      newActiveFilterId = event.savedFilter!.id;
    } else {
      // If no filter is explicitly passed, determine if the applied filter
      // matches an existing saved filter. This handles re-applying a saved
      // filter or applying a one-time "custom" filter.
      final matchingSavedFilter = state.savedFilters.firstWhereOrNull((
        savedFilter,
      ) {
        // Use sets for order-agnostic comparison of filter contents.
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

      // If a match is found, use its ID. Otherwise, mark it as 'custom'.
      newActiveFilterId = matchingSavedFilter?.id ?? 'custom';
    }

    // When applying new filters, this is considered a major feed change,
    // so we clear the ad cache to get a fresh set of relevant ads.
    _inlineAdCacheService.clearAllAds();
    emit(
      state.copyWith(
        filter: event.filter,
        activeFilterId: newActiveFilterId,
        status: HeadlinesFeedStatus.loading,
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

      // Use user content preferences from AppBloc for followed items.
      final userPreferences = _appBloc.state.userContentPreferences;

      // Use the full decoration pipeline, which includes injecting a
      // high-priority decorator and stateless ad placeholders.
      // See `FeedDecoratorService` for a detailed explanation of the ad architecture.
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

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: decorationResult.decoratedItems,
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
        ),
      );

      final injectedDecorator = decorationResult.injectedDecorator;
      if (injectedDecorator != null && currentUser?.id != null) {
        // Notify AppBloc that a decorator was shown, so its status can be persisted.
        // Safely cast to access decoratorType, as it's guaranteed to be one of these types.
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
    // Clearing filters is a major feed change, so clear the ad cache.
    const newFilter = HeadlineFilter();
    _inlineAdCacheService.clearAllAds();
    emit(
      state.copyWith(
        status: HeadlinesFeedStatus.loading,
        filter: newFilter,
        activeFilterId: 'all',
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
        filter: _buildFilter(newFilter),
        pagination: const PaginationOptions(limit: _headlinesFetchLimit),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      // Use user content preferences from AppBloc for followed items.
      final userPreferences = _appBloc.state.userContentPreferences;

      // Use the full decoration pipeline, which includes injecting a
      // high-priority decorator and stateless ad placeholders.
      // See `FeedDecoratorService` for a detailed explanation of the ad architecture.
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

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: decorationResult.decoratedItems,
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
        ),
      );

      final injectedDecorator = decorationResult.injectedDecorator;
      if (injectedDecorator != null && currentUser?.id != null) {
        // Notify AppBloc that a decorator was shown, so its status can be persisted.
        // Safely cast to access decoratorType, as it's guaranteed to be one of these types.
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

  /// Handles the dismissal of a feed decorator.
  ///
  /// Notifies the [AppBloc] to update the user's feed decorator status,
  /// marking it as completed so it won't be shown again.
  Future<void> _onFeedDecoratorDismissed(
    FeedDecoratorDismissed event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    final currentUser = _appBloc.state.user;
    if (currentUser == null) return;

    // Notify AppBloc to mark the decorator as completed for the user.
    _appBloc.add(
      AppUserFeedDecoratorShown(
        userId: currentUser.id,
        feedDecoratorType: event.feedDecoratorType,
        isCompleted: true,
      ),
    );
    // Remove the dismissed decorator from the current feedItems list to
    // immediately update the UI.
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

  /// Handles a tap on a call-to-action decorator.
  ///
  /// This typically involves navigating to an external URL or an internal route.
  /// The BLoC emits a state that the UI can listen to for navigation.
  Future<void> _onCallToActionTapped(
    CallToActionTapped event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    // Emit a state that contains the URL. The UI will listen for this
    // change, trigger navigation, and then dispatch an event to clear the URL.
    emit(state.copyWith(navigationUrl: event.url));
  }

  void _onNavigationHandled(
    NavigationHandled event,
    Emitter<HeadlinesFeedState> emit,
  ) {
    // Clear the navigationUrl from the state after it has been handled by the UI.
    emit(state.copyWith(clearNavigationUrl: true));
  }

  /// Handles updates to user content preferences from the AppBloc.
  void _onAppContentPreferencesChanged(
    _AppContentPreferencesChanged event,
    Emitter<HeadlinesFeedState> emit,
  ) {
    emit(state.copyWith(savedFilters: event.preferences.savedFilters));
  }

  /// Handles the selection of a saved filter from the filter bar.
  ///
  /// This creates a [HeadlineFilter] from the selected [SavedFilter] and
  /// triggers a full feed refresh.
  Future<void> _onSavedFilterSelected(
    SavedFilterSelected event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    final newFilter = HeadlineFilter(
      topics: event.filter.topics,
      sources: event.filter.sources,
      eventCountries: event.filter.countries,
    );

    // Set the active filter ID and then dispatch an event to apply the filter
    // and refresh the feed.
    emit(state.copyWith(activeFilterId: event.filter.id));
    add(
      HeadlinesFeedFiltersApplied(
        filter: newFilter,
        adThemeStyle: event.adThemeStyle,
      ),
    );
  }

  /// Handles the selection of the "All" filter from the filter bar.
  ///
  /// This clears all active filters and triggers a full feed refresh.
  Future<void> _onAllFilterSelected(
    AllFilterSelected event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    // Immediately clear the filter object in the state when 'All' is selected.
    // This prevents the old 'custom' filter from persisting during the
    // subsequent refresh action.
    emit(state.copyWith(activeFilterId: 'all', filter: const HeadlineFilter()));
    add(HeadlinesFeedFiltersCleared(adThemeStyle: event.adThemeStyle));
  }

  /// Handles the selection of the "Followed" filter from the filter bar.
  ///
  /// This creates a [HeadlineFilter] from the user's followed items and
  /// triggers a full feed refresh directly within this handler. It no longer
  /// delegates to `HeadlinesFeedFiltersApplied` to prevent a bug where the
  /// filter would be incorrectly identified as 'custom'.
  Future<void> _onFollowedFilterSelected(
    FollowedFilterSelected event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    final userPreferences = _appBloc.state.userContentPreferences;
    if (userPreferences == null) {
      return;
    }

    final newFilter = HeadlineFilter(
      topics: userPreferences.followedTopics,
      sources: userPreferences.followedSources,
      eventCountries: userPreferences.followedCountries,
    );

    // This is a major feed change, so clear the ad cache.
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

      emit(
        state.copyWith(
          status: HeadlinesFeedStatus.success,
          feedItems: decorationResult.decoratedItems,
          hasMore: headlineResponse.hasMore,
          cursor: headlineResponse.cursor,
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
