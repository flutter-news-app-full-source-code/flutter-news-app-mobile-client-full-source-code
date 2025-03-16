part of 'headlines_search_bloc.dart';

sealed class HeadlinesSearchEvent extends Equatable {
  const HeadlinesSearchEvent();

  @override
  List<Object> get props => [];
}

final class HeadlinesSearchFetchRequested extends HeadlinesSearchEvent {
  const HeadlinesSearchFetchRequested({required this.searchTerm});

  final String searchTerm;

  @override
  List<Object> get props => [searchTerm];
}
