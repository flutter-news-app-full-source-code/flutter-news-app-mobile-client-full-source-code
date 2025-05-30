import 'package:equatable/equatable.dart';
import 'package:ht_shared/ht_shared.dart';

/// {@template headline_filter}
/// A model representing the filter parameters for headlines.
/// {@endtemplate}
class HeadlineFilter extends Equatable {
  /// {@macro headline_filter}
  const HeadlineFilter({
    this.categories,
    this.sources,
    this.selectedSourceCountryIsoCodes,
    this.selectedSourceSourceTypes,
  });

  /// The list of selected category filters.
  /// Headlines matching *any* of these categories will be included (OR logic).
  final List<Category>? categories;

  /// The list of selected source filters.
  /// Headlines matching *any* of these sources will be included (OR logic).
  final List<Source>? sources;

  /// The set of selected country ISO codes for source filtering.
  final Set<String>? selectedSourceCountryIsoCodes;

  /// The set of selected source types for source filtering.
  final Set<SourceType>? selectedSourceSourceTypes;

  @override
  List<Object?> get props => [
        categories,
        sources,
        selectedSourceCountryIsoCodes,
        selectedSourceSourceTypes,
      ];

  /// Creates a copy of this [HeadlineFilter] with the given fields
  /// replaced with the new values.
  HeadlineFilter copyWith({
    List<Category>? categories,
    List<Source>? sources,
    Set<String>? selectedSourceCountryIsoCodes,
    Set<SourceType>? selectedSourceSourceTypes,
  }) {
    return HeadlineFilter(
      categories: categories ?? this.categories,
      sources: sources ?? this.sources,
      selectedSourceCountryIsoCodes: selectedSourceCountryIsoCodes ??
          this.selectedSourceCountryIsoCodes,
      selectedSourceSourceTypes:
          selectedSourceSourceTypes ?? this.selectedSourceSourceTypes,
    );
  }
}
