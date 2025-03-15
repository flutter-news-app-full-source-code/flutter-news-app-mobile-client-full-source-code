part of 'headlines_search_bloc.dart';

sealed class HeadlinesSearchEvent extends Equatable {
  const HeadlinesSearchEvent();

  @override
  List<Object> get props => [];
}

final class HeadlinesSearchTermChanged extends HeadlinesSearchEvent {
  const HeadlinesSearchTermChanged({required this.searchTerm});

  final String searchTerm;

  @override
  List<Object> get props => [searchTerm];
}

final class HeadlinesSearchRequested extends HeadlinesSearchEvent {}
