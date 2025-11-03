// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

part 'entity_details_event.dart';
part 'entity_details_state.dart';

/// {@template entity_details_bloc}
/// Manages the state for the entity details feature.
///
/// This BLoC is responsible for fetching the details of a specific entity
/// (Topic, Source, or Country) and its associated headlines. It also handles
/// toggling the "follow" status of the entity by dispatching events to the
/// [AppBloc], which is the single source of truth for user preferences.
/// {@endtemplate}
class EntityDetailsBloc extends Bloc<EntityDetailsEvent, EntityDetailsState> {
  /// {@macro entity_details_bloc}
  EntityDetailsBloc({
    required DataRepository<Headline> headlinesRepository,
    required DataRepository<Topic> topicRepository,
    required DataRepository<Source> sourceRepository,
    required DataRepository<Country> countryRepository,
    required AppBloc appBloc,
    required AdService adService,
    required InlineAdCacheService inlineAdCacheService,
  }) : _headlinesRepository = headlinesRepository,
       _topicRepository = topicRepository,
       _sourceRepository = sourceRepository,
       _countryRepository = countryRepository,
       _appBloc = appBloc,
       _adService = adService,
       _inlineAdCacheService = inlineAdCacheService,
       super(const EntityDetailsState()) {
    on<EntityDetailsLoadRequested>(_onEntityDetailsLoadRequested);
    on<EntityDetailsToggleFollowRequested>(
      _onEntityDetailsToggleFollowRequested,
    );
    on<EntityDetailsLoadMoreHeadlinesRequested>(
      _onEntityDetailsLoadMoreHeadlinesRequested,
    );
  }

  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<Topic> _topicRepository;
  final DataRepository<Source> _sourceRepository;
  final DataRepository<Country> _countryRepository;
  final AppBloc _appBloc;
  final AdService _adService;
  final InlineAdCacheService _inlineAdCacheService;

  static const _headlinesLimit = 10;

  /// Handles the [EntityDetailsLoadRequested] event.
  ///
  /// Fetches the entity details and its initial set of headlines.
  Future<void> _onEntityDetailsLoadRequested(
    EntityDetailsLoadRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    emit(
      state.copyWith(status: EntityDetailsStatus.loading, clearEntity: true),
    );

    // On a full load, clear the ad cache for this entity to ensure fresh ads.
    _inlineAdCacheService.clearAdsForContext(contextKey: event.entityId);

    try {
      // 1. Determine/Fetch Entity
      FeedItem entityToLoad;
      final contentTypeToLoad = event.contentType;

      switch (contentTypeToLoad) {
        case ContentType.topic:
          entityToLoad = await _topicRepository.read(id: event.entityId);
        case ContentType.source:
          entityToLoad = await _sourceRepository.read(id: event.entityId);
        case ContentType.country:
          entityToLoad = await _countryRepository.read(id: event.entityId);
        // ignore: no_default_cases
        default:
          throw const OperationFailedException(
            'Unsupported ContentType for EntityDetails.',
          );
      }

      // 2. Fetch Initial Headlines
      final filter = <String, dynamic>{};
      if (contentTypeToLoad == ContentType.topic) {
        filter['topic.id'] = (entityToLoad as Topic).id;
      } else if (contentTypeToLoad == ContentType.source) {
        filter['source.id'] = (entityToLoad as Source).id;
      } else if (contentTypeToLoad == ContentType.country) {
        filter['eventCountry.id'] = (entityToLoad as Country).id;
      }

      // Always filter for active headlines.
      filter['status'] = ContentStatus.active.name;

      final headlineResponse = await _headlinesRepository.readAll(
        filter: filter,
        pagination: const PaginationOptions(limit: _headlinesLimit),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      final currentUser = _appBloc.state.user;
      final remoteConfig = _appBloc.state.remoteConfig;

      if (remoteConfig == null) {
        throw const OperationFailedException(
          'App configuration not available.',
        );
      }

      // For entity details, only inject ad placeholders.
      //
      // This method injects stateless `AdPlaceholder` markers into the feed.
      // The full ad loading and lifecycle is managed by the UI layer.
      // See `AdService` for a detailed explanation.
      final processedFeedItems = await _adService.injectAdPlaceholders(
        feedItems: headlineResponse.items,
        user: currentUser,
        adConfig: remoteConfig.adConfig,
        imageStyle: _appBloc.state.headlineImageStyle,
        adThemeStyle: event.adThemeStyle,
      );

      // 3. Determine isFollowing status from AppBloc's user preferences
      var isCurrentlyFollowing = false;
      final preferences = _appBloc.state.userContentPreferences;
      if (preferences != null) {
        if (entityToLoad is Topic) {
          isCurrentlyFollowing = preferences.followedTopics.any(
            (t) => t.id == (entityToLoad as Topic).id,
          );
        } else if (entityToLoad is Source) {
          isCurrentlyFollowing = preferences.followedSources.any(
            (s) => s.id == (entityToLoad as Source).id,
          );
        } else if (entityToLoad is Country) {
          isCurrentlyFollowing = preferences.followedCountries.any(
            (c) => c.id == (entityToLoad as Country).id,
          );
        }
      }

      emit(
        state.copyWith(
          status: EntityDetailsStatus.success,
          contentType: contentTypeToLoad,
          entity: entityToLoad,
          isFollowing: isCurrentlyFollowing,
          feedItems: processedFeedItems,
          hasMoreHeadlines: headlineResponse.hasMore,
          headlinesCursor: headlineResponse.cursor,
          clearException: true,
        ),
      );

      // Feed actions are not injected in entity detail feeds.
    } on HttpException catch (e) {
      emit(state.copyWith(status: EntityDetailsStatus.failure, exception: e));
    } catch (e) {
      emit(
        state.copyWith(
          status: EntityDetailsStatus.failure,
          exception: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles the [EntityDetailsToggleFollowRequested] event.
  ///
  /// Dispatches an [AppUserContentPreferencesChanged] event to the [AppBloc]
  /// to update the user's followed entities.
  Future<void> _onEntityDetailsToggleFollowRequested(
    EntityDetailsToggleFollowRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    final entity = state.entity;
    final currentUser = _appBloc.state.user;
    final currentPreferences = _appBloc.state.userContentPreferences;

    if (entity == null || currentUser == null || currentPreferences == null) {
      return;
    }

    // Create a mutable copy of the lists to modify
    final updatedFollowedTopics = List<Topic>.from(
      currentPreferences.followedTopics,
    );
    final updatedFollowedSources = List<Source>.from(
      currentPreferences.followedSources,
    );
    final updatedFollowedCountries = List<Country>.from(
      currentPreferences.followedCountries,
    );

    var isCurrentlyFollowing = false;

    if (entity is Topic) {
      final topic = entity;
      if (updatedFollowedTopics.any((t) => t.id == topic.id)) {
        updatedFollowedTopics.removeWhere((t) => t.id == topic.id);
      } else {
        updatedFollowedTopics.add(topic);
        isCurrentlyFollowing = true;
      }
    } else if (entity is Source) {
      final source = entity;
      if (updatedFollowedSources.any((s) => s.id == source.id)) {
        updatedFollowedSources.removeWhere((s) => s.id == source.id);
      } else {
        updatedFollowedSources.add(source);
        isCurrentlyFollowing = true;
      }
    } else if (entity is Country) {
      final country = entity;
      if (updatedFollowedCountries.any((c) => c.id == country.id)) {
        updatedFollowedCountries.removeWhere((c) => c.id == country.id);
      } else {
        updatedFollowedCountries.add(country);
        isCurrentlyFollowing = true;
      }
    }

    // Create a new UserContentPreferences object with the updated lists
    final newPreferences = currentPreferences.copyWith(
      followedTopics: updatedFollowedTopics,
      followedSources: updatedFollowedSources,
      followedCountries: updatedFollowedCountries,
    );

    // Dispatch the event to AppBloc to update and persist preferences
    _appBloc.add(AppUserContentPreferencesChanged(preferences: newPreferences));

    // Optimistically update local state
    emit(state.copyWith(isFollowing: isCurrentlyFollowing));
  }

  /// Handles the [EntityDetailsLoadMoreHeadlinesRequested] event.
  ///
  /// Fetches the next page of headlines for the current entity.
  Future<void> _onEntityDetailsLoadMoreHeadlinesRequested(
    EntityDetailsLoadMoreHeadlinesRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    if (!state.hasMoreHeadlines ||
        state.status == EntityDetailsStatus.loadingMore) {
      return;
    }
    if (state.entity == null) return;

    emit(state.copyWith(status: EntityDetailsStatus.loadingMore));

    try {
      final filter = <String, dynamic>{};
      if (state.entity is Topic) {
        filter['topic.id'] = (state.entity! as Topic).id;
      } else if (state.entity is Source) {
        filter['source.id'] = (state.entity! as Source).id;
      } else if (state.entity is Country) {
        filter['eventCountry.id'] = (state.entity! as Country).id;
      }

      // Always filter for active headlines.
      filter['status'] = ContentStatus.active.name;

      final headlineResponse = await _headlinesRepository.readAll(
        filter: filter,
        pagination: PaginationOptions(
          limit: _headlinesLimit,
          cursor: state.headlinesCursor,
        ),
        sort: [const SortOption('updatedAt', SortOrder.desc)],
      );

      final currentUser = _appBloc.state.user;
      final remoteConfig = _appBloc.state.remoteConfig;

      if (remoteConfig == null) {
        throw const OperationFailedException(
          'App configuration not available for pagination.',
        );
      }

      // For entity details pagination, only inject ad placeholders.
      //
      // This method injects stateless `AdPlaceholder` markers into the feed.
      // The full ad loading and lifecycle is managed by the UI layer.
      // See `FeedDecoratorService` for a detailed explanation.
      final newProcessedFeedItems = await _adService.injectAdPlaceholders(
        feedItems: headlineResponse.items,
        user: currentUser,
        adConfig: remoteConfig.adConfig,
        imageStyle: _appBloc.state.headlineImageStyle,
        // Use the AdThemeStyle passed directly from the UI via the event.
        // This ensures that ads are styled consistently with the current,
        // fully-resolved theme of the widget, preventing visual discrepancies.
        adThemeStyle: event.adThemeStyle,
        // Calculate the count of actual content items (headlines) already in the
        // feed. This is crucial for the FeedDecoratorService to correctly apply
        // ad placement rules across paginated loads.
        processedContentItemCount: state.feedItems.whereType<Headline>().length,
      );

      emit(
        state.copyWith(
          status: EntityDetailsStatus.success,
          feedItems: List.of(state.feedItems)..addAll(newProcessedFeedItems),
          hasMoreHeadlines: headlineResponse.hasMore,
          headlinesCursor: headlineResponse.cursor,
          clearHeadlinesCursor: !headlineResponse.hasMore,
        ),
      );
    } on HttpException catch (e) {
      emit(
        state.copyWith(
          status: EntityDetailsStatus.partialFailure,
          exception: e,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EntityDetailsStatus.partialFailure,
          exception: UnknownException(e.toString()),
        ),
      );
    }
  }
}
