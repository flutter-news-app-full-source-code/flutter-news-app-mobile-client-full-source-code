import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

/// A transformer that debounces events to prevent rapid-fire processing.
///
/// This is particularly useful for search queries to avoid sending a request
/// for every keystroke.
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

/// {@template headline_search_bloc}
/// Manages the state for the headline search feature.
///
/// This BLoC handles incoming search queries, debounces them, fetches
/// matching headlines from the repository, and emits the corresponding state.
/// {@endtemplate}
class HeadlineSearchBloc
    extends Bloc<HeadlineSearchEvent, HeadlineSearchState> {
  /// {@macro headline_search_bloc}
  HeadlineSearchBloc({
    required DataRepository<Headline> headlinesRepository,
  })  : _headlinesRepository = headlinesRepository,
        super(const HeadlineSearchState()) {
    on<HeadlineSearchQueryChanged>(
      _onHeadlineSearchQueryChanged,
      // Apply a debounce transformer to prevent excessive API calls.
      transformer: debounce(const Duration(milliseconds: 350)),
    );
  }

  final DataRepository<Headline> _headlinesRepository;

  /// Handles the [HeadlineSearchQueryChanged] event.
  ///
  /// When the query changes, this method fetches headlines from the repository
  /// that match the query.
  Future<void> _onHeadlineSearchQueryChanged(
    HeadlineSearchQueryChanged event,
    Emitter<HeadlineSearchState> emit,
  ) async {
    final query = event.query;

    // If the query is empty, reset to the initial state.
    if (query.isEmpty) {
      return emit(const HeadlineSearchState(status: HeadlineSearchStatus.initial));
    }

    // Emit loading state before starting the search.
    emit(state.copyWith(status: HeadlineSearchStatus.loading));

    try {
      // Fetch headlines from the repository with a filter on the title.
      final response = await _headlinesRepository.readAll(
        filter: {'title': query},
        pagination: const PaginationOptions(limit: 20),
      );

      // On success, emit the new state with the fetched headlines.
      emit(
        state.copyWith(
          status: HeadlineSearchStatus.success,
          headlines: response.items,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlineSearchStatus.failure, error: e));
    }
  }
}
