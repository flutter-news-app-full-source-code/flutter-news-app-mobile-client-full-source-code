part of 'topics_filter_bloc.dart';

/// Enum representing the different statuses of the category filter data fetching.
enum CategoriesFilterStatus {
  /// Initial state, no data loaded yet.
  initial,

  /// Currently fetching the first page of categories.
  loading,

  /// Successfully loaded categories. May be loading more in the background.
  success,

  /// An error occurred while fetching categories.
  failure,

  /// Loading more categories for pagination (infinity scroll).
  loadingMore,
}

/// {@template categories_filter_state}
/// Represents the state for the category filter feature.
///
/// Contains the list of fetched categories, pagination information,
/// loading/error status.
/// {@endtemplate}
final class CategoriesFilterState extends Equatable {
  /// {@macro categories_filter_state}
  const CategoriesFilterState({
    this.status = CategoriesFilterStatus.initial,
    this.categories = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  /// The current status of fetching categories.
  final CategoriesFilterStatus status;

  /// The list of [Category] objects fetched so far.
  final List<Category> categories;

  /// Flag indicating if there are more categories available to fetch.
  final bool hasMore;

  /// The cursor string to fetch the next page of categories.
  /// This is typically the ID of the last fetched category.
  final String? cursor;

  /// An optional error object if the status is [CategoriesFilterStatus.failure].
  final Object? error;

  /// Creates a copy of this state with the given fields replaced.
  CategoriesFilterState copyWith({
    CategoriesFilterStatus? status,
    List<Category>? categories,
    bool? hasMore,
    String? cursor,
    Object? error,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return CategoriesFilterState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      hasMore: hasMore ?? this.hasMore,
      // Allow explicitly setting cursor to null or clearing it
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      // Clear error if requested, otherwise keep existing or use new one
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, categories, hasMore, cursor, error];
}
