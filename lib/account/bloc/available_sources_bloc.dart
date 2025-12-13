import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';

part 'available_sources_event.dart';
part 'available_sources_state.dart';

class AvailableSourcesBloc
    extends Bloc<AvailableSourcesEvent, AvailableSourcesState> {
  AvailableSourcesBloc({required DataRepository<Source> sourcesRepository})
    : _sourcesRepository = sourcesRepository,
      super(const AvailableSourcesState()) {
    on<FetchAvailableSources>(_onFetchAvailableSources);
  }

  final DataRepository<Source> _sourcesRepository;
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
      // Filter to fetch only active sources.
      final response = await _sourcesRepository.readAll(
        filter: {'status': ContentStatus.active.name},
        sort: [const SortOption('name', SortOrder.asc)],
      );
      emit(
        state.copyWith(
          status: AvailableSourcesStatus.success,
          availableSources: response.items,
          // hasMore: response.hasMore,
          // cursor: response.cursor,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
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
