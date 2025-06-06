import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // Added
import 'package:ht_main/headlines-search/models/search_model_type.dart';
import 'package:ht_main/shared/services/feed_injector_service.dart'; // Added
import 'package:ht_shared/ht_shared.dart'; // Updated for FeedItem, AppConfig, User etc.

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

class HeadlinesSearchBloc
    extends Bloc<HeadlinesSearchEvent, HeadlinesSearchState> {
  HeadlinesSearchBloc({
    required HtDataRepository<Headline> headlinesRepository,
    required HtDataRepository<Category> categoryRepository,
    required HtDataRepository<Source> sourceRepository,
    required AppBloc appBloc, // Added
    required FeedInjectorService feedInjectorService, // Added
  }) : _headlinesRepository = headlinesRepository,
       _categoryRepository = categoryRepository,
       _sourceRepository = sourceRepository,
       _appBloc = appBloc, // Added
       _feedInjectorService = feedInjectorService, // Added
       super(const HeadlinesSearchInitial()) {
    on<HeadlinesSearchModelTypeChanged>(_onHeadlinesSearchModelTypeChanged);
    on<HeadlinesSearchFetchRequested>(
      _onSearchFetchRequested,
      transformer: restartable(), // Process only the latest search
    );
  }

  final HtDataRepository<Headline> _headlinesRepository;
  final HtDataRepository<Category> _categoryRepository;
  final HtDataRepository<Source> _sourceRepository;
  final AppBloc _appBloc; // Added
  final FeedInjectorService _feedInjectorService; // Added
  static const _limit = 10;

  Future<void> _onHeadlinesSearchModelTypeChanged(
    HeadlinesSearchModelTypeChanged event,
    Emitter<HeadlinesSearchState> emit,
  ) async {
    // If there's an active search term, re-trigger search with new model type
    // ignore: unused_local_variable
    final currentSearchTerm =
        state is HeadlinesSearchLoading
            ? (state as HeadlinesSearchLoading).lastSearchTerm
            : state is HeadlinesSearchSuccess
            ? (state as HeadlinesSearchSuccess).lastSearchTerm
            : state is HeadlinesSearchFailure
            ? (state as HeadlinesSearchFailure).lastSearchTerm
            : null;

    emit(HeadlinesSearchInitial(selectedModelType: event.newModelType));
  }

  Future<void> _onSearchFetchRequested(
    HeadlinesSearchFetchRequested event,
    Emitter<HeadlinesSearchState> emit,
  ) async {
    final searchTerm = event.searchTerm;
    final modelType = state.selectedModelType;

    if (searchTerm.isEmpty) {
      emit(
        HeadlinesSearchSuccess(
          items: const [], // Changed
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
            case SearchModelType.headline:
              response = await _headlinesRepository.readAllByQuery(
                {'q': searchTerm, 'model': modelType.toJson()},
                limit: _limit,
                startAfterId: successState.cursor,
              );
              // Cast to List<Headline> for the injector
              final headlines = response.items.cast<Headline>();
              final currentUser = _appBloc.state.user;
              final appConfig = _appBloc.state.appConfig;
              if (appConfig == null) {
                emit(
                  successState.copyWith(
                    errorMessage:
                        'App configuration not available for pagination.',
                  ),
                );
                return;
              }
              final injectedItems = _feedInjectorService.injectItems(
                headlines: headlines,
                user: currentUser,
                appConfig: appConfig,
                currentFeedItemCount: successState.items.length,
              );
              emit(
                successState.copyWith(
                  items: List.of(successState.items)..addAll(injectedItems),
                  hasMore:
                      response.hasMore, // hasMore from original headline fetch
                  cursor: response.cursor,
                ),
              );
              // Dispatch event if AccountAction was injected during pagination
              if (injectedItems.any((item) => item is AccountAction) &&
                  _appBloc.state.user?.id != null) {
                _appBloc.add(
                  AppUserAccountActionShown(userId: _appBloc.state.user!.id),
                );
              }
            case SearchModelType.category:
              response = await _categoryRepository.readAllByQuery(
                {'q': searchTerm, 'model': modelType.toJson()},
                limit: _limit,
                startAfterId: successState.cursor,
              );
              emit(
                successState.copyWith(
                  items: List.of(successState.items)
                    ..addAll(response.items.cast<FeedItem>()),
                  hasMore: response.hasMore,
                  cursor: response.cursor,
                ),
              );
            // Added break
            case SearchModelType.source:
              response = await _sourceRepository.readAllByQuery(
                {'q': searchTerm, 'model': modelType.toJson()},
                limit: _limit,
                startAfterId: successState.cursor,
              );
              emit(
                successState.copyWith(
                  items: List.of(successState.items)
                    ..addAll(response.items.cast<FeedItem>()),
                  hasMore: response.hasMore,
                  cursor: response.cursor,
                ),
              );
            // Added break
          }
        } on HtHttpException catch (e) {
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

    // New search
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
        case SearchModelType.headline:
          rawResponse = await _headlinesRepository.readAllByQuery({
            'q': searchTerm,
            'model': modelType.toJson(),
          }, limit: _limit,);
          final headlines = rawResponse.items.cast<Headline>();
          final currentUser = _appBloc.state.user;
          final appConfig = _appBloc.state.appConfig;
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
          processedItems = _feedInjectorService.injectItems(
            headlines: headlines,
            user: currentUser,
            appConfig: appConfig,
            currentFeedItemCount: 0,
          );
        case SearchModelType.category:
          rawResponse = await _categoryRepository.readAllByQuery({
            'q': searchTerm,
            'model': modelType.toJson(),
          }, limit: _limit,);
          processedItems = rawResponse.items.cast<FeedItem>();
        case SearchModelType.source:
          rawResponse = await _sourceRepository.readAllByQuery({
            'q': searchTerm,
            'model': modelType.toJson(),
          }, limit: _limit,);
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
      // Dispatch event if AccountAction was injected in new search
      if (modelType == SearchModelType.headline &&
          processedItems.any((item) => item is AccountAction) &&
          _appBloc.state.user?.id != null) {
        _appBloc.add(
          AppUserAccountActionShown(userId: _appBloc.state.user!.id),
        );
      }
    } on HtHttpException catch (e) {
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
