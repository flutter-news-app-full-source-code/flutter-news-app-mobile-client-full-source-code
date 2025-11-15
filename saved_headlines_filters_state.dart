part of 'saved_headlines_filters_bloc.dart';

/// The status of the [SavedHeadlinesFiltersState].
enum SavedHeadlinesFiltersStatus {
  /// The initial state.
  initial,

  /// The state when loading data.
  loading,

  /// The state when data has been successfully loaded.
  success,

  /// The state when an error has occurred.
  failure,
}

/// {@template saved_headlines_filters_state}
/// Represents the state for the saved headlines filters management page.
///
/// This state holds the list of all saved headline filters, along with the
/// current loading/error status.
/// {@endtemplate}
class SavedHeadlinesFiltersState extends Equatable {
  /// {@macro saved_headlines_filters_state}
  const SavedHeadlinesFiltersState({
    this.status = SavedHeadlinesFiltersStatus.initial,
    this.filters = const [],
    this.error,
  });

  /// The current status of the state.
  final SavedHeadlinesFiltersStatus status;

  /// The list of saved headline filters.
  final List<SavedHeadlineFilter> filters;

  /// An optional error object if the status is [SavedHeadlinesFiltersStatus.failure].
  final HttpException? error;

  @override
  List<Object?> get props => [status, filters, error];
}
