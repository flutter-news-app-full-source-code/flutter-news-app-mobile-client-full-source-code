import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart'
    show Country, HtHttpException, Source, SourceType;

part 'sources_filter_event.dart';
part 'sources_filter_state.dart';

class SourcesFilterBloc extends Bloc<SourcesFilterEvent, SourcesFilterState> {
  SourcesFilterBloc({
    required HtDataRepository<Source> sourcesRepository,
    required HtDataRepository<Country> countriesRepository,
  }) : _sourcesRepository = sourcesRepository,
       _countriesRepository = countriesRepository,
       super(const SourcesFilterState()) {
    on<LoadSourceFilterData>(_onLoadSourceFilterData);
    on<CountryCapsuleToggled>(_onCountryCapsuleToggled);
    on<AllSourceTypesCapsuleToggled>(_onAllSourceTypesCapsuleToggled); // Added
    on<SourceTypeCapsuleToggled>(_onSourceTypeCapsuleToggled);
    on<SourceCheckboxToggled>(_onSourceCheckboxToggled);
    on<ClearSourceFiltersRequested>(_onClearSourceFiltersRequested);
    on<_FetchFilteredSourcesRequested>(_onFetchFilteredSourcesRequested);
  }

  final HtDataRepository<Source> _sourcesRepository;
  final HtDataRepository<Country> _countriesRepository;

  Future<void> _onLoadSourceFilterData(
    LoadSourceFilterData event,
    Emitter<SourcesFilterState> emit,
  ) async {
    emit(
      state.copyWith(dataLoadingStatus: SourceFilterDataLoadingStatus.loading),
    );
    try {
      final availableCountries = await _countriesRepository.readAll();
      final initialSelectedSourceIds =
          event.initialSelectedSources.map((s) => s.id).toSet();

      // Initialize selected capsules based on initialSelectedSources
      final initialSelectedCountryIsoCodes = <String>{};
      final initialSelectedSourceTypes = <SourceType>{};

      if (event.initialSelectedSources.isNotEmpty) {
        for (final source in event.initialSelectedSources) {
          if (source.headquarters?.isoCode != null) {
            initialSelectedCountryIsoCodes.add(source.headquarters!.isoCode);
          }
          if (source.sourceType != null) {
            initialSelectedSourceTypes.add(source.sourceType!);
          }
        }
      }

      emit(
        state.copyWith(
          availableCountries: availableCountries.items,
          finallySelectedSourceIds: initialSelectedSourceIds,
          selectedCountryIsoCodes: initialSelectedCountryIsoCodes,
          selectedSourceTypes: initialSelectedSourceTypes,
          // Keep loading status until sources are fetched
        ),
      );
      // Trigger initial fetch of displayable sources
      add(const _FetchFilteredSourcesRequested());
    } catch (e) {
      emit(
        state.copyWith(
          dataLoadingStatus: SourceFilterDataLoadingStatus.failure,
          errorMessage: 'Failed to load filter criteria.',
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
    emit(state.copyWith(selectedCountryIsoCodes: currentSelected));
    add(const _FetchFilteredSourcesRequested());
  }

  Future<void> _onAllSourceTypesCapsuleToggled(
    AllSourceTypesCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) async {
    // Toggling "All" for source types means clearing any specific selections.
    // If already clear, it remains clear.
    emit(state.copyWith(selectedSourceTypes: {}));
    add(const _FetchFilteredSourcesRequested());
  }

  Future<void> _onSourceTypeCapsuleToggled(
    SourceTypeCapsuleToggled event,
    Emitter<SourcesFilterState> emit,
  ) async {
    final currentSelected = Set<SourceType>.from(state.selectedSourceTypes);
    if (currentSelected.contains(event.sourceType)) {
      currentSelected.remove(event.sourceType);
    } else {
      currentSelected.add(event.sourceType);
    }
    // If specific types are selected, "All" is no longer true.
    // The UI will derive "All" state from selectedSourceTypes.isEmpty
    emit(state.copyWith(selectedSourceTypes: currentSelected));
    add(const _FetchFilteredSourcesRequested());
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

  Future<void> _onClearSourceFiltersRequested(
    ClearSourceFiltersRequested event,
    Emitter<SourcesFilterState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCountryIsoCodes: {},
        selectedSourceTypes: {},
        finallySelectedSourceIds: {},
        // Keep availableCountries and availableSourceTypes
      ),
    );
    add(const _FetchFilteredSourcesRequested());
  }

  Future<void> _onFetchFilteredSourcesRequested(
    _FetchFilteredSourcesRequested event,
    Emitter<SourcesFilterState> emit,
  ) async {
    emit(
      state.copyWith(
        dataLoadingStatus: SourceFilterDataLoadingStatus.loading,
        displayableSources: [], // Clear previous sources
        clearErrorMessage: true,
      ),
    );
    try {
      final queryParameters = <String, dynamic>{};
      if (state.selectedCountryIsoCodes.isNotEmpty) {
        queryParameters['countries'] = state.selectedCountryIsoCodes.join(',');
      }
      if (state.selectedSourceTypes.isNotEmpty) {
        queryParameters['sourceTypes'] = state.selectedSourceTypes
            .map((st) => st.name)
            .join(',');
      }

      final response = await _sourcesRepository.readAllByQuery(queryParameters);
      emit(
        state.copyWith(
          displayableSources: response.items,
          dataLoadingStatus: SourceFilterDataLoadingStatus.success,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          dataLoadingStatus: SourceFilterDataLoadingStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          dataLoadingStatus: SourceFilterDataLoadingStatus.failure,
          errorMessage: 'An unexpected error occurred while fetching sources.',
        ),
      );
    }
  }
}
