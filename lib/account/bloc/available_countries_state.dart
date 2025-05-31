part of 'available_countries_bloc.dart';

enum AvailableCountriesStatus { initial, loading, success, failure }

class AvailableCountriesState extends Equatable {
  const AvailableCountriesState({
    this.status = AvailableCountriesStatus.initial,
    this.availableCountries = const [],
    this.error,
    // Properties for pagination if added later
    // this.hasMore = true,
    // this.cursor,
  });

  final AvailableCountriesStatus status;
  final List<Country> availableCountries;
  final String? error;
  // final bool hasMore;
  // final String? cursor;

  AvailableCountriesState copyWith({
    AvailableCountriesStatus? status,
    List<Country>? availableCountries,
    String? error,
    bool clearError = false,
    // bool? hasMore,
    // String? cursor,
    // bool clearCursor = false,
  }) {
    return AvailableCountriesState(
      status: status ?? this.status,
      availableCountries: availableCountries ?? this.availableCountries,
      error: clearError ? null : error ?? this.error,
      // hasMore: hasMore ?? this.hasMore,
      // cursor: clearCursor ? null : (cursor ?? this.cursor),
    );
  }

  @override
  List<Object?> get props => [
        status,
        availableCountries,
        error,
        // hasMore, // Add if pagination is implemented
        // cursor, // Add if pagination is implemented
      ];
}
