part of 'headlines_search_bloc.dart';

sealed class HeadlinesSearchState extends Equatable {
  const HeadlinesSearchState();

  @override
  List<Object?> get props => [];
}

final class HeadlinesSearchInitial extends HeadlinesSearchState {}

final class HeadlinesSearchLoading extends HeadlinesSearchState {}

final class HeadlinesSearchLoaded extends HeadlinesSearchState {
  const HeadlinesSearchLoaded({
    required this.headlines,
    this.hasReachedMax = false,
    this.cursor,
  });

  final List<Headline> headlines;
  final bool hasReachedMax;
  final String? cursor;

  HeadlinesSearchLoaded copyWith({
    List<Headline>? headlines,
    bool? hasReachedMax,
    String? cursor,
  }) {
    return HeadlinesSearchLoaded(
      headlines: headlines ?? this.headlines,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      cursor: cursor ?? this.cursor,
    );
  }

  @override
  List<Object?> get props => [headlines, hasReachedMax, cursor];
}

final class HeadlinesSearchError extends HeadlinesSearchState {
  const HeadlinesSearchError({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}
