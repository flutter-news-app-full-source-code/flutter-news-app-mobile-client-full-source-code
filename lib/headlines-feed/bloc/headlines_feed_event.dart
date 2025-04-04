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
    this.categories, // Changed from category
    this.sources, // Changed from source
    this.eventCountries, // Changed from eventCountry
  });

  /// The list of selected category filters.
  final List<Category>? categories;

  /// The list of selected source filters.
  final List<Source>? sources;

  /// The list of selected event country filters.
  final List<Country>? eventCountries;

  @override
  List<Object?> get props => [categories, sources, eventCountries];
}
