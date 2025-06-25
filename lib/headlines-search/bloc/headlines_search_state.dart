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
  final String lastSearchTerm;

  @override
  List<Object?> get props => [...super.props, lastSearchTerm];
}

/// State when a search has successfully returned results.
class HeadlinesSearchSuccess extends HeadlinesSearchState {
  const HeadlinesSearchSuccess({
    required this.items,
    required this.hasMore,
    required this.lastSearchTerm,
    required super.selectedModelType,
    this.cursor,
    this.errorMessage,
  });

  final List<FeedItem> items;
  final bool hasMore;
  final String? cursor;
  final String? errorMessage;
  final String lastSearchTerm;

  HeadlinesSearchSuccess copyWith({
    List<FeedItem>? items,
    bool? hasMore,
    String? cursor,
    String? errorMessage,
    String? lastSearchTerm,
    SearchModelType? selectedModelType,
    bool clearErrorMessage = false,
  }) {
    return HeadlinesSearchSuccess(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      lastSearchTerm: lastSearchTerm ?? this.lastSearchTerm,
      selectedModelType: selectedModelType ?? this.selectedModelType,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    items,
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
  final String lastSearchTerm;

  @override
  List<Object?> get props => [...super.props, errorMessage, lastSearchTerm];
}
