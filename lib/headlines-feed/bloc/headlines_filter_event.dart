part of 'headlines_filter_bloc.dart';

/// {@template headlines_filter_event}
/// Base class for all events in the [HeadlinesFilterBloc].
/// {@endtemplate}
sealed class HeadlinesFilterEvent extends Equatable {
  /// {@macro headlines_filter_event}
  const HeadlinesFilterEvent();

  @override
  List<Object> get props => [];
}

/// {@template filter_data_loaded}
/// Event triggered to load all initial filter data (topics, sources, countries).
///
/// This event is dispatched when the filter page is initialized.
/// {@endtemplate}
final class FilterDataLoaded extends HeadlinesFilterEvent {
  /// {@macro filter_data_loaded}
  const FilterDataLoaded({
    this.initialSelectedTopics = const [],
    this.initialSelectedSources = const [],
    this.initialSelectedCountries = const [],
  });

  /// The topics that were initially selected on the previous page.
  final List<Topic> initialSelectedTopics;

  /// The sources that were initially selected on the previous page.
  final List<Source> initialSelectedSources;

  /// The countries that were initially selected on the previous page.
  final List<Country> initialSelectedCountries;

  @override
  List<Object> get props => [
    initialSelectedTopics,
    initialSelectedSources,
    initialSelectedCountries,
  ];
}

/// {@template filter_topic_toggled}
/// Event triggered when a topic checkbox is toggled.
/// {@endtemplate}
final class FilterTopicToggled extends HeadlinesFilterEvent {
  /// {@macro filter_topic_toggled}
  const FilterTopicToggled({required this.topic, required this.isSelected});

  /// The [Topic] that was toggled.
  final Topic topic;

  /// The new selection state of the topic.
  final bool isSelected;

  @override
  List<Object> get props => [topic, isSelected];
}

/// {@template filter_source_toggled}
/// Event triggered when a source checkbox is toggled.
/// {@endtemplate}
final class FilterSourceToggled extends HeadlinesFilterEvent {
  /// {@macro filter_source_toggled}
  const FilterSourceToggled({required this.source, required this.isSelected});

  /// The [Source] that was toggled.
  final Source source;

  /// The new selection state of the source.
  final bool isSelected;

  @override
  List<Object> get props => [source, isSelected];
}

/// {@template filter_country_toggled}
/// Event triggered when a country checkbox is toggled.
/// {@endtemplate}
final class FilterCountryToggled extends HeadlinesFilterEvent {
  /// {@macro filter_country_toggled}
  const FilterCountryToggled({required this.country, required this.isSelected});

  /// The [Country] that was toggled.
  final Country country;

  /// The new selection state of the country.
  final bool isSelected;

  @override
  List<Object> get props => [country, isSelected];
}

/// {@template filter_selections_cleared}
/// Event triggered to clear all active filter selections.
/// {@endtemplate}
final class FilterSelectionsCleared extends HeadlinesFilterEvent {
  /// {@macro filter_selections_cleared}
  const FilterSelectionsCleared();
}

/// {@template filter_source_criteria_changed}
/// Event triggered when the source filtering criteria (headquarters or types)
/// are updated from the `SourceListFilterPage`.
/// {@endtemplate}
final class FilterSourceCriteriaChanged extends HeadlinesFilterEvent {
  /// {@macro filter_source_criteria_changed}
  const FilterSourceCriteriaChanged({
    this.selectedCountries,
    this.selectedSourceTypes,
  });

  /// The updated set of selected headquarters countries.
  final Set<Country>? selectedCountries;

  /// The updated set of selected source types.
  final Set<SourceType>? selectedSourceTypes;

  @override
  List<Object> get props => [
    if (selectedCountries != null) selectedCountries!,
    if (selectedSourceTypes != null) selectedSourceTypes!,
  ];
}
