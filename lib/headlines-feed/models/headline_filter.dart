import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// {@template headline_filter}
/// A model representing the filter parameters for headlines.
/// {@endtemplate}
class HeadlineFilter extends Equatable {
  /// {@macro headline_filter}
  const HeadlineFilter({
    this.topics,
    this.sources,
    this.selectedSourceCountryIsoCodes,
    this.selectedSourceSourceTypes,
    this.eventCountries,
    this.isFromFollowedItems = false,
  });

  /// The list of selected topics to filter headlines by.
  final List<Topic>? topics;

  /// The list of selected sources to filter headlines by.
  final List<Source>? sources;

  /// The set of ISO codes for countries selected to filter sources by their
  /// headquarters.
  final Set<String>? selectedSourceCountryIsoCodes;

  /// The set of source types selected to filter sources by.
  final Set<SourceType>? selectedSourceSourceTypes;

  /// The list of selected event countries to filter headlines by.
  final List<Country>? eventCountries;

  /// Whether the filter is based on the user's followed items.
  final bool isFromFollowedItems;

  @override
  List<Object?> get props => [
    topics,
    sources,
    selectedSourceCountryIsoCodes,
    selectedSourceSourceTypes,
    eventCountries,
    isFromFollowedItems,
  ];

  /// Creates a copy of this [HeadlineFilter] but with the given fields
  /// replaced with the new values.
  HeadlineFilter copyWith({
    List<Topic>? topics,
    List<Source>? sources,
    Set<String>? selectedSourceCountryIsoCodes,
    Set<SourceType>? selectedSourceSourceTypes,
    List<Country>? eventCountries,
    bool? isFromFollowedItems,
  }) {
    return HeadlineFilter(
      topics: topics ?? this.topics,
      sources: sources ?? this.sources,
      selectedSourceCountryIsoCodes:
          selectedSourceCountryIsoCodes ?? this.selectedSourceCountryIsoCodes,
      selectedSourceSourceTypes:
          selectedSourceSourceTypes ?? this.selectedSourceSourceTypes,
      eventCountries: eventCountries ?? this.eventCountries,
      isFromFollowedItems: isFromFollowedItems ?? this.isFromFollowedItems,
    );
  }
}
