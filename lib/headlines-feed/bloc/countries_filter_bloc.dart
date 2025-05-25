import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart'; // For transformers
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_shared/ht_shared.dart'
    show
        Country,
        HtHttpException; // Shared models, including Country and standardized exceptions

part 'countries_filter_event.dart';
part 'countries_filter_state.dart';

/// {@template countries_filter_bloc}
/// Manages the state for fetching and displaying countries for filtering.
///
/// Handles initial fetching and pagination of countries using the
/// provided [HtDataRepository].
/// {@endtemplate}
class CountriesFilterBloc
    extends Bloc<CountriesFilterEvent, CountriesFilterState> {
  /// {@macro countries_filter_bloc}
  ///
  /// Requires a [HtDataRepository<Country>] to interact with the data layer.
  CountriesFilterBloc({required HtDataRepository<Country> countriesRepository})
    : _countriesRepository = countriesRepository,
      super(const CountriesFilterState()) {
    on<CountriesFilterRequested>(
      _onCountriesFilterRequested,
      transformer: restartable(), // Only process the latest request
    );
    on<CountriesFilterLoadMoreRequested>(
      _onCountriesFilterLoadMoreRequested,
      transformer: droppable(), // Ignore new requests while one is processing
    );
  }

  final HtDataRepository<Country> _countriesRepository;

  /// Number of countries to fetch per page.
  static const _countriesLimit = 20;

  /// Handles the initial request to fetch countries.
  Future<void> _onCountriesFilterRequested(
    CountriesFilterRequested event,
    Emitter<CountriesFilterState> emit,
  ) async {
    // Prevent fetching if already loading or successful
    if (state.status == CountriesFilterStatus.loading ||
        state.status == CountriesFilterStatus.success) {
      return;
    }

    emit(state.copyWith(status: CountriesFilterStatus.loading));

    try {
      final response = await _countriesRepository.readAll(
        limit: _countriesLimit,
      );
      emit(
        state.copyWith(
          status: CountriesFilterStatus.success,
          countries: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          clearError: true, // Clear any previous error
        ),
      );
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    } catch (e) {
      // Catch unexpected errors
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    }
  }

  /// Handles the request to load more countries for pagination.
  Future<void> _onCountriesFilterLoadMoreRequested(
    CountriesFilterLoadMoreRequested event,
    Emitter<CountriesFilterState> emit,
  ) async {
    // Only proceed if currently successful and has more items
    if (state.status != CountriesFilterStatus.success || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: CountriesFilterStatus.loadingMore));

    try {
      final response = await _countriesRepository.readAll(
        limit: _countriesLimit,
        startAfterId: state.cursor, // Use the cursor from the current state
      );
      emit(
        state.copyWith(
          status: CountriesFilterStatus.success,
          // Append new countries to the existing list
          countries: List.of(state.countries)..addAll(response.items),
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } on HtHttpException catch (e) {
      // Keep existing data but indicate failure
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    } catch (e) {
      // Catch unexpected errors
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    }
  }
}
