part of 'source_list_bloc.dart';

/// The status of the [SourceListBloc].
enum SourceListStatus {
  /// The initial state.
  initial,

  /// The state when loading the initial list of sources.
  loading,

  /// The state when loading more sources for pagination.
  loadingMore,

  /// The state when data has been successfully loaded.
  success,

  /// The state when a general failure has occurred.
  failure,

  /// The state when loading more sources fails, but the existing list is kept.
  partialFailure,

  /// The state when loading more countries for pagination.
  loadingMoreCountries,

  /// The state when loading more countries fails, but the existing list is kept.
  partialCountriesFailure,
}

/// {@template source_list_state}
/// The state for the list of sources of a specific type.
///
/// Manages pagination, filtering, and follow/unfollow actions.
/// {@endtemplate}
final class SourceListState extends Equatable {
  /// {@macro source_list_state}
  const SourceListState({
    this.status = SourceListStatus.initial,
    this.sourceType,
    this.sources = const [],
    this.nextCursor,
    this.countries = const [],
    this.countriesNextCursor,
    this.selectedCountries = const {},
    this.error,
  });

  /// The current status of the source list.
  final SourceListStatus status;

  /// The type of source being displayed.
  final SourceType? sourceType;

  /// The current list of loaded sources.
  final List<Source> sources;

  /// The cursor for fetching the next page of sources.
  final String? nextCursor;

  /// A computed property indicating if there are more sources to load.
  bool get hasMore => nextCursor != null;

  /// The current list of loaded countries for the filter UI.
  final List<Country> countries;

  /// The cursor for fetching the next page of countries.
  final String? countriesNextCursor;

  /// A computed property indicating if there are more countries to load.
  bool get countriesHasMore => countriesNextCursor != null;

  /// The set of countries selected for filtering.
  final Set<Country> selectedCountries;

  /// The error that occurred, if any.
  final HttpException? error;

  /// Creates a copy of the current [SourceListState] with the given fields
  /// replaced with the new values.
  SourceListState copyWith({
    SourceListStatus? status,
    SourceType? sourceType,
    List<Source>? sources,
    String? nextCursor,
    List<Country>? countries,
    String? countriesNextCursor,
    bool clearCountriesCursor = false,
    Set<Country>? selectedCountries,
    HttpException? error,
    bool clearError = false,
  }) {
    return SourceListState(
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      sources: sources ?? this.sources,
      nextCursor: nextCursor,
      countries: countries ?? this.countries,
      countriesNextCursor: clearCountriesCursor
          ? null
          : countriesNextCursor ?? this.countriesNextCursor,
      selectedCountries: selectedCountries ?? this.selectedCountries,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sourceType,
    sources,
    nextCursor,
    countries,
    countriesNextCursor,
    selectedCountries,
    error,
  ];
}
