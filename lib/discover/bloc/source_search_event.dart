part of 'source_search_bloc.dart';

/// Base class for all events related to the [SourceSearchBloc].
sealed class SourceSearchEvent extends Equatable {
  /// {@macro source_search_event}
  const SourceSearchEvent();

  @override
  List<Object> get props => [];
}

/// {@template source_search_query_changed}
/// Event added when the search query for sources changes.
/// {@endtemplate}
final class SourceSearchQueryChanged extends SourceSearchEvent {
  /// {@macro source_search_query_changed}
  const SourceSearchQueryChanged(this.query);

  /// The new search query.
  final String query;

  @override
  List<Object> get props => [query];
}
