part of 'headlines_search_bloc.dart';

/// Abstract base class for all events in the [HeadlineSearchBloc].
sealed class HeadlineSearchEvent extends Equatable {
  /// {@macro headline_search_event}
  const HeadlineSearchEvent();

  @override
  List<Object> get props => [];
}

/// Dispatched when the search query changes.
final class HeadlineSearchQueryChanged extends HeadlineSearchEvent {
  /// {@macro headline_search_query_changed}
  const HeadlineSearchQueryChanged(this.query);

  /// The search query string.
  final String query;

  @override
  List<Object> get props => [query];
}
