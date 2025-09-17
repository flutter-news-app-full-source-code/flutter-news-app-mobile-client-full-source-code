part of 'countries_filter_bloc.dart';

/// Enum representing the different statuses of the country filter data fetching.
enum CountriesFilterStatus {
  /// Initial state, no data loaded yet.
  initial,

  /// Currently fetching the first page of countries.
  loading,

  /// Successfully loaded countries. May be loading more in the background.
  success,

  /// An error occurred while fetching countries.
  failure,

  /// Loading more countries for pagination (infinity scroll).
  loadingMore,
}

/// {@template countries_filter_state}
/// Represents the state for the country filter feature.
///
/// Contains the list of fetched countries, pagination information,
/// loading/error status.
/// {@endtemplate}
final class CountriesFilterState extends Equatable {
  /// {@macro countries_filter_state}
  const CountriesFilterState({
    this.status = CountriesFilterStatus.initial,
    this.countries = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  /// The current status of fetching countries.
  final CountriesFilterStatus status;

  /// The list of [Country] objects fetched so far.
  final List<Country> countries;

  /// Flag indicating if there are more countries available to fetch.
  final bool hasMore;

  /// The cursor string to fetch the next page of countries.
  /// This is typically the ID of the last fetched country.
  final String? cursor;

  /// An optional error object if the status is [CountriesFilterStatus.failure].
  final HttpException? error;

  /// Creates a copy of this state with the given fields replaced.
  CountriesFilterState copyWith({
    CountriesFilterStatus? status,
    List<Country>? countries,
    bool? hasMore,
    String? cursor,
    HttpException? error,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return CountriesFilterState(
      status: status ?? this.status,
      countries: countries ?? this.countries,
      hasMore: hasMore ?? this.hasMore,
      // Allow explicitly setting cursor to null or clearing it
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      // Clear error if requested, otherwise keep existing or use new one
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    countries,
    hasMore,
    cursor,
    error,
  ];
}
