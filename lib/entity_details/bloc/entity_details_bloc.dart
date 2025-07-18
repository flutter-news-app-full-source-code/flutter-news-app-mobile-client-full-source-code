// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/shared/services/feed_injector_service.dart';
import 'package:ht_shared/ht_shared.dart';

part 'entity_details_event.dart';
part 'entity_details_state.dart';

class EntityDetailsBloc extends Bloc<EntityDetailsEvent, EntityDetailsState> {
  EntityDetailsBloc({
    required HtDataRepository<Headline> headlinesRepository,
    required HtDataRepository<Topic> topicRepository,
    required HtDataRepository<Source> sourceRepository,
    required AccountBloc accountBloc,
    required AppBloc appBloc,
    required FeedInjectorService feedInjectorService,
  })  : _headlinesRepository = headlinesRepository,
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

  final HtDataRepository<Headline> _headlinesRepository;
  final HtDataRepository<Topic> _topicRepository;
  final HtDataRepository<Source> _sourceRepository;
  final AccountBloc _accountBloc;
  final AppBloc _appBloc;
  final FeedInjectorService _feedInjectorService;
  late final StreamSubscription<AccountState> _accountBlocSubscription;

  static const _headlinesLimit = 10;

  Future<void> _onEntityDetailsLoadRequested(
    EntityDetailsLoadRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    emit(state.copyWith(status: EntityDetailsStatus.loading, clearEntity: true));

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
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        throw const OperationFailedException(
          'App configuration not available.',
        );
      }

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
        currentFeedItemCount: 0,
      );

      // 3. Determine isFollowing status
      var isCurrentlyFollowing = false;
      final preferences = _accountBloc.state.preferences;
      if (preferences != null) {
        if (entityToLoad is Topic) {
          isCurrentlyFollowing =
              preferences.followedTopics.any((t) => t.id == entityToLoad.id);
        } else if (entityToLoad is Source) {
          isCurrentlyFollowing =
              preferences.followedSources.any((s) => s.id == entityToLoad.id);
        }
      }

      emit(
        state.copyWith(
          status: EntityDetailsStatus.success,
          contentType: contentTypeToLoad,
          entity: entityToLoad,
          isFollowing: isCurrentlyFollowing,
          feedItems: processedFeedItems,
          hasMoreHeadlines: headlineResponse.nextCursor != null,
          headlinesCursor: headlineResponse.nextCursor,
          clearException: true,
        ),
      );

      // Dispatch event if AccountAction was injected in the initial load
      if (processedFeedItems.any((item) => item is FeedAction) &&
          _appBloc.state.user?.id != null) {
        _appBloc.add(
          const AppFeedActionShown(),
        );
      }
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          status: EntityDetailsStatus.failure,
          exception: e,
        ),
      );
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
    if (state.entity == null) return;

    final entity = state.entity!;
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
        filter['topic.id'] = (state.entity as Topic).id;
      } else if (state.entity is Source) {
        filter['source.id'] = (state.entity as Source).id;
      }

      final headlineResponse = await _headlinesRepository.readAll(
        filter: filter,
        pagination: PaginationOptions(
          limit: _headlinesLimit,
          cursor: state.headlinesCursor,
        ),
      );

      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        throw const OperationFailedException(
          'App configuration not available for pagination.',
        );
      }

      final newProcessedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
        currentFeedItemCount: state.feedItems.length,
      );

      emit(
        state.copyWith(
          status: EntityDetailsStatus.success,
          feedItems: List.of(state.feedItems)..addAll(newProcessedFeedItems),
          hasMoreHeadlines: headlineResponse.nextCursor != null,
          headlinesCursor: headlineResponse.nextCursor,
          clearHeadlinesCursor: headlineResponse.nextCursor == null,
        ),
      );

      if (newProcessedFeedItems.any((item) => item is FeedAction) &&
          _appBloc.state.user?.id != null) {
        _appBloc.add(
          const AppFeedActionShown(),
        );
      }
    } on HtHttpException catch (e) {
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
    if (state.entity == null) return;

    var isCurrentlyFollowing = false;
    final preferences = event.preferences;
    final entity = state.entity!;

    if (entity is Topic) {
      isCurrentlyFollowing =
          preferences.followedTopics.any((t) => t.id == entity.id);
    } else if (entity is Source) {
      isCurrentlyFollowing =
          preferences.followedSources.any((s) => s.id == entity.id);
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
