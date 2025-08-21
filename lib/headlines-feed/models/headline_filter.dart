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
    this.eventCountries,
    this.isFromFollowedItems = false,
  });

  /// The list of selected topics to filter headlines by.
  final List<Topic>? topics;

  /// The list of selected sources to filter headlines by.
  ///
  /// Note: The `SourceFilterPage` uses internal UI state (country and source
  /// type capsules) to refine the list of sources presented to the user.
  /// However, only the *explicitly selected* sources from that refined list
  /// are passed back and stored here. The country and source type selections
  /// themselves are *not* part of this filter model, as they are purely for
  /// UI-side filtering on the `SourceFilterPage` and should not affect the
  /// backend query for headlines.
  final List<Source>? sources;

  /// The list of selected event countries to filter headlines by.
  final List<Country>? eventCountries;

  /// Whether the filter is based on the user's followed items.
  ///
  /// When `true`, the `topics` and `sources` fields will be populated based
  /// on the user's followed items, and manual selections for these categories
  /// will be ignored.
  final bool isFromFollowedItems;

  @override
  List<Object?> get props => [
    topics,
    sources,
    eventCountries,
    isFromFollowedItems,
  ];

  /// Creates a copy of this [HeadlineFilter] but with the given fields
  /// replaced with the new values.
  HeadlineFilter copyWith({
    List<Topic>? topics,
    List<Source>? sources,
    List<Country>? eventCountries,
    bool? isFromFollowedItems,
  }) {
    return HeadlineFilter(
      topics: topics ?? this.topics,
      sources: sources ?? this.sources,
      eventCountries: eventCountries ?? this.eventCountries,
      isFromFollowedItems: isFromFollowedItems ?? this.isFromFollowedItems,
    );
  }
}
