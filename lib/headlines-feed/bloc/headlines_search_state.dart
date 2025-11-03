part of 'headlines_search_bloc.dart';

/// Defines the status of the headline search operation.
enum HeadlineSearchStatus {
  /// The initial state before any search has been performed.
  initial,

  /// A search is currently in progress.
  loading,

  /// The search completed successfully.
  success,

  /// The search failed.
  failure,
}

/// {@template headline_search_state}
/// Represents the state for the headline search feature.
/// {@endtemplate}
final class HeadlineSearchState extends Equatable {
  /// {@macro headline_search_state}
  const HeadlineSearchState({
    this.status = HeadlineSearchStatus.initial,
    this.headlines = const [],
    this.error,
  });

  /// The current status of the search.
  final HeadlineSearchStatus status;

  /// The list of headlines found.
  final List<Headline> headlines;

  /// The error that occurred during the search, if any.
  final HttpException? error;

  /// Creates a copy of this [HeadlineSearchState] with the given fields
  /// replaced with the new values.
  HeadlineSearchState copyWith({
    HeadlineSearchStatus? status,
    List<Headline>? headlines,
    HttpException? error,
  }) {
    return HeadlineSearchState(
      status: status ?? this.status,
      headlines: headlines ?? this.headlines,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, headlines, error];
}
