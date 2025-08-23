import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart'; // Import AppBloc

part 'sources_filter_event.dart';
part 'sources_filter_state.dart';

class SourcesFilterBloc extends Bloc<SourcesFilterEvent, SourcesFilterState> {
  SourcesFilterBloc({
    required DataRepository<Source> sourcesRepository,
    required DataRepository<Country> countriesRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required AppBloc appBloc,
  }) : _sourcesRepository = sourcesRepository,
       _countriesRepository = countriesRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _appBloc = appBloc,
       super(const SourcesFilterState()) {
    on<LoadSourceFilterData>(_onLoadSourceFilterData);
    on<CountryCapsuleToggled>(_onCountryCapsuleToggled);
    on<AllSourceTypesCapsuleToggled>(_onAllSourceTypesCapsuleToggled);
    on<SourceTypeCapsuleToggled>(_onSourceTypeCapsuleToggled);
    on<SourceCheckboxToggled>(_onSourceCheckboxToggled);
    on<SourcesFilterApplyFollowedRequested>(
      _onSourcesFilterApplyFollowedRequested,
    );
  }

  final DataRepository<Source> _sourcesRepository;
  final DataRepository<Country> _countriesRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final AppBloc _appBloc;

  Future<void> _onLoadSourceFilterData(
    LoadSourceFilterData event,
    Emitter<SourcesFilterState> emit,
  ) async {
    emit(
      state.copyWith(dataLoadingStatus: SourceFilterDataLoadingStatus.loading),
    );
    try {
      final countriesWithActiveSources = (await _countriesRepository.readAll(
        filter: {'hasActiveSources': 'true'},
      )).items;
      final initialSelectedSourceIds = event.initialSelectedSources
          .map((s) => s.id)
          .toSet();

      // The initial country and source type capsule selections are ephemeral
      // to the UI of the SourceFilterPage and are not passed via the event.
      // They are initialized as empty sets here, meaning the filter starts
      // with all countries and source types selected by default in the UI.
      final initialSelectedCountryIsoCodes = <String>{};
      final initialSelectedSourceTypes = <SourceType>{};

      final allAvailableSources = (await _sourcesRepository.readAll()).items;

      // Initially, display all sources. Capsules are visually set but don't filter the list yet.
      // Filtering will occur if a capsule is manually toggled.
      final displayableSources = _getFilteredSources(
        allSources: allAvailableSources,
        selectedCountries: initialSelectedCountryIsoCodes,
        selectedTypes: initialSelectedSourceTypes,
      );

      emit(
        state.copyWith(
          countriesWithActiveSources: countriesWithActiveSources,
          allAvailableSources: allAvailableSources,
          displayableSources: displayableSources,
          finallySelectedSourceIds: initialSelectedSourceIds,
          selectedCountryIsoCodes: initialSelectedCountryIsoCodes,
          selectedSourceTypes: initialSelectedSourceTypes,
          dataLoadingStatus: SourceFilterDataLoadingStatus.success,
          clearErrorMessage: true,
        ),
      );
    } on HttpException catch (e) {
      emit(
        state.copyWith(
          dataLoadingStatus: SourceFilterDataLoadingStatus.failure,
          error: e,
        ),
      );
    }
  }

  Future<void> _onCountryCapsuleToggled(
    CountryCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) async {
    final currentSelected = Set<String>.from(state.selectedCountryIsoCodes);
    if (event.countryIsoCode.isEmpty) {
      // "All Countries" toggled
      // If "All" is tapped and it's already effectively "All" (empty set), or if it's tapped to select "All"
      // we clear the set. If specific items are selected and "All" is tapped, it also clears.
      // Essentially, tapping "All" always results in an empty set, meaning no country filter.
      currentSelected.clear();
    } else {
      // Specific country toggled
      if (currentSelected.contains(event.countryIsoCode)) {
        currentSelected.remove(event.countryIsoCode);
      } else {
        currentSelected.add(event.countryIsoCode);
      }
    }
    final newDisplayableSources = _getFilteredSources(
      allSources: state.allAvailableSources,
      selectedCountries: currentSelected,
      selectedTypes: state.selectedSourceTypes,
    );
    emit(
      state.copyWith(
        selectedCountryIsoCodes: currentSelected,
        displayableSources: newDisplayableSources,
      ),
    );
  }

  void _onAllSourceTypesCapsuleToggled(
    AllSourceTypesCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) {
    final newDisplayableSources = _getFilteredSources(
      allSources: state.allAvailableSources,
      selectedCountries: state.selectedCountryIsoCodes,
      selectedTypes: {},
    );
    emit(
      state.copyWith(
        selectedSourceTypes: {},
        displayableSources: newDisplayableSources,
      ),
    );
  }

  void _onSourceTypeCapsuleToggled(
    SourceTypeCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) {
    final currentSelected = Set<SourceType>.from(state.selectedSourceTypes);
    if (currentSelected.contains(event.sourceType)) {
      currentSelected.remove(event.sourceType);
    } else {
      currentSelected.add(event.sourceType);
    }
    final newDisplayableSources = _getFilteredSources(
      allSources: state.allAvailableSources,
      selectedCountries: state.selectedCountryIsoCodes,
      selectedTypes: currentSelected,
    );
    emit(
      state.copyWith(
        selectedSourceTypes: currentSelected,
        displayableSources: newDisplayableSources,
      ),
    );
  }

  void _onSourceCheckboxToggled(
    SourceCheckboxToggled event,
    Emitter<SourcesFilterState> emit,
  ) {
    final currentSelected = Set<String>.from(state.finallySelectedSourceIds);
    if (event.isSelected) {
      currentSelected.add(event.sourceId);
    } else {
      currentSelected.remove(event.sourceId);
    }
    emit(state.copyWith(finallySelectedSourceIds: currentSelected));
  }

  /// Handles the request to apply the user's followed sources as filters.
  Future<void> _onSourcesFilterApplyFollowedRequested(
    SourcesFilterApplyFollowedRequested event,
    Emitter<SourcesFilterState> emit,
  ) async {
    emit(
      state.copyWith(
        followedSourcesStatus: SourceFilterDataLoadingStatus.loading,
      ),
    );

    final currentUser = _appBloc.state.user!;

    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: currentUser.id,
        userId: currentUser.id,
      );

      if (preferences.followedSources.isEmpty) {
        emit(
          state.copyWith(
            followedSourcesStatus: SourceFilterDataLoadingStatus.success,
            followedSources: const [],
            clearErrorMessage: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          followedSourcesStatus: SourceFilterDataLoadingStatus.success,
          followedSources: preferences.followedSources,
          finallySelectedSourceIds: preferences.followedSources
              .map((s) => s.id)
              .toSet(),
          clearFollowedSourcesError: true,
        ),
      );
    } on HttpException catch (e) {
      emit(
        state.copyWith(
          followedSourcesStatus: SourceFilterDataLoadingStatus.failure,
          error: e,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          followedSourcesStatus: SourceFilterDataLoadingStatus.failure,
          error: UnknownException(e.toString()),
        ),
      );
    }
  }

  // Helper method to filter sources based on selected countries and types
  List<Source> _getFilteredSources({
    required List<Source> allSources,
    required Set<String> selectedCountries,
    required Set<SourceType> selectedTypes,
  }) {
    if (selectedCountries.isEmpty && selectedTypes.isEmpty) {
      return List.from(allSources);
    }

    return allSources.where((source) {
      final matchesCountry =
          selectedCountries.isEmpty ||
          (selectedCountries.contains(source.headquarters.isoCode));
      final matchesType =
          selectedTypes.isEmpty || (selectedTypes.contains(source.sourceType));
      return matchesCountry && matchesType;
    }).toList();
  }
}
