import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart' show HtHttpException, Source;

part 'available_sources_event.dart';
part 'available_sources_state.dart';

class AvailableSourcesBloc
    extends Bloc<AvailableSourcesEvent, AvailableSourcesState> {
  AvailableSourcesBloc({
    required HtDataRepository<Source> sourcesRepository,
  })  : _sourcesRepository = sourcesRepository,
        super(const AvailableSourcesState()) {
    on<FetchAvailableSources>(_onFetchAvailableSources);
  }

  final HtDataRepository<Source> _sourcesRepository;
  // Consider adding a limit if the number of sources can be very large.
  // static const _sourcesLimit = 50; 

  Future<void> _onFetchAvailableSources(
    FetchAvailableSources event,
    Emitter<AvailableSourcesState> emit,
  ) async {
    if (state.status == AvailableSourcesStatus.loading ||
        state.status == AvailableSourcesStatus.success) {
      // Avoid re-fetching if already loading or loaded,
      // unless a refresh mechanism is added.
      return;
    }
    emit(state.copyWith(status: AvailableSourcesStatus.loading));
    try {
      // Assuming readAll without parameters fetches all items.
      // Add pagination if necessary for very large datasets.
      final response = await _sourcesRepository.readAll(
          // limit: _sourcesLimit, // Uncomment if pagination is needed
          );
      emit(
        state.copyWith(
          status: AvailableSourcesStatus.success,
          availableSources: response.items,
          // hasMore: response.hasMore, // Uncomment if pagination is needed
          // cursor: response.cursor, // Uncomment if pagination is needed
          clearError: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          status: AvailableSourcesStatus.failure,
          error: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AvailableSourcesStatus.failure,
          error: 'An unexpected error occurred while fetching sources.',
        ),
      );
    }
  }
}
