part of 'sources_filter_bloc.dart';

/// Enum representing the different statuses of the source filter data fetching.
enum SourcesFilterStatus {
  /// Initial state, no data loaded yet.
  initial,

  /// Currently fetching the first page of sources.
  loading,

  /// Successfully loaded sources. May be loading more in the background.
  success,

  /// An error occurred while fetching sources.
  failure,

  /// Loading more sources for pagination (infinity scroll).
  loadingMore,
}

/// {@template sources_filter_state}
/// Represents the state for the source filter feature.
///
/// Contains the list of fetched sources, pagination information,
/// loading/error status.
/// {@endtemplate}
final class SourcesFilterState extends Equatable {
  /// {@macro sources_filter_state}
  const SourcesFilterState({
    this.status = SourcesFilterStatus.initial,
    this.sources = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  /// The current status of fetching sources.
  final SourcesFilterStatus status;

  /// The list of [Source] objects fetched so far.
  final List<Source> sources;

  /// Flag indicating if there are more sources available to fetch.
  final bool hasMore;

  /// The cursor string to fetch the next page of sources.
  /// This is typically the ID of the last fetched source.
  final String? cursor;

  /// An optional error object if the status is [SourcesFilterStatus.failure].
  final Object? error;

  /// Creates a copy of this state with the given fields replaced.
  SourcesFilterState copyWith({
    SourcesFilterStatus? status,
    List<Source>? sources,
    bool? hasMore,
    String? cursor,
    Object? error,
    bool clearError = false, // Flag to explicitly clear the error
    bool clearCursor = false, // Flag to explicitly clear the cursor
  }) {
    return SourcesFilterState(
      status: status ?? this.status,
      sources: sources ?? this.sources,
      hasMore: hasMore ?? this.hasMore,
      // Allow explicitly setting cursor to null or clearing it
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      // Clear error if requested, otherwise keep existing or use new one
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, sources, hasMore, cursor, error];
}
