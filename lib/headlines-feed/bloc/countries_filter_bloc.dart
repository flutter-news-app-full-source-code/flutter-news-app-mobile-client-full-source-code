import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart'; // For transformers
import 'package:equatable/equatable.dart';
import 'package:ht_countries_client/ht_countries_client.dart'; // For Country model and exceptions
import 'package:ht_countries_repository/ht_countries_repository.dart';
// For PaginatedResponse

part 'countries_filter_event.dart';
part 'countries_filter_state.dart';

/// {@template countries_filter_bloc}
/// Manages the state for fetching and displaying countries for filtering.
///
/// Handles initial fetching and pagination of countries using the
/// provided [HtCountriesRepository].
/// {@endtemplate}
class CountriesFilterBloc
    extends Bloc<CountriesFilterEvent, CountriesFilterState> {
  /// {@macro countries_filter_bloc}
  ///
  /// Requires a [HtCountriesRepository] to interact with the data layer.
  CountriesFilterBloc({required HtCountriesRepository countriesRepository})
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

  final HtCountriesRepository _countriesRepository;

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
      // Note: Repository uses 'cursor' parameter name here
      final response = await _countriesRepository.fetchCountries(
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
    } on CountryFetchFailure catch (e) {
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
      // Note: Repository uses 'cursor' parameter name here
      final response = await _countriesRepository.fetchCountries(
        limit: _countriesLimit,
        cursor: state.cursor, // Use the cursor from the current state
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
    } on CountryFetchFailure catch (e) {
      // Keep existing data but indicate failure
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    } catch (e) {
      // Catch unexpected errors
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    }
  }
}
