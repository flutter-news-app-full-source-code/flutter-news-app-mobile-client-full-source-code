part of 'headlines_search_bloc.dart';

abstract class HeadlinesSearchState extends Equatable {
  const HeadlinesSearchState({
    this.selectedModelType = SearchModelType.headline,
  });

  final SearchModelType selectedModelType;

  @override
  List<Object?> get props => [selectedModelType];
}

/// Initial state before any search is performed.
class HeadlinesSearchInitial extends HeadlinesSearchState {
  const HeadlinesSearchInitial({super.selectedModelType});
}

/// State when a search is actively in progress.
class HeadlinesSearchLoading extends HeadlinesSearchState {
  const HeadlinesSearchLoading({
    required this.lastSearchTerm,
    required super.selectedModelType,
  });
  final String lastSearchTerm; // Term being loaded

  @override
  List<Object?> get props => [...super.props, lastSearchTerm];
}

/// State when a search has successfully returned results.
class HeadlinesSearchSuccess extends HeadlinesSearchState {
  const HeadlinesSearchSuccess({
    required this.results,
    required this.hasMore,
    required this.lastSearchTerm,
    required super.selectedModelType, // The model type for these results
    this.cursor,
    this.errorMessage, // For non-critical errors like pagination failure
  });

  final List<dynamic> results; // Can hold Headline, Category, Source, Country
  final bool hasMore;
  final String? cursor;
  final String? errorMessage; // e.g., for pagination errors
  final String lastSearchTerm; // The term that yielded these results

  HeadlinesSearchSuccess copyWith({
    List<dynamic>? results,
    bool? hasMore,
    String? cursor,
    String? errorMessage,
    String? lastSearchTerm,
    SearchModelType? selectedModelType,
    bool clearErrorMessage = false,
  }) {
    return HeadlinesSearchSuccess(
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastSearchTerm: lastSearchTerm ?? this.lastSearchTerm,
      selectedModelType: selectedModelType ?? this.selectedModelType,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    results,
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
    required super.selectedModelType,
  });

  final String errorMessage;
  final String lastSearchTerm; // The term that failed

  @override
  List<Object?> get props => [...super.props, errorMessage, lastSearchTerm];
}
