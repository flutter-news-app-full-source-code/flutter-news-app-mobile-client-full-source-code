import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/feed_decorator_service.dart';

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
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required FeedDecoratorService feedDecoratorService,
    required AppBloc appBloc,
  }) : _headlinesRepository = headlinesRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _feedDecoratorService = feedDecoratorService,
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
    on<FeedDecoratorDismissed>(
      _onFeedDecoratorDismissed,
      transformer: sequential(),
    );
    on<CallToActionTapped>(_onCallToActionTapped, transformer: sequential());
    on<NavigationHandled>(_onNavigationHandled, transformer: sequential());
  }

  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final FeedDecoratorService _feedDecoratorService;
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

      // For pagination, only inject ad placeholders, not feed actions.
      //
      // This method injects stateless `AdPlaceholder` markers into the feed.
      // The full ad loading and lifecycle is managed by the UI layer.
      // See `FeedDecoratorService` for a detailed explanation.
      final newProcessedFeedItems = await _feedDecoratorService.injectAdPlaceholders(
        feedItems: headlineResponse.items,
        user: currentUser,
        adConfig: remoteConfig.adConfig,
        imageStyle: _appBloc.state.settings.feedPreferences.headlineImageStyle,
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
    AdCacheService().clearAllAds();
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

      // Fetch user content preferences to get followed items for filtering suggestions.
      final userPreferences = currentUser?.id != null
          ? await _userContentPreferencesRepository.read(
              id: currentUser!.id,
              userId: currentUser.id,
            )
          : null;

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
        imageStyle: _appBloc.state.settings.feedPreferences.headlineImageStyle,
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
    // When applying new filters, this is considered a major feed change,
    // so we clear the ad cache to get a fresh set of relevant ads.
    AdCacheService().clearAllAds();
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

      // Fetch user content preferences to get followed items for filtering suggestions.
      final userPreferences = currentUser?.id != null
          ? await _userContentPreferencesRepository.read(
              id: currentUser!.id,
              userId: currentUser.id,
            )
          : null;

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
        imageStyle: _appBloc.state.settings.feedPreferences.headlineImageStyle,
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
    AdCacheService().clearAllAds();
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

      // Fetch user content preferences to get followed items for filtering suggestions.
      final userPreferences = currentUser?.id != null
          ? await _userContentPreferencesRepository.read(id: currentUser!.id)
          : null;

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
        imageStyle: _appBloc.state.settings.feedPreferences.headlineImageStyle,
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
}
