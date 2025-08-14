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

/// {@template feed_decorator_dismissed}
/// Event triggered when a user dismisses a feed decorator.
/// {@endtemplate}
final class FeedDecoratorDismissed extends HeadlinesFeedEvent {
  /// {@macro feed_decorator_dismissed}
  const FeedDecoratorDismissed({required this.feedDecoratorType});

  /// The type of the decorator that was dismissed.
  final FeedDecoratorType feedDecoratorType;

  @override
  List<Object> get props => [feedDecoratorType];
}

/// {@template suggested_item_follow_toggled}
/// Event triggered when a user toggles the follow status of a suggested item.
/// {@endtemplate}
final class SuggestedItemFollowToggled extends HeadlinesFeedEvent {
  /// {@macro suggested_item_follow_toggled}
  const SuggestedItemFollowToggled({
    required this.item,
    required this.isFollowing,
  });

  /// The [FeedItem] (Topic or Source) whose follow status was toggled.
  final FeedItem item;

  /// The new follow status (true if now following, false if now unfollowing).
  final bool isFollowing;

  @override
  List<Object> get props => [item, isFollowing];
}

/// {@template call_to_action_tapped}
/// Event triggered when a user taps the call-to-action button on a decorator.
/// {@endtemplate}
final class CallToActionTapped extends HeadlinesFeedEvent {
  /// {@macro call_to_action_tapped}
  const CallToActionTapped({required this.url});

  /// The URL associated with the call-to-action.
  final String url;

  @override
  List<Object> get props => [url];
}
