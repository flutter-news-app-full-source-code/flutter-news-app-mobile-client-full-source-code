part of 'headlines_search_bloc.dart';

abstract class HeadlinesSearchState extends Equatable {
  const HeadlinesSearchState();
  abstract final String? lastSearchTerm;
  @override
  List<Object?> get props => [];
}

class HeadlinesSearchLoading extends HeadlinesSearchState {
  @override
  final String? lastSearchTerm = null;
  @override
  List<Object?> get props => [];
}

class HeadlinesSearchSuccess extends HeadlinesSearchState {
  const HeadlinesSearchSuccess({
    required this.headlines,
    required this.hasMore,
    required this.lastSearchTerm, this.cursor,
    this.errorMessage,
  });

  final List<Headline> headlines;
  final bool hasMore;
  final String? cursor;
  final String? errorMessage;
  @override
  final String? lastSearchTerm;

  HeadlinesSearchSuccess copyWith(
      {List<Headline>? headlines,
      bool? hasMore,
      String? cursor,
      String? errorMessage,
      String? lastSearchTerm,}) {
    return HeadlinesSearchSuccess(
        headlines: headlines ?? this.headlines,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor ?? this.cursor,
        errorMessage: errorMessage ?? this.errorMessage,
        lastSearchTerm: lastSearchTerm ?? this.lastSearchTerm,);
  }

  @override
  List<Object?> get props =>
      [headlines, hasMore, cursor, errorMessage, lastSearchTerm];
}
