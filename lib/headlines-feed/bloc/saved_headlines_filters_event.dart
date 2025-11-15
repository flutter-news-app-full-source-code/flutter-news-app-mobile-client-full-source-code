part of 'saved_headlines_filters_bloc.dart';

/// {@template saved_headlines_filters_event}
/// Base class for all events related to the saved headlines filters page.
/// {@endtemplate}
sealed class SavedHeadlinesFiltersEvent extends Equatable {
  /// {@macro saved_headlines_filters_event}
  const SavedHeadlinesFiltersEvent();

  @override
  List<Object> get props => [];
}

/// {@template saved_headlines_filters_data_loaded}
/// Dispatched when the page is first initialized to load the saved filters.
/// {@endtemplate}
final class SavedHeadlinesFiltersDataLoaded extends SavedHeadlinesFiltersEvent {
  /// {@macro saved_headlines_filters_data_loaded}
  const SavedHeadlinesFiltersDataLoaded();
}

/// {@template saved_headlines_filters_reordered}
/// Dispatched when the user reorders the list of saved filters.
/// {@endtemplate}
final class SavedHeadlinesFiltersReordered extends SavedHeadlinesFiltersEvent {
  /// {@macro saved_headlines_filters_reordered}
  const SavedHeadlinesFiltersReordered({required this.reorderedFilters});

  /// The complete list of filters in their new order.
  final List<SavedHeadlineFilter> reorderedFilters;

  @override
  List<Object> get props => [reorderedFilters];
}

/// {@template saved_headlines_filters_deleted}
/// Dispatched when a user deletes a saved filter from the list.
/// {@endtemplate}
final class SavedHeadlinesFiltersDeleted extends SavedHeadlinesFiltersEvent {
  /// {@macro saved_headlines_filters_deleted}
  const SavedHeadlinesFiltersDeleted({required this.filterId});

  /// The ID of the filter to be deleted.
  final String filterId;

  @override
  List<Object> get props => [filterId];
}
