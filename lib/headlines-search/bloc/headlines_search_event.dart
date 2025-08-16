part of 'headlines_search_bloc.dart';

sealed class HeadlinesSearchEvent extends Equatable {
  const HeadlinesSearchEvent();

  @override
  List<Object> get props => [];
}

final class HeadlinesSearchModelTypeChanged extends HeadlinesSearchEvent {
  const HeadlinesSearchModelTypeChanged(this.newModelType);

  final ContentType newModelType;

  @override
  List<Object> get props => [newModelType];
}

final class HeadlinesSearchFetchRequested extends HeadlinesSearchEvent {
  const HeadlinesSearchFetchRequested({
    required this.searchTerm,
    required this.theme,
  });

  final String searchTerm;
  final ThemeData theme;

  @override
  List<Object> get props => [searchTerm, theme];
}
