part of 'source_list_bloc.dart';

/// Base class for all events related to the [SourceListBloc].
sealed class SourceListEvent extends Equatable {
  /// {@macro source_list_event}
  const SourceListEvent();

  @override
  List<Object?> get props => [];
}

/// {@template source_list_started}
/// Event added when the source list page is first opened.
///
/// This triggers the initial fetch of sources for a specific [sourceType].
/// {@endtemplate}
final class SourceListStarted extends SourceListEvent {
  /// {@macro source_list_started}
  const SourceListStarted({required this.sourceType});

  /// The type of source to display.
  final SourceType sourceType;

  @override
  List<Object> get props => [sourceType];
}

/// {@template source_list_refreshed}
/// Event added when the user requests to refresh the list of sources.
/// {@endtemplate}
final class SourceListRefreshed extends SourceListEvent {}

/// {@template source_list_load_more_requested}
/// Event added when the user scrolls to the bottom of the list, requesting
/// the next page of sources.
/// {@endtemplate}
final class SourceListLoadMoreRequested extends SourceListEvent {}

/// {@template source_list_country_filter_changed}
/// Event added when the user changes the country filter.
/// {@endtemplate}
final class SourceListCountryFilterChanged extends SourceListEvent {
  /// {@macro source_list_country_filter_changed}
  const SourceListCountryFilterChanged({required this.selectedCountries});

  /// The new set of selected countries for filtering.
  final Set<Country> selectedCountries;

  @override
  List<Object> get props => [selectedCountries];
}

/// {@template source_list_follow_toggled}
/// Event added when the user toggles the follow status of a source.
/// {@endtemplate}
final class SourceListFollowToggled extends SourceListEvent {
  /// {@macro source_list_follow_toggled}
  const SourceListFollowToggled({required this.source});

  /// The source whose follow status is being toggled.
  final Source source;

  @override
  List<Object> get props => [source];
}
