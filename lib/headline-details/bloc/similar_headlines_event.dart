part of 'similar_headlines_bloc.dart';

abstract class SimilarHeadlinesEvent extends Equatable {
  const SimilarHeadlinesEvent();

  @override
  List<Object> get props => [];
}

class FetchSimilarHeadlines extends SimilarHeadlinesEvent {
  const FetchSimilarHeadlines({required this.currentHeadline});

  final Headline currentHeadline;

  @override
  List<Object> get props => [currentHeadline];
}
