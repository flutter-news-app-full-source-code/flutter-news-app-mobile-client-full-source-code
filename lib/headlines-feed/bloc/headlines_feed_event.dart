part of 'headlines_feed_bloc.dart';

/// {@template headlines_feed_event}
/// Base class for all events related to the headlines feed.
/// {@endtemplate}
sealed class HeadlinesFeedEvent extends Equatable {
  /// {@macro headlines_feed_event}
  const HeadlinesFeedEvent();

  @override
  List<Object> get props => [];
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
  List<Object> get props => [cursor ?? ''];
}

/// {@template headlines_feed_refresh_requested}
/// Event triggered when the headlines feed needs to be refreshed.
/// {@endtemplate}
final class HeadlinesFeedRefreshRequested extends HeadlinesFeedEvent {}
