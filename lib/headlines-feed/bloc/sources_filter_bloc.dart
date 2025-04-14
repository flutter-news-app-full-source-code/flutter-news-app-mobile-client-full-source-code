import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart'; // For transformers
import 'package:equatable/equatable.dart';
import 'package:ht_shared/ht_shared.dart'; // For PaginatedResponse
import 'package:ht_sources_client/ht_sources_client.dart'; // Keep existing, also for Source model
import 'package:ht_sources_repository/ht_sources_repository.dart';

part 'sources_filter_event.dart';
part 'sources_filter_state.dart';

/// {@template sources_filter_bloc}
/// Manages the state for fetching and displaying sources for filtering.
///
/// Handles initial fetching and pagination of sources using the
/// provided [HtSourcesRepository].
/// {@endtemplate}
class SourcesFilterBloc extends Bloc<SourcesFilterEvent, SourcesFilterState> {
  /// {@macro sources_filter_bloc}
  ///
  /// Requires a [HtSourcesRepository] to interact with the data layer.
  SourcesFilterBloc({required HtSourcesRepository sourcesRepository})
      : _sourcesRepository = sourcesRepository,
        super(const SourcesFilterState()) {
    on<SourcesFilterRequested>(
      _onSourcesFilterRequested,
      transformer: restartable(), // Only process the latest request
    );
    on<SourcesFilterLoadMoreRequested>(
      _onSourcesFilterLoadMoreRequested,
      transformer: droppable(), // Ignore new requests while one is processing
    );
  }

  final HtSourcesRepository _sourcesRepository;

  /// Number of sources to fetch per page.
  static const _sourcesLimit = 20;

  /// Handles the initial request to fetch sources.
  Future<void> _onSourcesFilterRequested(
    SourcesFilterRequested event,
    Emitter<SourcesFilterState> emit,
  ) async {
    // Prevent fetching if already loading or successful
    if (state.status == SourcesFilterStatus.loading ||
        state.status == SourcesFilterStatus.success) {
      return;
    }

    emit(state.copyWith(status: SourcesFilterStatus.loading));

    try {
      final response = await _sourcesRepository.getSources(
        limit: _sourcesLimit,
      );
      emit(
        state.copyWith(
          status: SourcesFilterStatus.success,
          sources: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          clearError: true, // Clear any previous error
        ),
      );
    } on SourceFetchFailure catch (e) {
      emit(
        state.copyWith(
          status: SourcesFilterStatus.failure,
          error: e,
        ),
      );
    } catch (e) {
      // Catch unexpected errors
      emit(
        state.copyWith(
          status: SourcesFilterStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Handles the request to load more sources for pagination.
  Future<void> _onSourcesFilterLoadMoreRequested(
    SourcesFilterLoadMoreRequested event,
    Emitter<SourcesFilterState> emit,
  ) async {
    // Only proceed if currently successful and has more items
    if (state.status != SourcesFilterStatus.success || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: SourcesFilterStatus.loadingMore));

    try {
      final response = await _sourcesRepository.getSources(
        limit: _sourcesLimit,
        startAfterId: state.cursor, // Use the cursor from the current state
      );
      emit(
        state.copyWith(
          status: SourcesFilterStatus.success,
          // Append new sources to the existing list
          sources: List.of(state.sources)..addAll(response.items),
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } on SourceFetchFailure catch (e) {
      // Keep existing data but indicate failure
      emit(
        state.copyWith(
          status: SourcesFilterStatus.failure,
          error: e,
        ),
      );
    } catch (e) {
      // Catch unexpected errors
      emit(
        state.copyWith(
          status: SourcesFilterStatus.failure,
          error: e,
        ),
      );
    }
  }
}
