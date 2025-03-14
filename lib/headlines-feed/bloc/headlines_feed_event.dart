part of 'headlines_feed_bloc.dart';

/// {@template headlines_feed_event}
/// Base class for all events related to the headlines feed.
/// {@endtemplate}
sealed class HeadlinesFeedEvent extends Equatable {
  /// {@macro headlines_feed_event}
  const HeadlinesFeedEvent();

  @override
  List<Object?> get props => [];
}

/// {@template headlines_feed_fetch_requested}
/// Event triggered when the headlines feed needs to be fetched.
/// {@endtemplate}
final class HeadlinesFeedFetchRequested extends HeadlinesFeedEvent {
  /// {@macro headlines_feed_fetch_requested}
  const HeadlinesFeedFetchRequested({this.cursor});

  /// The cursor for pagination.
  final String? cursor;

  @override
  List<Object?> get props => [cursor];
}

/// {@template headlines_feed_refresh_requested}
/// Event triggered when the headlines feed needs to be refreshed.
/// {@endtemplate}
final class HeadlinesFeedRefreshRequested extends HeadlinesFeedEvent {}

/// {@template headlines_feed_filter_changed}
/// Event triggered when the filter parameters for the headlines feed change.
/// {@endtemplate}
final class HeadlinesFeedFilterChanged extends HeadlinesFeedEvent {
  /// {@macro headlines_feed_filter_changed}
  const HeadlinesFeedFilterChanged({
    this.category,
    this.source,
    this.eventCountry,
  });

  /// The selected category filter.
  final String? category;

  /// The selected source filter.
  final String? source;

  /// The selected event country filter.
  final String? eventCountry;

  @override
  List<Object?> get props => [category, source, eventCountry];
}
