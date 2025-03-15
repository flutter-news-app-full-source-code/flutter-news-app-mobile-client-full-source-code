import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:stream_transform/stream_transform.dart';

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

class HeadlinesSearchBloc
    extends Bloc<HeadlinesSearchEvent, HeadlinesSearchState> {
  HeadlinesSearchBloc({required HtHeadlinesRepository headlinesRepository})
      : _headlinesRepository = headlinesRepository,
        super(HeadlinesSearchInitial()) {
    on<HeadlinesSearchTermChanged>(
      _onSearchTermChanged,
      transformer: (events, mapper) => events
          .debounce(const Duration(milliseconds: 300))
          .asyncExpand(mapper),
    );
    on<HeadlinesSearchRequested>(_onSearchRequested);
  }

  final HtHeadlinesRepository _headlinesRepository;
  String _searchTerm = '';

  Future<void> _onSearchTermChanged(
    HeadlinesSearchTermChanged event,
    Emitter<HeadlinesSearchState> emit,
  ) async {
    _searchTerm = event.searchTerm;
    if (_searchTerm.isEmpty) {
      emit(HeadlinesSearchInitial());
    }
  }

  Future<void> _onSearchRequested(
    HeadlinesSearchRequested event,
    Emitter<HeadlinesSearchState> emit,
  ) async {
    if (_searchTerm.isEmpty) {
      return; // Don't search if the term is empty
    }
    emit(HeadlinesSearchLoading());
    try {
      final response =
          await _headlinesRepository.searchHeadlines(query: _searchTerm);
      emit(HeadlinesSearchLoaded(headlines: response.items));
    } on HeadlinesSearchException catch (e) {
      emit(HeadlinesSearchError(message: e.message));
    } catch (e) {
      emit(HeadlinesSearchError(message: e.toString()));
    }
  }
}
