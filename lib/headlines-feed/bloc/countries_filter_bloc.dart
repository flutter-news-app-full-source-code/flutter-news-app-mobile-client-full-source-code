import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart'; // Import AppBloc

part 'countries_filter_event.dart';
part 'countries_filter_state.dart';

/// {@template countries_filter_bloc}
/// Manages the state for fetching and displaying countries for filtering.
///
/// Handles initial fetching and pagination of countries using the
/// provided [DataRepository].
/// {@endtemplate}
class CountriesFilterBloc
    extends Bloc<CountriesFilterEvent, CountriesFilterState> {
  /// {@macro countries_filter_bloc}
  ///
  /// Requires a [DataRepository<Country>] to interact with the data layer.
  CountriesFilterBloc({
    required DataRepository<Country> countriesRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository, // Inject UserContentPreferencesRepository
    required AppBloc appBloc, // Inject AppBloc
  }) : _countriesRepository = countriesRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _appBloc = appBloc,
       super(const CountriesFilterState()) {
    on<CountriesFilterRequested>(
      _onCountriesFilterRequested,
      transformer: restartable(),
    );
    on<CountriesFilterApplyFollowedRequested>(
      _onCountriesFilterApplyFollowedRequested,
      transformer: restartable(),
    ); // Register new event handler
  }

  final DataRepository<Country> _countriesRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final AppBloc _appBloc;

  /// Handles the request to fetch countries based on a specific usage.
  ///
  /// This method fetches a non-paginated list of countries, filtered by
  /// the provided [usage] (e.g., 'eventCountry', 'headquarters').
  Future<void> _onCountriesFilterRequested(
    CountriesFilterRequested event,
    Emitter<CountriesFilterState> emit,
  ) async {
    // If already loading or successfully loaded, do not re-fetch unless explicitly
    // designed for a refresh mechanism (which is not the case for this usage-based fetch).
    if (state.status == CountriesFilterStatus.loading ||
        state.status == CountriesFilterStatus.success) {
      return;
    }

    emit(state.copyWith(status: CountriesFilterStatus.loading));

    try {
      // Build the filter map based on the provided usage.
      final filter = event.usage != null
          ? <String, dynamic>{'usage': event.usage}
          : null;

      // Fetch countries. The API for 'usage' filters is not paginated,
      // so we expect a complete list.
      final response = await _countriesRepository.readAll(
        filter: filter,
        sort: [const SortOption('name', SortOrder.asc)],
      );

      emit(
        state.copyWith(
          status: CountriesFilterStatus.success,
          countries: response.items,
          hasMore: false, // Always false for usage-based filters
          cursor: null, // Always null for usage-based filters
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: CountriesFilterStatus.failure, error: e));
    }
  }

  /// Handles the request to apply the user's followed countries as filters.
  Future<void> _onCountriesFilterApplyFollowedRequested(
    CountriesFilterApplyFollowedRequested event,
    Emitter<CountriesFilterState> emit,
  ) async {
    emit(
      state.copyWith(followedCountriesStatus: CountriesFilterStatus.loading),
    );

    final currentUser = _appBloc.state.user;

    if (currentUser == null) {
      emit(
        state.copyWith(
          followedCountriesStatus: CountriesFilterStatus.failure,
          error: const UnauthorizedException(
            'User must be logged in to apply followed countries.',
          ),
        ),
      );
      return;
    }

    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: currentUser.id,
        userId: currentUser.id,
      );

      if (preferences.followedCountries.isEmpty) {
        emit(
          state.copyWith(
            followedCountriesStatus: CountriesFilterStatus.success,
            followedCountries: const [],
            error: const OperationFailedException(
              'No followed countries found.',
            ),
            clearFollowedCountriesError: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          followedCountriesStatus: CountriesFilterStatus.success,
          followedCountries: preferences.followedCountries,
          clearFollowedCountriesError: true,
        ),
      );
    } on HttpException catch (e) {
      emit(
        state.copyWith(
          followedCountriesStatus: CountriesFilterStatus.failure,
          error: e,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          followedCountriesStatus: CountriesFilterStatus.failure,
          error: UnknownException(e.toString()),
        ),
      );
    }
  }
}
