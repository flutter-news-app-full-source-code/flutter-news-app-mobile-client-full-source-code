import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_main/headlines-search/models/search_model_type.dart'; // Import SearchModelType
import 'package:ht_shared/ht_shared.dart'; // Shared models, including Headline

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

class HeadlinesSearchBloc
    extends Bloc<HeadlinesSearchEvent, HeadlinesSearchState> {
  HeadlinesSearchBloc({
    required HtDataRepository<Headline> headlinesRepository,
    required HtDataRepository<Category> categoryRepository,
    required HtDataRepository<Source> sourceRepository,
    required HtDataRepository<Country> countryRepository,
  }) : _headlinesRepository = headlinesRepository,
       _categoryRepository = categoryRepository,
       _sourceRepository = sourceRepository,
       _countryRepository = countryRepository,
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
  final HtDataRepository<Country> _countryRepository;
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

    // Removed automatic re-search:
    // if (currentSearchTerm != null && currentSearchTerm.isNotEmpty) {
    //   add(HeadlinesSearchFetchRequested(searchTerm: currentSearchTerm));
    // }
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
          results: const [],
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
            case SearchModelType.category:
              response = await _categoryRepository.readAllByQuery(
                {'q': searchTerm, 'model': modelType.toJson()},
                limit: _limit,
                startAfterId: successState.cursor,
              );
            case SearchModelType.source:
              response = await _sourceRepository.readAllByQuery(
                {'q': searchTerm, 'model': modelType.toJson()},
                limit: _limit,
                startAfterId: successState.cursor,
              );
            case SearchModelType.country:
              response = await _countryRepository.readAllByQuery(
                {'q': searchTerm, 'model': modelType.toJson()},
                limit: _limit,
                startAfterId: successState.cursor,
              );
          }
          emit(
            successState.copyWith(
              results: List.of(successState.results)..addAll(response.items),
              hasMore: response.hasMore,
              cursor: response.cursor,
            ),
          );
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
      PaginatedResponse<dynamic> response;
      switch (modelType) {
        case SearchModelType.headline:
          response = await _headlinesRepository.readAllByQuery({
            'q': searchTerm,
            'model': modelType.toJson(),
          }, limit: _limit,);
        case SearchModelType.category:
          response = await _categoryRepository.readAllByQuery({
            'q': searchTerm,
            'model': modelType.toJson(),
          }, limit: _limit,);
        case SearchModelType.source:
          response = await _sourceRepository.readAllByQuery({
            'q': searchTerm,
            'model': modelType.toJson(),
          }, limit: _limit,);
        case SearchModelType.country:
          response = await _countryRepository.readAllByQuery({
            'q': searchTerm,
            'model': modelType.toJson(),
          }, limit: _limit,);
      }
      emit(
        HeadlinesSearchSuccess(
          results: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          lastSearchTerm: searchTerm,
          selectedModelType: modelType,
        ),
      );
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
