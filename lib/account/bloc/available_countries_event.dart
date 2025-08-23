part of 'available_countries_bloc.dart';

abstract class AvailableCountriesEvent extends Equatable {
  const AvailableCountriesEvent();

  @override
  List<Object> get props => [];
}

class FetchAvailableCountries extends AvailableCountriesEvent {
  const FetchAvailableCountries();
}
