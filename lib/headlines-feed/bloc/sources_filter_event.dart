part of 'sources_filter_bloc.dart';

abstract class SourcesFilterEvent extends Equatable {
  const SourcesFilterEvent();

  @override
  List<Object?> get props => [];
}

class LoadSourceFilterData extends SourcesFilterEvent {
  const LoadSourceFilterData({this.initialSelectedSources = const []});

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

class ClearSourceFiltersRequested extends SourcesFilterEvent {
  const ClearSourceFiltersRequested();
}

// Internal event - not part of public API, hence leading underscore
class _FetchFilteredSourcesRequested extends SourcesFilterEvent {
  const _FetchFilteredSourcesRequested();
}
