part of 'app_bloc.dart';

/// Abstract base class for all events in the [AppBloc].
///
/// All concrete app events must extend this class.
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the application is first started and ready to load initial data.
///
/// This event triggers the initial data loading sequence, including fetching
/// user-specific settings and preferences.
class AppStarted extends AppEvent {
  const AppStarted({this.initialUser});

  /// The user object pre-fetched during bootstrap, if available.
  final User? initialUser;

  @override
  List<Object?> get props => [initialUser];
}

/// Dispatched when the authentication state changes (e.g., user logs in/out).
///
/// This event signals a change in the current user, prompting the [AppBloc]
/// to update its internal user state and potentially trigger data migration
/// or re-initialization.
class AppUserChanged extends AppEvent {
  const AppUserChanged(this.user);

  /// The new user object, or null if the user has logged out.
  final User? user;

  @override
  List<Object?> get props => [user];
}

/// Dispatched to request a refresh of the user's application settings.
///
/// This event is typically used when external changes might have occurred
/// or when a manual refresh of settings is desired.
class AppUserAppSettingsRefreshed extends AppEvent {
  const AppUserAppSettingsRefreshed();
}

/// Dispatched to request a refresh of the user's content preferences.
///
/// This event is typically used when external changes might have occurred
/// or when a manual refresh of preferences is desired.
class AppUserContentPreferencesRefreshed extends AppEvent {
  const AppUserContentPreferencesRefreshed();
}

/// Dispatched when the user's application settings have been updated.
///
/// This event carries the complete, updated [UserAppSettings] object,
/// allowing the [AppBloc] to update its state and persist the changes.
class AppSettingsChanged extends AppEvent {
  const AppSettingsChanged(this.settings);

  /// The updated [UserAppSettings] object.
  final UserAppSettings settings;

  @override
  List<Object?> get props => [settings];
}

/// Dispatched to fetch the remote application configuration periodically or
/// as a background check.
///
/// This event is used by services like [AppStatusService] to regularly
/// check for global app status changes (e.g., maintenance mode, forced updates)
/// without necessarily showing a loading UI.
class AppPeriodicConfigFetchRequested extends AppEvent {
  const AppPeriodicConfigFetchRequested({this.isBackgroundCheck = true});

  /// Whether this fetch is a silent background check.
  ///
  /// If `true`, the BLoC will not enter a visible loading state.
  /// If `false` (default), it's treated as an initial fetch that shows a
  /// loading UI.
  final bool isBackgroundCheck;

  @override
  List<Object> get props => [isBackgroundCheck];
}

/// Dispatched when the user logs out.
///
/// This event triggers the sign-out process, clearing authentication tokens
/// and resetting user-specific state.
class AppLogoutRequested extends AppEvent {
  const AppLogoutRequested();
}

/// Dispatched when a one-time user account decorator has been shown.
///
/// This event updates the user's interaction status with specific in-feed
/// decorators, allowing the app to track completion and display frequency.
class AppUserFeedDecoratorShown extends AppEvent {
  const AppUserFeedDecoratorShown({
    required this.userId,
    required this.feedDecoratorType,
    this.isCompleted = false,
  });

  /// The ID of the user for whom the decorator status is being updated.
  final String userId;

  /// The type of the feed decorator whose status is being updated.
  final FeedDecoratorType feedDecoratorType;

  /// A flag indicating whether the decorator action has been completed by the user.
  final bool isCompleted;

  @override
  List<Object> get props => [userId, feedDecoratorType, isCompleted];
}
