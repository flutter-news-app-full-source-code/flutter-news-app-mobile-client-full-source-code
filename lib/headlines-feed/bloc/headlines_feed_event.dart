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
/// Event triggered when more headlines need to be fetched, either for the
/// initial load or for pagination.
/// {@endtemplate}
final class HeadlinesFeedFetchRequested extends HeadlinesFeedEvent {
  /// {@macro headlines_feed_fetch_requested}
  ///
  /// Optionally includes a [cursor] to fetch the next page. If [cursor] is null,
  /// it typically indicates an initial fetch request.
  const HeadlinesFeedFetchRequested({this.cursor});

  /// The cursor indicating the starting point for the next page of headlines.
  /// If null, fetches the first page.
  final String? cursor;

  @override
  List<Object?> get props => [cursor];
}

/// {@template headlines_feed_refresh_requested}
/// Event triggered when the user requests a manual refresh of the headlines feed
/// (e.g., via pull-to-refresh). This should fetch the first page using the
/// currently active filters.
/// {@endtemplate}
final class HeadlinesFeedRefreshRequested extends HeadlinesFeedEvent {}

/// {@template headlines_feed_filters_applied}
/// Event triggered when a new set of filters, selected by the user,
/// should be applied to the headlines feed.
/// {@endtemplate}
final class HeadlinesFeedFiltersApplied extends HeadlinesFeedEvent {
  /// {@macro headlines_feed_filters_applied}
  ///
  /// Contains the complete [HeadlineFilter] configuration to be applied.
  const HeadlinesFeedFiltersApplied({required this.filter});

  /// The [HeadlineFilter] containing the selected categories, sources,
  /// and/or countries.
  final HeadlineFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// {@template headlines_feed_filters_cleared}
/// Event triggered when the user requests to clear all active filters
/// and view the unfiltered headlines feed.
/// {@endtemplate}
final class HeadlinesFeedFiltersCleared extends HeadlinesFeedEvent {}
