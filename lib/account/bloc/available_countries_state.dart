part of 'available_countries_bloc.dart';

enum AvailableCountriesStatus { initial, loading, success, failure }

class AvailableCountriesState extends Equatable {
  const AvailableCountriesState({
    this.status = AvailableCountriesStatus.initial,
    this.availableCountries = const [],
    this.error,
  });

  final AvailableCountriesStatus status;
  final List<Country> availableCountries;
  final String? error;

  AvailableCountriesState copyWith({
    AvailableCountriesStatus? status,
    List<Country>? availableCountries,
    String? error,
    bool clearError = false,
  }) {
    return AvailableCountriesState(
      status: status ?? this.status,
      availableCountries: availableCountries ?? this.availableCountries,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    availableCountries,
    error,
  ];
}
