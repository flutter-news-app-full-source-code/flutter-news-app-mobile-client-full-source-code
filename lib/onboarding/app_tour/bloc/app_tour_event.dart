part of 'app_tour_bloc.dart';

/// {@template app_tour_event}
/// Base class for all events related to the app tour.
/// {@endtemplate}
sealed class AppTourEvent extends Equatable {
  /// {@macro app_tour_event}
  const AppTourEvent();

  @override
  List<Object> get props => [];
}

/// {@template app_tour_page_changed}
/// Dispatched when the user swipes to a different page in the tour.
/// {@endtemplate}
final class AppTourPageChanged extends AppTourEvent {
  /// {@macro app_tour_page_changed}
  const AppTourPageChanged(this.pageIndex);

  /// The index of the new page.
  final int pageIndex;

  @override
  List<Object> get props => [pageIndex];
}

/// {@template app_tour_completed}
/// Dispatched when the user completes or skips the tour.
/// {@endtemplate}
final class AppTourCompleted extends AppTourEvent {}
