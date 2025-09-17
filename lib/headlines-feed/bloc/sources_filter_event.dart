// ignore_for_file: avoid_positional_boolean_parameters

part of 'sources_filter_bloc.dart';

abstract class SourcesFilterEvent extends Equatable {
  const SourcesFilterEvent();

  @override
  List<Object?> get props => [];
}

/// {@template load_source_filter_data}
/// Event triggered to load the initial data for the source filter page.
///
/// This event is dispatched when the `SourceFilterPage` is initialized.
/// It fetches all available countries and sources, and initializes the
/// internal state with any `initialSelectedSources` passed from the
/// `HeadlinesFilterPage`. The country and source type capsule selections
/// are ephemeral to the `SourceFilterPage` and are not passed via this event.
/// {@endtemplate}
class LoadSourceFilterData extends SourcesFilterEvent {
  /// {@macro load_source_filter_data}
  const LoadSourceFilterData({this.initialSelectedSources = const []});

  /// The list of sources that were initially selected on the previous page.
  final List<Source> initialSelectedSources;

  @override
  List<Object?> get props => [initialSelectedSources];
}

class CountryCapsuleToggled extends SourcesFilterEvent {
  const CountryCapsuleToggled(this.countryIsoCode);

  /// If countryIsoCode is empty, it implies "All Countries".
  final String countryIsoCode;

  @override
  List<Object> get props => [countryIsoCode];
}

class AllSourceTypesCapsuleToggled extends SourcesFilterEvent {
  const AllSourceTypesCapsuleToggled();
}

class SourceTypeCapsuleToggled extends SourcesFilterEvent {
  const SourceTypeCapsuleToggled(this.sourceType);

  final SourceType sourceType;

  @override
  List<Object> get props => [sourceType];
}

class SourceCheckboxToggled extends SourcesFilterEvent {
  const SourceCheckboxToggled(this.sourceId, this.isSelected);

  final String sourceId;
  final bool isSelected;

  @override
  List<Object> get props => [sourceId, isSelected];
}
