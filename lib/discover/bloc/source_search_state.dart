part of 'source_search_bloc.dart';

/// The status of the [SourceSearchBloc].
enum SourceSearchStatus {
  /// The initial state, before any search has been performed.
  initial,

  /// The state when a search is in progress.
  loading,

  /// The state when a search has completed successfully.
  success,

  /// The state when a search has failed.
  failure,
}

/// {@template source_search_state}
/// The state of the source search feature.
/// {@endtemplate}
final class SourceSearchState extends Equatable {
  /// {@macro source_search_state}
  const SourceSearchState({
    this.status = SourceSearchStatus.initial,
    this.sources = const [],
    this.error,
  });

  /// The current status of the search.
  final SourceSearchStatus status;

  /// The list of sources found by the search.
  final List<Source> sources;

  /// The error that occurred during the search, if any.
  final HttpException? error;

  /// Creates a copy of the current [SourceSearchState] with the given fields
  /// replaced with the new values.
  SourceSearchState copyWith({
    SourceSearchStatus? status,
    List<Source>? sources,
    HttpException? error,
    bool clearError = false,
  }) {
    return SourceSearchState(
      status: status ?? this.status,
      sources: sources ?? this.sources,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, sources, error];
}
