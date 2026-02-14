part of 'app_tour_bloc.dart';

/// {@template app_tour_state}
/// Represents the state of the app tour.
/// {@endtemplate}
class AppTourState extends Equatable {
  /// {@macro app_tour_state}
  const AppTourState({this.currentPage = 0});

  /// The index of the currently visible page in the tour.
  final int currentPage;

  /// The total number of pages in the tour.
  static const int totalPages = 3;

  /// A convenience getter to check if the current page is the last one.
  bool get isLastPage => currentPage == totalPages - 1;

  /// Creates a copy of this state with the given fields replaced with the new
  /// values.
  AppTourState copyWith({int? currentPage}) {
    return AppTourState(currentPage: currentPage ?? this.currentPage);
  }

  @override
  List<Object> get props => [currentPage];
}
