import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

class HeadlinesSearchBloc
    extends Bloc<HeadlinesSearchEvent, HeadlinesSearchState> {
  HeadlinesSearchBloc({required HtHeadlinesRepository headlinesRepository})
      : _headlinesRepository = headlinesRepository,
        super(HeadlinesSearchLoading()) {
    on<HeadlinesSearchFetchRequested>(_onSearchFetchRequested);
  }

  final HtHeadlinesRepository _headlinesRepository;
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
        final response = await _headlinesRepository.searchHeadlines(
          query: event.searchTerm,
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
        final response = await _headlinesRepository.searchHeadlines(
          query: event.searchTerm,
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
