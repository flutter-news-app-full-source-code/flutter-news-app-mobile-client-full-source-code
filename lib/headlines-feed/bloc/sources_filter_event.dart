part of 'sources_filter_bloc.dart';

/// {@template sources_filter_event}
/// Base class for events related to fetching and managing source filters.
/// {@endtemplate}
sealed class SourcesFilterEvent extends Equatable {
  /// {@macro sources_filter_event}
  const SourcesFilterEvent();

  @override
  List<Object> get props => [];
}

/// {@template sources_filter_requested}
/// Event triggered to request the initial list of sources.
/// {@endtemplate}
final class SourcesFilterRequested extends SourcesFilterEvent {}

/// {@template sources_filter_load_more_requested}
/// Event triggered to request the next page of sources for pagination.
/// {@endtemplate}
final class SourcesFilterLoadMoreRequested extends SourcesFilterEvent {}
