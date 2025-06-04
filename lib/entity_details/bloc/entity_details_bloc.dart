import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // Added
import 'package:ht_main/entity_details/models/entity_type.dart';
import 'package:ht_main/shared/services/feed_injector_service.dart'; // Added
import 'package:ht_shared/ht_shared.dart'; // Ensures FeedItem, AppConfig, User are available

part 'entity_details_event.dart';
part 'entity_details_state.dart';

class EntityDetailsBloc extends Bloc<EntityDetailsEvent, EntityDetailsState> {
  EntityDetailsBloc({
    required HtDataRepository<Headline> headlinesRepository,
    required HtDataRepository<Category> categoryRepository,
    required HtDataRepository<Source> sourceRepository,
    required AccountBloc accountBloc,
    required AppBloc appBloc, // Added
    required FeedInjectorService feedInjectorService, // Added
  }) : _headlinesRepository = headlinesRepository,
       _categoryRepository = categoryRepository,
       _sourceRepository = sourceRepository,
       _accountBloc = accountBloc,
       _appBloc = appBloc, // Added
       _feedInjectorService = feedInjectorService, // Added
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
  final HtDataRepository<Category> _categoryRepository;
  final HtDataRepository<Source> _sourceRepository;
  final AccountBloc _accountBloc;
  final AppBloc _appBloc; // Added
  final FeedInjectorService _feedInjectorService; // Added
  late final StreamSubscription<AccountState> _accountBlocSubscription;

  static const _headlinesLimit = 10; // For fetching original headlines

  Future<void> _onEntityDetailsLoadRequested(
    EntityDetailsLoadRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    emit(
      state.copyWith(status: EntityDetailsStatus.loading, clearEntity: true),
    );

    dynamic entityToLoad = event.entity;
    var entityTypeToLoad = event.entityType;

    try {
      // 1. Determine/Fetch Entity
      if (entityToLoad == null &&
          event.entityId != null &&
          event.entityType != null) {
        entityTypeToLoad = event.entityType; // Ensure type is set
        if (event.entityType == EntityType.category) {
          entityToLoad = await _categoryRepository.read(id: event.entityId!);
        } else if (event.entityType == EntityType.source) {
          entityToLoad = await _sourceRepository.read(id: event.entityId!);
        } else {
          throw Exception('Unknown entity type for ID fetch');
        }
      } else if (entityToLoad != null) {
        // If entity is directly provided, determine its type
        if (entityToLoad is Category) {
          entityTypeToLoad = EntityType.category;
        } else if (entityToLoad is Source) {
          entityTypeToLoad = EntityType.source;
        } else {
          throw Exception('Provided entity is of unknown type');
        }
      }

      if (entityToLoad == null || entityTypeToLoad == null) {
        emit(
          state.copyWith(
            status: EntityDetailsStatus.failure,
            errorMessage: 'Entity could not be determined or loaded.',
          ),
        );
        return;
      }

      // 2. Fetch Initial Headlines
      final queryParams = <String, dynamic>{};
      if (entityTypeToLoad == EntityType.category) {
        queryParams['categories'] = (entityToLoad as Category).id;
      } else if (entityTypeToLoad == EntityType.source) {
        queryParams['sources'] = (entityToLoad as Source).id;
      }

      final headlineResponse = await _headlinesRepository.readAllByQuery(
        queryParams,
        limit: _headlinesLimit,
      );

      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(
          state.copyWith(
            status: EntityDetailsStatus.failure,
            errorMessage: 'App configuration not available.',
            entityType: entityTypeToLoad,
            entity: entityToLoad,
          ),
        );
        return;
      }

      final processedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
        currentFeedItemCount: 0, // Initial load for this entity's feed
      );

      // 3. Determine isFollowing status
      var isCurrentlyFollowing = false;
      final currentAccountState = _accountBloc.state;
      if (currentAccountState.preferences != null) {
        if (entityTypeToLoad == EntityType.category &&
            entityToLoad is Category) {
          isCurrentlyFollowing = currentAccountState
              .preferences!
              .followedCategories
              .any((cat) => cat.id == entityToLoad.id);
        } else if (entityTypeToLoad == EntityType.source &&
            entityToLoad is Source) {
          isCurrentlyFollowing = currentAccountState
              .preferences!
              .followedSources
              .any((src) => src.id == entityToLoad.id);
        }
      }

      emit(
        state.copyWith(
          status: EntityDetailsStatus.success,
          entityType: entityTypeToLoad,
          entity: entityToLoad,
          isFollowing: isCurrentlyFollowing,
          feedItems: processedFeedItems, // Changed
          headlinesStatus: EntityHeadlinesStatus.success,
          hasMoreHeadlines:
              headlineResponse.hasMore, // Based on original headlines
          headlinesCursor: headlineResponse.cursor,
          clearErrorMessage: true,
        ),
      );

      // Dispatch event if AccountAction was injected in the initial load
      if (processedFeedItems.any((item) => item is AccountAction) &&
          _appBloc.state.user?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(userId: _appBloc.state.user!.id),
        );
      }
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          status: EntityDetailsStatus.failure,
          errorMessage: e.message,
          entityType: entityTypeToLoad, // Keep type if known
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EntityDetailsStatus.failure,
          errorMessage: 'An unexpected error occurred: $e',
          entityType: entityTypeToLoad, // Keep type if known
        ),
      );
    }
  }

  Future<void> _onEntityDetailsToggleFollowRequested(
    EntityDetailsToggleFollowRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    if (state.entity == null || state.entityType == null) {
      // Cannot toggle follow if no entity is loaded
      emit(
        state.copyWith(
          errorMessage: 'No entity loaded to follow/unfollow.',
          clearErrorMessage: false, // Keep existing error if any, or set new
        ),
      );
      return;
    }

    // Optimistic update of UI can be handled by listening to AccountBloc state changes
    // which will trigger _onEntityDetailsUserPreferencesChanged.

    if (state.entityType == EntityType.category && state.entity is Category) {
      _accountBloc.add(
        AccountFollowCategoryToggled(category: state.entity as Category),
      );
    } else if (state.entityType == EntityType.source &&
        state.entity is Source) {
      _accountBloc.add(
        AccountFollowSourceToggled(source: state.entity as Source),
      );
    } else {
      // Should not happen if entity and entityType are consistent
      emit(
        state.copyWith(
          errorMessage: 'Cannot determine entity type to follow/unfollow.',
          clearErrorMessage: false,
        ),
      );
    }
    // Note: We don't emit a new state here for `isFollowing` directly.
    // The change will propagate from AccountBloc -> _accountBlocSubscription
    // -> _EntityDetailsUserPreferencesChanged -> update state.isFollowing.
    // This keeps AccountBloc as the source of truth for preferences.
  }

  Future<void> _onEntityDetailsLoadMoreHeadlinesRequested(
    EntityDetailsLoadMoreHeadlinesRequested event,
    Emitter<EntityDetailsState> emit,
  ) async {
    if (!state
            .hasMoreHeadlines || // Still refers to original headlines pagination
        state.headlinesStatus == EntityHeadlinesStatus.loadingMore) {
      return;
    }
    if (state.entity == null || state.entityType == null) return;

    emit(state.copyWith(headlinesStatus: EntityHeadlinesStatus.loadingMore));

    try {
      final queryParams = <String, dynamic>{};
      if (state.entityType == EntityType.category) {
        queryParams['categories'] = (state.entity as Category).id;
      } else if (state.entityType == EntityType.source) {
        queryParams['sources'] = (state.entity as Source).id;
      } else {
        emit(
          state.copyWith(
            headlinesStatus: EntityHeadlinesStatus.failure,
            errorMessage: 'Cannot load more headlines: Unknown entity type.',
          ),
        );
        return;
      }

      final headlineResponse = await _headlinesRepository.readAllByQuery(
        queryParams,
        limit: _headlinesLimit,
        startAfterId: state.headlinesCursor, // Cursor for original headlines
      );

      final currentUser = _appBloc.state.user;
      final appConfig = _appBloc.state.appConfig;

      if (appConfig == null) {
        emit(
          state.copyWith(
            headlinesStatus: EntityHeadlinesStatus.failure,
            errorMessage: 'App configuration not available for pagination.',
          ),
        );
        return;
      }

      final newProcessedFeedItems = _feedInjectorService.injectItems(
        headlines: headlineResponse.items,
        user: currentUser,
        appConfig: appConfig,
        currentFeedItemCount: state.feedItems.length, // Pass current total
      );

      emit(
        state.copyWith(
          feedItems: List.of(state.feedItems)
            ..addAll(newProcessedFeedItems), // Changed
          headlinesStatus: EntityHeadlinesStatus.success,
          hasMoreHeadlines:
              headlineResponse.hasMore, // Based on original headlines
          headlinesCursor: headlineResponse.cursor,
          clearHeadlinesCursor: !headlineResponse.hasMore,
        ),
      );

      // Dispatch event if AccountAction was injected in the newly loaded items
      if (newProcessedFeedItems.any((item) => item is AccountAction) &&
          _appBloc.state.user?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(userId: _appBloc.state.user!.id),
        );
      }
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          headlinesStatus: EntityHeadlinesStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          headlinesStatus: EntityHeadlinesStatus.failure,
          errorMessage: 'An unexpected error occurred: $e',
        ),
      );
    }
  }

  void _onEntityDetailsUserPreferencesChanged(
    _EntityDetailsUserPreferencesChanged event,
    Emitter<EntityDetailsState> emit,
  ) {
    if (state.entity == null || state.entityType == null) return;

    var isCurrentlyFollowing = false;
    final preferences = event.preferences;

    if (state.entityType == EntityType.category && state.entity is Category) {
      final currentCategory = state.entity as Category;
      isCurrentlyFollowing = preferences.followedCategories.any(
        (cat) => cat.id == currentCategory.id,
      );
    } else if (state.entityType == EntityType.source &&
        state.entity is Source) {
      final currentSource = state.entity as Source;
      isCurrentlyFollowing = preferences.followedSources.any(
        (src) => src.id == currentSource.id,
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
