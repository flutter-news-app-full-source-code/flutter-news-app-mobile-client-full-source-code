part of 'countries_filter_bloc.dart';

/// {@template countries_filter_event}
/// Base class for events related to fetching and managing country filters.
/// {@endtemplate}
sealed class CountriesFilterEvent extends Equatable {
  /// {@macro countries_filter_event}
  const CountriesFilterEvent();

  @override
  List<Object> get props => [];
}

/// {@template countries_filter_requested}
/// Event triggered to request the initial list of countries.
/// {@endtemplate}
final class CountriesFilterRequested extends CountriesFilterEvent {}

/// {@template countries_filter_load_more_requested}
/// Event triggered to request the next page of countries for pagination.
/// {@endtemplate}
final class CountriesFilterLoadMoreRequested extends CountriesFilterEvent {}
