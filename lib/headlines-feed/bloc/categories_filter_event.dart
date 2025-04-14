part of 'categories_filter_bloc.dart';

/// {@template categories_filter_event}
/// Base class for events related to fetching and managing category filters.
/// {@endtemplate}
sealed class CategoriesFilterEvent extends Equatable {
  /// {@macro categories_filter_event}
  const CategoriesFilterEvent();

  @override
  List<Object> get props => [];
}

/// {@template categories_filter_requested}
/// Event triggered to request the initial list of categories.
/// {@endtemplate}
final class CategoriesFilterRequested extends CategoriesFilterEvent {}

/// {@template categories_filter_load_more_requested}
/// Event triggered to request the next page of categories for pagination.
/// {@endtemplate}
final class CategoriesFilterLoadMoreRequested extends CategoriesFilterEvent {}
