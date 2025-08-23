part of 'sources_filter_bloc.dart';

// Import for Country, Source, SourceType will be in sources_filter_bloc.dart

enum SourceFilterDataLoadingStatus { initial, loading, success, failure }

class SourcesFilterState extends Equatable {
  const SourcesFilterState({
    this.countriesWithActiveSources = const [],
    this.selectedCountryIsoCodes = const {},
    this.availableSourceTypes = SourceType.values,
    this.selectedSourceTypes = const {},
    this.allAvailableSources = const [],
    this.displayableSources = const [],
    this.finallySelectedSourceIds = const {},
    this.dataLoadingStatus = SourceFilterDataLoadingStatus.initial,
    this.error,
    this.followedSourcesStatus = SourceFilterDataLoadingStatus.initial,
    this.followedSources = const [],
  });

  final List<Country> countriesWithActiveSources;
  final Set<String> selectedCountryIsoCodes;
  final List<SourceType> availableSourceTypes;
  final Set<SourceType> selectedSourceTypes;
  final List<Source> allAvailableSources;
  final List<Source> displayableSources;
  final Set<String> finallySelectedSourceIds;
  final SourceFilterDataLoadingStatus dataLoadingStatus;
  final HttpException? error;

  /// The current status of fetching followed sources.
  final SourceFilterDataLoadingStatus followedSourcesStatus;

  /// The list of [Source] objects representing the user's followed sources.
  final List<Source> followedSources;

  SourcesFilterState copyWith({
    List<Country>? countriesWithActiveSources,
    Set<String>? selectedCountryIsoCodes,
    List<SourceType>? availableSourceTypes,
    Set<SourceType>? selectedSourceTypes,
    List<Source>? allAvailableSources,
    List<Source>? displayableSources,
    Set<String>? finallySelectedSourceIds,
    SourceFilterDataLoadingStatus? dataLoadingStatus,
    HttpException? error,
    SourceFilterDataLoadingStatus? followedSourcesStatus,
    List<Source>? followedSources,
    bool clearErrorMessage = false,
    bool clearFollowedSourcesError = false,
  }) {
    return SourcesFilterState(
      countriesWithActiveSources:
          countriesWithActiveSources ?? this.countriesWithActiveSources,
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
      followedSourcesStatus:
          followedSourcesStatus ?? this.followedSourcesStatus,
      followedSources: followedSources ?? this.followedSources,
    );
  }

  @override
  List<Object?> get props => [
    countriesWithActiveSources,
    selectedCountryIsoCodes,
    availableSourceTypes,
    selectedSourceTypes,
    allAvailableSources,
    displayableSources,
    finallySelectedSourceIds,
    dataLoadingStatus,
    error,
    followedSourcesStatus,
    followedSources,
  ];
}
