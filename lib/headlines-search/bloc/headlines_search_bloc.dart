// ignore_for_file: no_default_cases

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/feed_decorator_service.dart';

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

/// {@template headlines_search_bloc}
/// A BLoC that manages the state for the headlines search feature.
///
/// This BLoC is responsible for fetching search results based on a query
/// and selected content type, and for injecting ad placeholders into the
/// headline results. It consumes global application state from [AppBloc]
/// for user settings and remote configuration.
/// {@endtemplate}
class HeadlinesSearchBloc
    extends Bloc<HeadlinesSearchEvent, HeadlinesSearchState> {
  /// {@macro headlines_search_bloc}
  HeadlinesSearchBloc({
    required DataRepository<Headline> headlinesRepository,
    required DataRepository<Topic> topicRepository,
    required DataRepository<Source> sourceRepository,
    required DataRepository<Country> countryRepository,
    required AppBloc appBloc,
    required FeedDecoratorService feedDecoratorService,
    required InlineAdCacheService inlineAdCacheService,
  }) : _headlinesRepository = headlinesRepository,
       _topicRepository = topicRepository,
       _sourceRepository = sourceRepository,
       _countryRepository = countryRepository,
       _appBloc = appBloc,
       _feedDecoratorService = feedDecoratorService,
       _inlineAdCacheService = inlineAdCacheService,
       super(const HeadlinesSearchInitial()) {
    on<HeadlinesSearchModelTypeChanged>(_onHeadlinesSearchModelTypeChanged);
    on<HeadlinesSearchFetchRequested>(
      _onSearchFetchRequested,
      transformer: restartable(),
    );
  }

  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<Topic> _topicRepository;
  final DataRepository<Source> _sourceRepository;
  final DataRepository<Country> _countryRepository;
  final AppBloc _appBloc;
  final FeedDecoratorService _feedDecoratorService;
  final InlineAdCacheService _inlineAdCacheService;
  static const _limit = 10;

  /// Handles changes to the selected model type for search.
  ///
  /// If there's an active search term, it re-triggers the search with the
  /// new model type.
  Future<void> _onHeadlinesSearchModelTypeChanged(
    HeadlinesSearchModelTypeChanged event,
    Emitter<HeadlinesSearchState> emit,
  ) async {
    // If there's an active search term, re-trigger search with new model type
    // ignore: unused_local_variable
    final currentSearchTerm = state is HeadlinesSearchLoading
        ? (state as HeadlinesSearchLoading).lastSearchTerm
        : state is HeadlinesSearchSuccess
        ? (state as HeadlinesSearchSuccess).lastSearchTerm
        : state is HeadlinesSearchFailure
        ? (state as HeadlinesSearchFailure).lastSearchTerm
        : null;

    emit(HeadlinesSearchInitial(selectedModelType: event.newModelType));
  }

  /// Handles requests to fetch search results.
  ///
  /// This method performs the actual search operation based on the search term
  /// and selected model type. It also handles pagination and injects ad
  /// placeholders into headline results.
  Future<void> _onSearchFetchRequested(
    HeadlinesSearchFetchRequested event,
    Emitter<HeadlinesSearchState> emit,
  ) async {
    final searchTerm = event.searchTerm;
    final modelType = state.selectedModelType;

    if (searchTerm.isEmpty) {
      emit(
        HeadlinesSearchSuccess(
          items: const [],
          hasMore: false,
          lastSearchTerm: '',
          selectedModelType: modelType,
        ),
      );
      return;
    }

    // Handle pagination
    if (state is HeadlinesSearchSuccess) {
      final successState = state as HeadlinesSearchSuccess;
      if (searchTerm == successState.lastSearchTerm &&
          modelType == successState.selectedModelType) {
        if (!successState.hasMore) return;

        try {
          PaginatedResponse<dynamic> response;
          switch (modelType) {
            case ContentType.headline:
              response = await _headlinesRepository.readAll(
                filter: {'q': searchTerm},
                pagination: PaginationOptions(
                  limit: _limit,
                  cursor: successState.cursor,
                ),
                sort: [const SortOption('updatedAt', SortOrder.desc)],
              );
              // Cast to List<Headline> for the injector
              final headlines = response.items.cast<Headline>();
              final currentUser = _appBloc.state.user;
              final appConfig = _appBloc.state.remoteConfig;
              if (appConfig == null) {
                emit(
                  successState.copyWith(
                    errorMessage:
                        'App configuration not available for pagination.',
                  ),
                );
                return;
              }
              // For search pagination, only inject ad placeholders.
              //
              // This method injects stateless `AdPlaceholder` markers into the feed.
              // The full ad loading and lifecycle is managed by the UI layer.
              // See `FeedDecoratorService` for a detailed explanation.
              final injectedItems = await _feedDecoratorService.injectAdPlaceholders(
                feedItems: headlines,
                user: currentUser,
                adConfig: appConfig.adConfig,
                imageStyle:
                    _appBloc.state.headlineImageStyle, // Use AppBloc getter
                adThemeStyle: event.adThemeStyle,
                // Calculate the count of actual content items (headlines) already in the
                // feed. This is crucial for the FeedDecoratorService to correctly apply
                // ad placement rules across paginated loads.
                processedContentItemCount: successState.items
                    .whereType<Headline>()
                    .length,
              );
              emit(
                successState.copyWith(
                  items: List.of(successState.items)..addAll(injectedItems),
                  hasMore: response.hasMore,
                  cursor: response.cursor,
                ),
              );
            case ContentType.topic:
              response = await _topicRepository.readAll(
                filter: {'q': searchTerm},
                pagination: PaginationOptions(
                  limit: _limit,
                  cursor: successState.cursor,
                ),
                sort: [const SortOption('name', SortOrder.asc)],
              );
              emit(
                successState.copyWith(
                  items: List.of(successState.items)
                    ..addAll(response.items.cast<FeedItem>()),
                  hasMore: response.hasMore,
                  cursor: response.cursor,
                ),
              );
            case ContentType.source:
              response = await _sourceRepository.readAll(
                filter: {'q': searchTerm},
                pagination: PaginationOptions(
                  limit: _limit,
                  cursor: successState.cursor,
                ),
                sort: [const SortOption('name', SortOrder.asc)],
              );
              emit(
                successState.copyWith(
                  items: List.of(successState.items)
                    ..addAll(response.items.cast<FeedItem>()),
                  hasMore: response.hasMore,
                  cursor: response.cursor,
                ),
              );
            case ContentType.country:
              response = await _countryRepository.readAll(
                filter: {'q': searchTerm, 'hasActiveHeadlines': true},
                pagination: const PaginationOptions(limit: _limit),
                sort: [const SortOption('name', SortOrder.asc)],
              );
              emit(
                successState.copyWith(
                  items: List.of(successState.items)
                    ..addAll(response.items.cast<FeedItem>()),
                  hasMore: response.hasMore,
                  cursor: response.cursor,
                ),
              );
          }
        } on HttpException catch (e) {
          emit(successState.copyWith(errorMessage: e.message));
        } catch (e, st) {
          print('Search pagination error ($modelType): $e\n$st');
          emit(
            successState.copyWith(errorMessage: 'Failed to load more results.'),
          );
        }
        return;
      }
    }

    // New search, clear previous ad cache.
    _inlineAdCacheService.clearAllAds();
    emit(
      HeadlinesSearchLoading(
        lastSearchTerm: searchTerm,
        selectedModelType: modelType,
      ),
    );
    try {
      PaginatedResponse<dynamic> rawResponse;
      List<FeedItem> processedItems;

      switch (modelType) {
        case ContentType.headline:
          rawResponse = await _headlinesRepository.readAll(
            filter: {'q': searchTerm},
            pagination: const PaginationOptions(limit: _limit),
            sort: [const SortOption('updatedAt', SortOrder.desc)],
          );
          final headlines = rawResponse.items.cast<Headline>();
          final currentUser = _appBloc.state.user;
          final appConfig = _appBloc.state.remoteConfig;
          if (appConfig == null) {
            emit(
              HeadlinesSearchFailure(
                errorMessage: 'App configuration not available.',
                lastSearchTerm: searchTerm,
                selectedModelType: modelType,
              ),
            );
            return;
          }
          // For search results, only inject ad placeholders.
          //
          // This method injects stateless `AdPlaceholder` markers into the feed.
          // The full ad loading and lifecycle is managed by the UI layer.
          // See `FeedDecoratorService` for a detailed explanation.
          processedItems = await _feedDecoratorService.injectAdPlaceholders(
            feedItems: headlines,
            user: currentUser,
            adConfig: appConfig.adConfig,
            imageStyle: _appBloc.state.headlineImageStyle, // Use AppBloc getter
            adThemeStyle: event.adThemeStyle,
          );
        case ContentType.topic:
          rawResponse = await _topicRepository.readAll(
            filter: {'q': searchTerm},
            pagination: const PaginationOptions(limit: _limit),
            sort: [const SortOption('name', SortOrder.asc)],
          );
          processedItems = rawResponse.items.cast<FeedItem>();
        case ContentType.source:
          rawResponse = await _sourceRepository.readAll(
            filter: {'q': searchTerm},
            pagination: const PaginationOptions(limit: _limit),
            sort: [const SortOption('name', SortOrder.asc)],
          );
          processedItems = rawResponse.items.cast<FeedItem>();
        case ContentType.country:
          rawResponse = await _countryRepository.readAll(
            filter: {'q': searchTerm, 'hasActiveHeadlines': true},
            pagination: const PaginationOptions(limit: _limit),
            sort: [const SortOption('name', SortOrder.asc)],
          );
          processedItems = rawResponse.items.cast<FeedItem>();
      }
      emit(
        HeadlinesSearchSuccess(
          items: processedItems,
          hasMore: rawResponse.hasMore,
          cursor: rawResponse.cursor,
          lastSearchTerm: searchTerm,
          selectedModelType: modelType,
        ),
      );
      // Feed actions are not injected in search results.
    } on HttpException catch (e) {
      emit(
        HeadlinesSearchFailure(
          errorMessage: e.message,
          lastSearchTerm: searchTerm,
          selectedModelType: modelType,
        ),
      );
    } catch (e, st) {
      print('Search error ($modelType): $e\n$st');
      emit(
        HeadlinesSearchFailure(
          errorMessage: 'An unexpected error occurred during search.',
          lastSearchTerm: searchTerm,
          selectedModelType: modelType,
        ),
      );
    }
  }
}
