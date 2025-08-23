import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';

part 'available_countries_event.dart';
part 'available_countries_state.dart';

class AvailableCountriesBloc
    extends Bloc<AvailableCountriesEvent, AvailableCountriesState> {
  AvailableCountriesBloc({required DataRepository<Country> countriesRepository})
    : _countriesRepository = countriesRepository,
      super(const AvailableCountriesState()) {
    on<FetchAvailableCountries>(_onFetchAvailableCountries);
  }

  final DataRepository<Country> _countriesRepository;

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
      final response = await _countriesRepository.readAll(
        sort: [const SortOption('name', SortOrder.asc)],
      );
      emit(
        state.copyWith(
          status: AvailableCountriesStatus.success,
          availableCountries: response.items,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
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
