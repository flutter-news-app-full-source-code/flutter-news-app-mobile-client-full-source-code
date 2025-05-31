part of 'similar_headlines_bloc.dart';

abstract class SimilarHeadlinesState extends Equatable {
  const SimilarHeadlinesState();

  @override
  List<Object> get props => [];
}

class SimilarHeadlinesInitial extends SimilarHeadlinesState {}

class SimilarHeadlinesLoading extends SimilarHeadlinesState {}

class SimilarHeadlinesLoaded extends SimilarHeadlinesState {
  const SimilarHeadlinesLoaded({required this.similarHeadlines});

  final List<Headline> similarHeadlines;

  @override
  List<Object> get props => [similarHeadlines];
}

class SimilarHeadlinesEmpty extends SimilarHeadlinesState {}

class SimilarHeadlinesError extends SimilarHeadlinesState {
  const SimilarHeadlinesError({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}
