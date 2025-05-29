import 'package:equatable/equatable.dart';
import 'package:ht_shared/ht_shared.dart';

/// {@template headline_filter}
/// A model representing the filter parameters for headlines.
/// {@endtemplate}
class HeadlineFilter extends Equatable {
  /// {@macro headline_filter}
  const HeadlineFilter({this.categories, this.sources});

  /// The list of selected category filters.
  /// Headlines matching *any* of these categories will be included (OR logic).
  final List<Category>? categories;

  /// The list of selected source filters.
  /// Headlines matching *any* of these sources will be included (OR logic).
  final List<Source>? sources;

  @override
  List<Object?> get props => [categories, sources];

  /// Creates a copy of this [HeadlineFilter] with the given fields
  /// replaced with the new values.
  HeadlineFilter copyWith({
    List<Category>? categories,
    List<Source>? sources,
  }) {
    return HeadlineFilter(
      categories: categories ?? this.categories,
      sources: sources ?? this.sources,
    );
  }
}
