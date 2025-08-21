part of 'topics_filter_bloc.dart';

/// {@template topics_filter_event}
/// Base class for events related to fetching and managing topic filters.
/// {@endtemplate}
sealed class TopicsFilterEvent extends Equatable {
  /// {@macro topics_filter_event}
  const TopicsFilterEvent();

  @override
  List<Object> get props => [];
}

/// {@template topics_filter_requested}
/// Event triggered to request the initial list of topics.
/// {@endtemplate}
final class TopicsFilterRequested extends TopicsFilterEvent {}

/// {@template topics_filter_load_more_requested}
/// Event triggered to request the next page of topics for pagination.
/// {@endtemplate}
final class TopicsFilterLoadMoreRequested extends TopicsFilterEvent {}

/// {@template topics_filter_apply_followed_requested}
/// Event triggered to request applying the user's followed topics as filters.
/// {@endtemplate}
final class TopicsFilterApplyFollowedRequested extends TopicsFilterEvent {}
