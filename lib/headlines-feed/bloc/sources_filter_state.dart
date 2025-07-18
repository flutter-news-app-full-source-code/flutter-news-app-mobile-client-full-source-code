part of 'sources_filter_bloc.dart';

// Import for Country, Source, SourceType will be in sources_filter_bloc.dart

enum SourceFilterDataLoadingStatus { initial, loading, success, failure }

class SourcesFilterState extends Equatable {
  const SourcesFilterState({
    this.availableCountries = const [],
    this.selectedCountryIsoCodes = const {},
    this.availableSourceTypes = SourceType.values,
    this.selectedSourceTypes = const {},
    this.allAvailableSources = const [],
    this.displayableSources = const [],
    this.finallySelectedSourceIds = const {},
    this.dataLoadingStatus = SourceFilterDataLoadingStatus.initial,
    this.error,
  });

  final List<Country> availableCountries;
  final Set<String> selectedCountryIsoCodes;
  final List<SourceType> availableSourceTypes;
  final Set<SourceType> selectedSourceTypes;
  final List<Source> allAvailableSources;
  final List<Source> displayableSources;
  final Set<String> finallySelectedSourceIds;
  final SourceFilterDataLoadingStatus dataLoadingStatus;
  final HtHttpException? error;

  SourcesFilterState copyWith({
    List<Country>? availableCountries,
    Set<String>? selectedCountryIsoCodes,
    List<SourceType>? availableSourceTypes,
    Set<SourceType>? selectedSourceTypes,
    List<Source>? allAvailableSources,
    List<Source>? displayableSources,
    Set<String>? finallySelectedSourceIds,
    SourceFilterDataLoadingStatus? dataLoadingStatus,
    HtHttpException? error,
    bool clearErrorMessage = false,
  }) {
    return SourcesFilterState(
      availableCountries: availableCountries ?? this.availableCountries,
      selectedCountryIsoCodes:
          selectedCountryIsoCodes ?? this.selectedCountryIsoCodes,
      availableSourceTypes: availableSourceTypes ?? this.availableSourceTypes,
      selectedSourceTypes: selectedSourceTypes ?? this.selectedSourceTypes,
      allAvailableSources: allAvailableSources ?? this.allAvailableSources,
      displayableSources: displayableSources ?? this.displayableSources,
      finallySelectedSourceIds:
          finallySelectedSourceIds ?? this.finallySelectedSourceIds,
      dataLoadingStatus: dataLoadingStatus ?? this.dataLoadingStatus,
      error: clearErrorMessage ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    availableCountries,
    selectedCountryIsoCodes,
    availableSourceTypes,
    selectedSourceTypes,
    allAvailableSources,
    displayableSources,
    finallySelectedSourceIds,
    dataLoadingStatus,
    error,
  ];
}
