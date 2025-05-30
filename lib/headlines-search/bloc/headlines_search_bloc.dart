import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_shared/ht_shared.dart'; // Shared models, including Headline

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

class HeadlinesSearchBloc
    extends Bloc<HeadlinesSearchEvent, HeadlinesSearchState> {
  HeadlinesSearchBloc({required HtDataRepository<Headline> headlinesRepository})
    : _headlinesRepository = headlinesRepository,
      super(const HeadlinesSearchInitial()) {
    // Start with Initial state
    on<HeadlinesSearchFetchRequested>(
      _onSearchFetchRequested,
      transformer: restartable(), // Process only the latest search
    );
  }

  final HtDataRepository<Headline> _headlinesRepository;
  static const _limit = 10;

  Future<void> _onSearchFetchRequested(
    HeadlinesSearchFetchRequested event,
    Emitter<HeadlinesSearchState> emit,
  ) async {
    if (event.searchTerm.isEmpty) {
      emit(
        const HeadlinesSearchSuccess(
          headlines: [],
          hasMore: false,
          lastSearchTerm: '',
        ),
      );
      return;
    }

    // Check if current state is success and if the search term is the same for pagination
    if (state is HeadlinesSearchSuccess) {
      final successState = state as HeadlinesSearchSuccess;
      if (event.searchTerm == successState.lastSearchTerm) {
        // This is a pagination request for the current search term
        if (!successState.hasMore) return; // No more items to paginate

        // It's a bit unusual to emit Loading here for pagination,
        // typically UI handles this. Let's keep it simple for now.
        // emit(HeadlinesSearchLoading(lastSearchTerm: event.searchTerm));
        try {
          final response = await _headlinesRepository.readAllByQuery(
            {'q': event.searchTerm},
            limit: _limit,
            startAfterId: successState.cursor,
          );
          emit(
            response.items.isEmpty
                ? successState.copyWith(hasMore: false)
                : successState.copyWith(
                  headlines: List.of(successState.headlines)
                    ..addAll(response.items),
                  hasMore: response.hasMore,
                  cursor: response.cursor,
                ),
          );
        } on HtHttpException catch (e) {
          emit(successState.copyWith(errorMessage: e.message));
        } catch (e, st) {
          print('Search pagination error: $e\n$st');
          emit(
            successState.copyWith(errorMessage: 'Failed to load more results.'),
          );
        }
        return; // Pagination handled
      }
    }

    // If not paginating for the same term, it's a new search or different term
    emit(
      HeadlinesSearchLoading(lastSearchTerm: event.searchTerm),
    ); // Show loading for new search
    try {
      final response = await _headlinesRepository.readAllByQuery({
        'q': event.searchTerm,
      }, limit: _limit);
      emit(
        HeadlinesSearchSuccess(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          lastSearchTerm: event.searchTerm,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        HeadlinesSearchFailure(
          errorMessage: e.message,
          lastSearchTerm: event.searchTerm,
        ),
      );
    } catch (e, st) {
      print('Search error: $e\n$st');
      emit(
        HeadlinesSearchFailure(
          errorMessage: 'An unexpected error occurred during search.',
          lastSearchTerm: event.searchTerm,
        ),
      );
    }
  }
}
