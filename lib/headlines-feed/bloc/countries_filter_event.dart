part of 'countries_filter_bloc.dart';

/// {@template countries_filter_event}
/// Base class for events related to fetching and managing country filters.
/// {@endtemplate}
sealed class CountriesFilterEvent extends Equatable {
  /// {@macro countries_filter_event}
  const CountriesFilterEvent();

  @override
  List<Object?> get props => [];
}

/// {@template countries_filter_requested}
/// Event triggered to request the initial list of countries.
/// {@endtemplate}
final class CountriesFilterRequested extends CountriesFilterEvent {
  /// {@macro countries_filter_requested}
  ///
  /// Optionally includes a [usage] context to filter countries by their
  /// relevance to headlines (e.g., 'eventCountry' or 'headquarters').
  const CountriesFilterRequested({this.usage});

  /// The usage context for filtering countries (e.g., 'eventCountry', 'headquarters').
  final String? usage;

  @override
  List<Object?> get props => [usage];
}
