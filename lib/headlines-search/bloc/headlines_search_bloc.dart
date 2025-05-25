import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_shared/ht_shared.dart'; // Shared models, including Headline

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

class HeadlinesSearchBloc
    extends Bloc<HeadlinesSearchEvent, HeadlinesSearchState> {
  HeadlinesSearchBloc({required HtDataRepository<Headline> headlinesRepository})
    : _headlinesRepository = headlinesRepository,
      super(HeadlinesSearchLoading()) {
    on<HeadlinesSearchFetchRequested>(_onSearchFetchRequested);
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

    if (state is HeadlinesSearchSuccess &&
        event.searchTerm == state.lastSearchTerm) {
      final currentState = state as HeadlinesSearchSuccess;
      if (!currentState.hasMore) return;

      try {
        final response = await _headlinesRepository.readAllByQuery(
          {'query': event.searchTerm}, // Use query map
          limit: _limit,
          startAfterId: currentState.cursor,
        );
        emit(
          response.items.isEmpty
              ? currentState.copyWith(hasMore: false)
              : currentState.copyWith(
                headlines: List.of(currentState.headlines)
                  ..addAll(response.items),
                hasMore: response.hasMore,
                cursor: response.cursor,
              ),
        );
      } catch (e) {
        emit(currentState.copyWith(errorMessage: e.toString()));
      }
    } else {
      try {
        final response = await _headlinesRepository.readAllByQuery(
          {'query': event.searchTerm}, // Use query map
          limit: _limit,
        );
        emit(
          HeadlinesSearchSuccess(
            headlines: response.items,
            hasMore: response.hasMore,
            cursor: response.cursor,
            lastSearchTerm: event.searchTerm,
          ),
        );
      } catch (e) {
        emit(
          HeadlinesSearchSuccess(
            headlines: const [],
            hasMore: false,
            errorMessage: e.toString(),
            lastSearchTerm: event.searchTerm,
          ),
        );
      }
    }
  }
}
