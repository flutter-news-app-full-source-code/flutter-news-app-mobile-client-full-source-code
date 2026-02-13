part of 'app_bloc.dart';

/// {@template app_state}
/// Represents the overall state of the application.
///
/// This state is hydrated with pre-fetched data from the [AppInitializer].
/// This state includes authentication status, user settings, remote
/// configuration, and UI-related preferences. It acts as the single source
/// of truth for global application state.
/// {@endtemplate}
class AppState extends Equatable {
  /// {@macro app_state}
  const AppState({
    required this.status,
    this.user,
    this.userContext,
    this.remoteConfig,
    this.error,
    this.userContentPreferences,
    this.userRewards,
    this.settings,
    this.selectedBottomNavigationIndex = 0,
    this.currentAppVersion,
    this.latestAppVersion,
    this.hasUnreadInAppNotifications = false,
    this.positiveInteractionCount = 0,
    this.limitationStatus = LimitationStatus.allowed,
    this.limitedAction,
  });

  /// A factory constructor to determine the initial [AppLifeCycleStatus] based
  /// on the user and a potential onboarding requirement.
  factory AppState.fromOnboardingStatus({
    required User? user,
    required OnboardingStatus? onboardingStatus,
  }) {
    AppLifeCycleStatus status;
    if (onboardingStatus != null) {
      status = switch (onboardingStatus) {
        OnboardingStatus.preAuthTour =>
          AppLifeCycleStatus.preAuthOnboardingRequired,
        OnboardingStatus.postAuthPersonalization =>
          AppLifeCycleStatus.postAuthOnboardingRequired,
      };
    } else if (user == null) {
      status = AppLifeCycleStatus.unauthenticated;
    } else if (user.isAnonymous) {
      status = AppLifeCycleStatus.anonymous;
    } else {
      status = AppLifeCycleStatus.authenticated;
    }
    return AppState(status: status);
  }

  /// The current status of the application, indicating its lifecycle stage.
  final AppLifeCycleStatus status;

  /// The currently authenticated or anonymous user.
  /// Null if no user is logged in or recognized.
  final User? user;

  /// The user's context (ephemeral state like feed decorator status).
  final UserContext? userContext;

  /// The user's application settings, including display preferences and language.
  /// This is null until successfully fetched from the backend.
  final AppSettings? settings;

  /// The remote configuration fetched from the backend.
  /// Contains global settings like maintenance mode, update requirements, and ad configurations.
  final RemoteConfig? remoteConfig;

  /// An error that occurred during the initialization or a user transition.
  /// If not null, indicates a critical issue.
  final HttpException? error;

  /// The user's content preferences, including followed countries, sources,
  /// topics, and saved headlines.
  /// This is null until successfully fetched from the backend.
  final UserContentPreferences? userContentPreferences;

  /// The user's active rewards, if any.
  final UserRewards? userRewards;

  /// The currently selected index for bottom navigation.
  final int selectedBottomNavigationIndex;

  /// The current version of the application, fetched from `package_info_plus`.
  /// This is used for version enforcement.
  final String? currentAppVersion;

  /// The latest required app version, passed from [InitializationFailure].
  final String? latestAppVersion;

  /// A flag indicating if there are unread in-app notifications.
  final bool hasUnreadInAppNotifications;

  /// The number of positive interactions the user has performed in the session.
  final int positiveInteractionCount;

  /// The status of the most recent content limitation check.
  final LimitationStatus limitationStatus;

  /// The specific action that was limited, if any.
  final ContentAction? limitedAction;

  /// The current theme mode (light, dark, or system), derived from [settings].
  /// Defaults to [ThemeMode.system] if [settings] are not yet loaded.
  ThemeMode get themeMode {
    return settings?.displaySettings.baseTheme == AppBaseTheme.light
        ? ThemeMode.light
        : (settings?.displaySettings.baseTheme == AppBaseTheme.dark
              ? ThemeMode.dark
              : ThemeMode.system);
  }

  /// The current FlexColorScheme scheme for accent colors, derived from [settings].
  /// Defaults to [FlexScheme.blue] if [settings] are not yet loaded.
  FlexScheme get flexScheme {
    switch (settings?.displaySettings.accentTheme) {
      case AppAccentTheme.newsRed:
        return FlexScheme.red;
      case AppAccentTheme.graphiteGray:
        return FlexScheme.material;
      case AppAccentTheme.defaultBlue:
      case null:
        return FlexScheme.blue;
    }
  }

  /// The currently selected font family, derived from [settings].
  /// Returns null if 'SystemDefault' is selected or if [settings] are not yet loaded.
  String? get fontFamily {
    final family = settings?.displaySettings.fontFamily;
    return family == 'SystemDefault' ? null : family;
  }

  /// The current text scale factor, derived from [settings].
  /// Defaults to [AppTextScaleFactor.medium] if [settings] are not yet loaded.
  AppTextScaleFactor get appTextScaleFactor {
    return settings?.displaySettings.textScaleFactor ??
        AppTextScaleFactor.medium;
  }

  /// The current font weight, derived from [settings].
  /// Defaults to [AppFontWeight.regular] if [settings] are not yet loaded.
  AppFontWeight get appFontWeight {
    return settings?.displaySettings.fontWeight ?? AppFontWeight.regular;
  }

  /// The current feed item image style, derived from [settings].
  /// Defaults to [FeedItemImageStyle.smallThumbnail] if [settings] are not yet loaded.
  FeedItemImageStyle get feedItemImageStyle {
    return settings?.feedSettings.feedItemImageStyle ??
        FeedItemImageStyle.smallThumbnail;
  }

  /// The currently selected locale for localization, derived from [settings].
  /// Defaults to English ('en') if [settings] are not yet loaded.
  Locale get locale {
    return Locale(settings?.language.code ?? 'en');
  }

  @override
  List<Object?> get props => [
    status,
    user,
    userContext,
    settings,
    remoteConfig,
    error,
    userContentPreferences,
    userRewards,
    selectedBottomNavigationIndex,
    currentAppVersion,
    latestAppVersion,
    hasUnreadInAppNotifications,
    positiveInteractionCount,
  ];

  /// Creates a copy of this [AppState] with the given fields replaced with
  /// the new values.
  AppState copyWith({
    AppLifeCycleStatus? status,
    User? user,
    UserContext? userContext,
    AppSettings? settings,
    RemoteConfig? remoteConfig,
    HttpException? error,
    bool clearError = false,
    bool clearUser = false,
    UserContentPreferences? userContentPreferences,
    UserRewards? userRewards,
    int? selectedBottomNavigationIndex,
    String? currentAppVersion,
    String? latestAppVersion,
    bool? hasUnreadInAppNotifications,
    int? positiveInteractionCount,
    LimitationStatus? limitationStatus,
    ContentAction? limitedAction,
    bool clearLimitedAction = false,
  }) {
    return AppState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      userContext: clearUser ? null : userContext ?? this.userContext,
      settings: clearUser ? null : settings ?? this.settings,
      remoteConfig: remoteConfig ?? this.remoteConfig,
      error: clearError ? null : error ?? this.error,
      userContentPreferences: clearUser
          ? null
          : userContentPreferences ?? this.userContentPreferences,
      userRewards: clearUser ? null : userRewards ?? this.userRewards,
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      currentAppVersion: currentAppVersion ?? this.currentAppVersion,
      latestAppVersion: latestAppVersion ?? this.latestAppVersion,
      hasUnreadInAppNotifications:
          hasUnreadInAppNotifications ?? this.hasUnreadInAppNotifications,
      positiveInteractionCount:
          positiveInteractionCount ?? this.positiveInteractionCount,
      limitationStatus: limitationStatus ?? this.limitationStatus,
      limitedAction: clearLimitedAction
          ? null
          : limitedAction ?? this.limitedAction,
    );
  }
}
