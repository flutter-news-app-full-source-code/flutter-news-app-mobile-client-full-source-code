import 'package:equatable/equatable.dart';

/// {@template headline_filter}
/// A model representing the filter parameters for headlines.
/// {@endtemplate}
class HeadlineFilter extends Equatable {
  /// {@macro headline_filter}
  const HeadlineFilter({
    this.category,
    this.source,
    this.eventCountry,
  });

  /// The selected category filter.
  final String? category;

  /// The selected source filter.
  final String? source;

  /// The selected event country filter.
  final String? eventCountry;

  @override
  List<Object?> get props => [category, source, eventCountry];

  /// Creates a copy of this [HeadlineFilter] with the given fields
  /// replaced with the new values.
  HeadlineFilter copyWith({
    String? category,
    String? source,
    String? eventCountry,
  }) {
    return HeadlineFilter(
      category: category ?? this.category,
      source: source ?? this.source,
      eventCountry: eventCountry ?? this.eventCountry,
    );
  }
}
