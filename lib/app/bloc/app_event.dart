part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the authentication state changes (e.g., user logs in/out).
class AppUserChanged extends AppEvent {
  const AppUserChanged(this.user);

  final User? user;

  @override
  List<Object?> get props => [user];
}

/// Dispatched to request a refresh of the user's application settings.
class AppSettingsRefreshed extends AppEvent {
  const AppSettingsRefreshed();
}

/// Dispatched to fetch the remote application configuration.
class AppConfigFetchRequested extends AppEvent {
  const AppConfigFetchRequested({this.isBackgroundCheck = false});

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
class AppLogoutRequested extends AppEvent {
  const AppLogoutRequested();
}

/// Dispatched when the theme mode (light/dark/system) changes.
class AppThemeModeChanged extends AppEvent {
  const AppThemeModeChanged(this.themeMode);
  final ThemeMode themeMode;
  @override
  List<Object> get props => [themeMode];
}

/// Dispatched when the accent color theme changes.
class AppFlexSchemeChanged extends AppEvent {
  const AppFlexSchemeChanged(this.flexScheme);
  final FlexScheme flexScheme;
  @override
  List<Object> get props => [flexScheme];
}

/// Dispatched when the font family changes.
class AppFontFamilyChanged extends AppEvent {
  const AppFontFamilyChanged(this.fontFamily);
  final String? fontFamily;
  @override
  List<Object?> get props => [fontFamily];
}

/// Dispatched when the text scale factor changes.
class AppTextScaleFactorChanged extends AppEvent {
  const AppTextScaleFactorChanged(this.appTextScaleFactor);
  final AppTextScaleFactor appTextScaleFactor;
  @override
  List<Object> get props => [appTextScaleFactor];
}

/// Dispatched when the font weight changes.
class AppFontWeightChanged extends AppEvent {
  const AppFontWeightChanged(this.fontWeight);
  final AppFontWeight fontWeight;
  @override
  List<Object> get props => [fontWeight];
}

/// Dispatched when a one-time user account decorator has been shown.
class AppUserFeedDecoratorShown extends AppEvent {
  const AppUserFeedDecoratorShown({
    required this.userId,
    required this.feedDecoratorType,
    this.isCompleted = false,
  });
  final String userId;
  final FeedDecoratorType feedDecoratorType;
  final bool isCompleted;
  @override
  List<Object> get props => [userId, feedDecoratorType, isCompleted];
}

/// Dispatched when a page transition occurs, used for tracking interstitial ad frequency.
class AppPageTransitioned extends AppEvent {
  const AppPageTransitioned();
}
