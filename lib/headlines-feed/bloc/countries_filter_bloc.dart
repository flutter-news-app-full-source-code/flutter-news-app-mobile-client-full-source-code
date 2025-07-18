import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart';

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
      transformer: restartable(),
    );
    on<CountriesFilterLoadMoreRequested>(
      _onCountriesFilterLoadMoreRequested,
      transformer: droppable(),
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
    if (state.status == CountriesFilterStatus.loading ||
        state.status == CountriesFilterStatus.success) {
      return;
    }

    emit(state.copyWith(status: CountriesFilterStatus.loading));

    try {
      final response = await _countriesRepository.readAll(
        pagination: const PaginationOptions(limit: _countriesLimit),
      );
      emit(
        state.copyWith(
          status: CountriesFilterStatus.success,
          countries: response.items,
          hasMore: response.cursor != null,
          cursor: response.cursor,
          clearError: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    }
  }

  /// Handles the request to load more countries for pagination.
  Future<void> _onCountriesFilterLoadMoreRequested(
    CountriesFilterLoadMoreRequested event,
    Emitter<CountriesFilterState> emit,
  ) async {
    if (state.status != CountriesFilterStatus.success || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: CountriesFilterStatus.loadingMore));

    try {
      final response = await _countriesRepository.readAll(
        pagination: PaginationOptions(
          limit: _countriesLimit,
          cursor: state.cursor,
        ),
      );
      emit(
        state.copyWith(
          status: CountriesFilterStatus.success,
          countries: List.of(state.countries)..addAll(response.items),
          hasMore: response.cursor != null,
          cursor: response.cursor,
        ),
      );
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    }
  }
}
