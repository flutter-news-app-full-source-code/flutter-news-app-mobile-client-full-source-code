part of 'headlines_filter_bloc.dart';

/// Enum representing the different statuses of the filter data fetching.
enum HeadlinesFilterStatus {
  /// Initial state, no data loaded yet.
  initial,

  /// Currently loading all filter data (topics, sources, countries).
  loading,

  /// Successfully loaded all filter data.
  success,

  /// An error occurred while fetching filter data.
  failure,
}

/// {@template headlines_filter_state}
/// Represents the state for the centralized headlines filter feature.
///
/// This state holds all available filter options (topics, sources, countries)
/// and the user's current temporary selections, along with loading/error status.
/// {@endtemplate}
final class HeadlinesFilterState extends Equatable {
  /// {@macro headlines_filter_state}
  const HeadlinesFilterState({
    this.status = HeadlinesFilterStatus.initial,
    this.allTopics = const [],
    this.allSources = const [],
    this.allCountries = const [],
    this.selectedTopics = const {},
    this.selectedSources = const {},
    this.selectedCountries = const {},
    this.selectedSourceHeadquarterCountries = const {},
    this.selectedSourceTypes = const {},
    this.error,
  });

  /// The current status of fetching filter data.
  final HeadlinesFilterStatus status;

  /// All available [Topic] objects that can be used for filtering.
  final List<Topic> allTopics;

  /// All available [Source] objects that can be used for filtering.
  final List<Source> allSources;

  /// All available [Country] objects that can be used for filtering.
  final List<Country> allCountries;

  /// The set of [Topic] objects currently selected by the user.
  final Set<Topic> selectedTopics;

  /// The set of [Source] objects currently selected by the user.
  final Set<Source> selectedSources;

  /// The set of [Country] objects currently selected by the user.
  final Set<Country> selectedCountries;

  /// The set of [Country] objects selected for filtering the source list
  /// by headquarters.
  final Set<Country> selectedSourceHeadquarterCountries;

  /// The set of [SourceType] objects selected for filtering the source list
  /// by type.
  final Set<SourceType> selectedSourceTypes;

  /// An optional error object if the status is [HeadlinesFilterStatus.failure].
  final HttpException? error;

  /// Creates a copy of this state with the given fields replaced.
  HeadlinesFilterState copyWith({
    HeadlinesFilterStatus? status,
    List<Topic>? allTopics,
    List<Source>? allSources,
    List<Country>? allCountries,
    Set<Topic>? selectedTopics,
    Set<Source>? selectedSources,
    Set<Country>? selectedCountries,
    Set<Country>? selectedSourceHeadquarterCountries,
    Set<SourceType>? selectedSourceTypes,
    HttpException? error,
    bool clearError = false,
  }) {
    return HeadlinesFilterState(
      status: status ?? this.status,
      allTopics: allTopics ?? this.allTopics,
      allSources: allSources ?? this.allSources,
      allCountries: allCountries ?? this.allCountries,
      selectedTopics: selectedTopics ?? this.selectedTopics,
      selectedSources: selectedSources ?? this.selectedSources,
      selectedCountries: selectedCountries ?? this.selectedCountries,
      selectedSourceHeadquarterCountries:
          selectedSourceHeadquarterCountries ??
          this.selectedSourceHeadquarterCountries,
      selectedSourceTypes: selectedSourceTypes ?? this.selectedSourceTypes,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allTopics,
    allSources,
    allCountries,
    selectedTopics,
    selectedSources,
    selectedCountries,
    selectedSourceHeadquarterCountries,
    selectedSourceTypes,
    error,
  ];
}
