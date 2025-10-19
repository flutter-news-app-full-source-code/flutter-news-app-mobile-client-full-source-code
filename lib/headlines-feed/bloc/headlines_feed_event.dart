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

/// {@template headlines_feed_started}
/// Dispatched once when the [HeadlinesFeedPage] is first initialized to
/// trigger the initial loading of the feed content.
///
/// This explicit event makes the initial data fetch declarative and robust,
/// removing the dependency on observing `AppBloc` state transitions which
/// could lead to race conditions.
/// {@endtemplate}
final class HeadlinesFeedStarted extends HeadlinesFeedEvent {
  /// {@macro headlines_feed_started}
  const HeadlinesFeedStarted({required this.adThemeStyle});

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [adThemeStyle];
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
  const HeadlinesFeedFetchRequested({required this.adThemeStyle, this.cursor});

  /// The cursor indicating the starting point for the next page of headlines.
  /// If null, fetches the first page.
  final String? cursor;

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object?> get props => [cursor, adThemeStyle];
}

/// {@template headlines_feed_refresh_requested}
/// Event triggered when the user requests a manual refresh of the headlines feed
/// (e.g., via pull-to-refresh). This should fetch the first page using the
/// currently active filters.
/// {@endtemplate}
final class HeadlinesFeedRefreshRequested extends HeadlinesFeedEvent {
  const HeadlinesFeedRefreshRequested({required this.adThemeStyle});

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [adThemeStyle];
}

/// {@template headlines_feed_filters_applied}
/// Event triggered when a new set of filters, selected by the user,
/// should be applied to the headlines feed.
/// {@endtemplate}
/// The `activeFilterId` is determined within the `HeadlinesFeedBloc`.
/// In most cases, this is done by comparing the applied filter against the
/// list of saved filters. However, to prevent a race condition during the
/// "save and apply" flow, an optional `savedFilter` can be provided to
/// ensure the newly created filter is selected immediately.
final class HeadlinesFeedFiltersApplied extends HeadlinesFeedEvent {
  /// {@macro headlines_feed_filters_applied}
  ///
  /// Contains the complete [HeadlineFilter] configuration to be applied.
  const HeadlinesFeedFiltersApplied({
    required this.filter,
    required this.adThemeStyle,
    this.savedFilter,
  });

  /// The [HeadlineFilter] containing the selected categories, sources,
  /// and/or countries.
  final HeadlineFilter filter;

  /// The optional [SavedFilter] that this filter corresponds to.
  /// This is used exclusively during the "save and apply" flow to prevent
  /// a race condition and ensure the new filter's chip is selected.
  final SavedFilter? savedFilter;

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object?> get props => [filter, adThemeStyle, savedFilter];
}

/// {@template headlines_feed_filters_cleared}
/// Event triggered when the user requests to clear all active filters
/// and view the unfiltered headlines feed.
/// {@endtemplate}
final class HeadlinesFeedFiltersCleared extends HeadlinesFeedEvent {
  const HeadlinesFeedFiltersCleared({required this.adThemeStyle});

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [adThemeStyle];
}

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

/// {@template navigation_handled}
/// Event triggered after a navigation action has been handled by the UI.
/// This is used to clear the navigationUrl from the state.
/// {@endtemplate}
final class NavigationHandled extends HeadlinesFeedEvent {}

/// {@template saved_filter_selected}
/// Event triggered when a user selects a saved filter from the filter bar.
/// {@endtemplate}
final class SavedFilterSelected extends HeadlinesFeedEvent {
  /// {@macro saved_filter_selected}
  const SavedFilterSelected({required this.filter, required this.adThemeStyle});

  /// The saved filter that was selected.
  final SavedFilter filter;

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [filter, adThemeStyle];
}

/// {@template all_filter_selected}
/// Event triggered when the user selects the "All" filter from the filter bar.
/// {@endtemplate}
final class AllFilterSelected extends HeadlinesFeedEvent {
  /// {@macro all_filter_selected}
  const AllFilterSelected({required this.adThemeStyle});

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [adThemeStyle];
}

/// {@template followed_filter_selected}
/// Event triggered when the user selects the "Followed" filter from the
/// filter bar.
/// {@endtemplate}
final class FollowedFilterSelected extends HeadlinesFeedEvent {
  /// {@macro followed_filter_selected}
  const FollowedFilterSelected({required this.adThemeStyle});

  /// The current ad theme style of the application.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [adThemeStyle];
}

/// Internal event to notify the bloc of changes in user content preferences.
final class _AppContentPreferencesChanged extends HeadlinesFeedEvent {
  const _AppContentPreferencesChanged({required this.preferences});

  final UserContentPreferences preferences;

  @override
  List<Object> get props => [preferences];
}
