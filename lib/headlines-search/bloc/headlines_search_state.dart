part of 'headlines_search_bloc.dart';

abstract class HeadlinesSearchState extends Equatable {
  const HeadlinesSearchState();
  // lastSearchTerm will be defined in specific states that need it.
  @override
  List<Object?> get props => [];
}

/// Initial state before any search is performed.
class HeadlinesSearchInitial extends HeadlinesSearchState {
  const HeadlinesSearchInitial();
  // No lastSearchTerm needed for initial state.
}

/// State when a search is actively in progress.
class HeadlinesSearchLoading extends HeadlinesSearchState {
  const HeadlinesSearchLoading({this.lastSearchTerm});
  final String? lastSearchTerm; // Term being loaded

  @override
  List<Object?> get props => [lastSearchTerm];
}

/// State when a search has successfully returned results.
class HeadlinesSearchSuccess extends HeadlinesSearchState {
  const HeadlinesSearchSuccess({
    required this.headlines,
    required this.hasMore,
    required this.lastSearchTerm,
    this.cursor,
    this.errorMessage, // For non-critical errors like pagination failure
  });

  final List<Headline> headlines;
  final bool hasMore;
  final String? cursor;
  final String? errorMessage; // e.g., for pagination errors
  final String lastSearchTerm; // The term that yielded these results

  HeadlinesSearchSuccess copyWith({
    List<Headline>? headlines,
    bool? hasMore,
    String? cursor,
    String? errorMessage, // Allow clearing/setting error
    String? lastSearchTerm,
    bool clearErrorMessage = false,
  }) {
    return HeadlinesSearchSuccess(
      headlines: headlines ?? this.headlines,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastSearchTerm: lastSearchTerm ?? this.lastSearchTerm,
    );
  }

  @override
  List<Object?> get props => [
    headlines,
    hasMore,
    cursor,
    errorMessage,
    lastSearchTerm,
  ];
}

/// State when a search operation has failed.
class HeadlinesSearchFailure extends HeadlinesSearchState {
  const HeadlinesSearchFailure({
    required this.errorMessage,
    required this.lastSearchTerm,
  });

  final String errorMessage;
  final String lastSearchTerm; // The term that failed

  @override
  List<Object?> get props => [errorMessage, lastSearchTerm];
}
