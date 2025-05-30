part of 'sources_filter_bloc.dart';

// Import for Country, Source, SourceType will be in sources_filter_bloc.dart

enum SourceFilterDataLoadingStatus { initial, loading, success, failure }

class SourcesFilterState extends Equatable {
  const SourcesFilterState({
    this.availableCountries = const [],
    this.selectedCountryIsoCodes = const {},
    this.availableSourceTypes = SourceType.values,
    this.selectedSourceTypes = const {},
    this.allAvailableSources = const [], // Added new property
    this.displayableSources = const [],
    this.finallySelectedSourceIds = const {},
    this.dataLoadingStatus = SourceFilterDataLoadingStatus.initial,
    this.errorMessage,
  });

  final List<Country> availableCountries;
  final Set<String> selectedCountryIsoCodes;
  final List<SourceType> availableSourceTypes;
  final Set<SourceType> selectedSourceTypes;
  final List<Source> allAvailableSources; // Added new property
  final List<Source> displayableSources;
  final Set<String> finallySelectedSourceIds;
  final SourceFilterDataLoadingStatus dataLoadingStatus;
  final String? errorMessage;

  SourcesFilterState copyWith({
    List<Country>? availableCountries,
    Set<String>? selectedCountryIsoCodes,
    List<SourceType>? availableSourceTypes,
    Set<SourceType>? selectedSourceTypes,
    List<Source>? allAvailableSources, // Added new property
    List<Source>? displayableSources,
    Set<String>? finallySelectedSourceIds,
    SourceFilterDataLoadingStatus? dataLoadingStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SourcesFilterState(
      availableCountries: availableCountries ?? this.availableCountries,
      selectedCountryIsoCodes:
          selectedCountryIsoCodes ?? this.selectedCountryIsoCodes,
      availableSourceTypes: availableSourceTypes ?? this.availableSourceTypes,
      selectedSourceTypes: selectedSourceTypes ?? this.selectedSourceTypes,
      allAvailableSources:
          allAvailableSources ?? this.allAvailableSources, // Added
      displayableSources: displayableSources ?? this.displayableSources,
      finallySelectedSourceIds:
          finallySelectedSourceIds ?? this.finallySelectedSourceIds,
      dataLoadingStatus: dataLoadingStatus ?? this.dataLoadingStatus,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    availableCountries,
    selectedCountryIsoCodes,
    availableSourceTypes,
    selectedSourceTypes,
    allAvailableSources, // Added new property
    displayableSources,
    finallySelectedSourceIds,
    dataLoadingStatus,
    errorMessage,
  ];
}
