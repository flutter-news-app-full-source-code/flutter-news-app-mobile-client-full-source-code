import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart' show Country, HtHttpException;

part 'available_countries_event.dart';
part 'available_countries_state.dart';

class AvailableCountriesBloc
    extends Bloc<AvailableCountriesEvent, AvailableCountriesState> {
  AvailableCountriesBloc({
    required HtDataRepository<Country> countriesRepository,
  })  : _countriesRepository = countriesRepository,
        super(const AvailableCountriesState()) {
    on<FetchAvailableCountries>(_onFetchAvailableCountries);
  }

  final HtDataRepository<Country> _countriesRepository;

  Future<void> _onFetchAvailableCountries(
    FetchAvailableCountries event,
    Emitter<AvailableCountriesState> emit,
  ) async {
    if (state.status == AvailableCountriesStatus.loading ||
        state.status == AvailableCountriesStatus.success) {
      return;
    }
    emit(state.copyWith(status: AvailableCountriesStatus.loading));
    try {
      final response = await _countriesRepository.readAll();
      emit(
        state.copyWith(
          status: AvailableCountriesStatus.success,
          availableCountries: response.items,
          clearError: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          status: AvailableCountriesStatus.failure,
          error: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AvailableCountriesStatus.failure,
          error: 'An unexpected error occurred while fetching countries.',
        ),
      );
    }
  }
}
