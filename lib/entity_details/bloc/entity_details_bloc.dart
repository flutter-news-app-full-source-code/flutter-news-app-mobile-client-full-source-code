// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/account_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/feed_injector_service.dart';

part 'entity_details_event.dart';
part 'entity_details_state.dart';

class EntityDetailsBloc extends Bloc<EntityDetailsEvent, EntityDetailsState> {
  EntityDetailsBloc({
    required DataRepository<Headline> headlinesRepository,
    required DataRepository<Topic> topicRepository,
    required DataRepository<Source> sourceRepository,
    required AccountBloc accountBloc,
    required AppBloc appBloc,
    required FeedInjectorService feedInjectorService,
  }) : _headlinesRepository = headlinesRepository,
       _topicRepository = topicRepository,
       _sourceRepository = sourceRepository,
       _accountBloc = accountBloc,
       _appBloc = appBloc,
       _feedInjectorService = feedInjectorService,
       super(const EntityDetailsState()) {
    on<EntityDetailsLoadRequested>(_onEntityDetailsLoadRequested);
    on<EntityDetailsToggleFollowRequested>(
      _onEntityDetailsToggleFollowRequested,
    );
    on<EntityDetailsLoadMoreHeadlinesRequested>(
      _onEntityDetailsLoadMoreHeadlinesRequested,
    );
    on<_EntityDetailsUserPreferencesChanged>(
      _onEntityDetailsUserPreferencesChanged,
    );

    // Listen to AccountBloc for changes in user preferences
    _accountBlocSubscription = _accountBloc.stream.listen((accountState) {
      if (accountState.preferences != null) {
        add(_EntityDetailsUserPreferencesChanged(accountState.preferences!));
      }
    });
  }

  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<Topic> _topicRepository;
  final DataRepository<Source> _sourceRepository;
  final AccountBloc _accountBloc;
  final AppBloc _appBloc;
  final FeedInjectorService _feedInjectorService;
  late final StreamSubscription<AccountState> _accountBlocSubscription;

  static const _headlinesLimit = 10;

  Future<void> _onEntityDetailsLoadRequested(
    EntityDetailsLoadRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    emit(
      state.copyWith(status: EntityDetailsStatus.loading, clearEntity: true),
    );

    try {
      // 1. Determine/Fetch Entity
      FeedItem entityToLoad;
      ContentType contentTypeToLoad;

      if (event.entity != null) {
        entityToLoad = event.entity!;
        contentTypeToLoad = event.entity is Topic
            ? ContentType.topic
            : ContentType.source;
      } else {
        contentTypeToLoad = event.contentType!;
        if (contentTypeToLoad == ContentType.topic) {
          entityToLoad = await _topicRepository.read(id: event.entityId!);
        } else {
          entityToLoad = await _sourceRepository.read(id: event.entityId!);
        }
      }

      // 2. Fetch Initial Headlines
      final filter = <String, dynamic>{};
      if (contentTypeToLoad == ContentType.topic) {
        filter['topic.id'] = (entityToLoad as Topic).id;
      } else {
        filter['source.id'] = (entityToLoad as Source).id;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: filter,
        pagination: const PaginationOptions(limit: _headlinesLimit),
      );

      final currentUser = _appBloc.state.user;
      final remoteConfig = _appBloc.state.remoteConfig;

      if (remoteConfig == null) {
        throw const OperationFailedException(
          'App configuration not available.',
        );
      }

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: remoteConfig,
        currentFeedItemCount: 0,
      );

      // 3. Determine isFollowing status
      var isCurrentlyFollowing = false;
      final preferences = _accountBloc.state.preferences;
      if (preferences != null) {
        if (entityToLoad is Topic) {
          isCurrentlyFollowing = preferences.followedTopics.any(
            (t) => t.id == (entityToLoad as Topic).id,
          );
        } else if (entityToLoad is Source) {
          isCurrentlyFollowing = preferences.followedSources.any(
            (s) => s.id == (entityToLoad as Source).id,
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

      // Dispatch event if AccountAction was injected in the initial load
      if (processedFeedItems.any((item) => item is FeedAction) &&
          _appBloc.state.user?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(
            userId: _appBloc.state.user!.id,
            feedActionType:
                (processedFeedItems.firstWhere((item) => item is FeedAction)
                        as FeedAction)
                    .feedActionType,
            isCompleted: false,
          ),
        );
      }
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

  Future<void> _onEntityDetailsToggleFollowRequested(
    EntityDetailsToggleFollowRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    final entity = state.entity;
    if (entity == null) return;

    if (entity is Topic) {
      _accountBloc.add(AccountFollowTopicToggled(topic: entity));
    } else if (entity is Source) {
      _accountBloc.add(AccountFollowSourceToggled(source: entity));
    }
  }

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
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: filter,
        pagination: PaginationOptions(
          limit: _headlinesLimit,
          cursor: state.headlinesCursor,
        ),
      );

      final currentUser = _appBloc.state.user;
      final remoteConfig = _appBloc.state.remoteConfig;

      if (remoteConfig == null) {
        throw const OperationFailedException(
          'App configuration not available for pagination.',
        );
      }

      final newProcessedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        remoteConfig: remoteConfig,
        currentFeedItemCount: state.feedItems.length,
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

      if (newProcessedFeedItems.any((item) => item is FeedAction) &&
          _appBloc.state.user?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(
            userId: _appBloc.state.user!.id,
            feedActionType:
                (newProcessedFeedItems.firstWhere((item) => item is FeedAction)
                        as FeedAction)
                    .feedActionType,
            isCompleted: false,
          ),
        );
      }
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

  void _onEntityDetailsUserPreferencesChanged(
    _EntityDetailsUserPreferencesChanged event,
    Emitter<EntityDetailsState> emit,
  ) {
    final entity = state.entity;
    if (entity == null) return;

    var isCurrentlyFollowing = false;
    final preferences = event.preferences;

    if (entity is Topic) {
      isCurrentlyFollowing = preferences.followedTopics.any(
        (t) => t.id == entity.id,
      );
    } else if (entity is Source) {
      isCurrentlyFollowing = preferences.followedSources.any(
        (s) => s.id == entity.id,
      );
    }

    if (state.isFollowing != isCurrentlyFollowing) {
      emit(state.copyWith(isFollowing: isCurrentlyFollowing));
    }
  }

  @override
  Future<void> close() {
    _accountBlocSubscription.cancel();
    return super.close();
  }
}
