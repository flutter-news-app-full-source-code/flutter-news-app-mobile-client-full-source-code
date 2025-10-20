import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

part 'source_search_event.dart';
part 'source_search_state.dart';

const _duration = Duration(milliseconds: 300);

EventTransformer<Event> debounce<Event>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

/// {@template source_search_bloc}
/// A BLoC that manages the state of the source search feature.
///
/// This BLoC is responsible for handling search queries and fetching
/// matching sources from the repository.
/// {@endtemplate}
class SourceSearchBloc extends Bloc<SourceSearchEvent, SourceSearchState> {
  /// {@macro source_search_bloc}
  SourceSearchBloc({required DataRepository<Source> sourcesRepository})
    : _sourcesRepository = sourcesRepository,
      super(const SourceSearchState()) {
    on<SourceSearchQueryChanged>(
      _onSourceSearchQueryChanged,
      transformer: debounce(_duration),
    );
  }

  final DataRepository<Source> _sourcesRepository;

  /// Handles the search query changes.
  ///
  /// When [SourceSearchQueryChanged] is added, this method performs a search
  /// against the sources repository and emits a success or failure state.
  Future<void> _onSourceSearchQueryChanged(
    SourceSearchQueryChanged event,
    Emitter<SourceSearchState> emit,
  ) async {
    final query = event.query;

    if (query.isEmpty) {
      return emit(const SourceSearchState());
    }

    emit(state.copyWith(status: SourceSearchStatus.loading));

    try {
      final response = await _sourcesRepository.readAll(
        filter: {
          'name': {r'$regex': query, r'$options': 'i'},
        },
      );
      emit(
        state.copyWith(
          status: SourceSearchStatus.success,
          sources: response.items,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SourceSearchStatus.failure,
          error: e as Exception,
        ),
      );
    }
  }
}
