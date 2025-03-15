part of 'headlines_search_bloc.dart';

sealed class HeadlinesSearchState extends Equatable {
  const HeadlinesSearchState();

  @override
  List<Object> get props => [];
}

final class HeadlinesSearchInitial extends HeadlinesSearchState {}

final class HeadlinesSearchLoading extends HeadlinesSearchState {}

final class HeadlinesSearchLoaded extends HeadlinesSearchState {
  const HeadlinesSearchLoaded({required this.headlines});

  final List<Headline> headlines;

  @override
  List<Object> get props => [headlines];
}

final class HeadlinesSearchError extends HeadlinesSearchState {
  const HeadlinesSearchError({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}
