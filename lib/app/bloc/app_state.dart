part of 'app_bloc.dart';

/// Defines the various statuses of the application's overall state.
///
/// This enum helps manage the application's flow, especially during startup
/// and critical operations like fetching remote configuration or handling
/// authentication changes.
enum AppLifeCycleStatus {
  /// The application is currently loading user-specific data (settings, preferences).
  loadingUserData,

  /// The user is not authenticated.
  unauthenticated,

  /// The user is authenticated (e.g., standard user).
  authenticated,

  /// The user is anonymous (e.g., guest user).
  anonymous,

  /// A critical error occurred during application startup,
  /// preventing normal operation.
  criticalError,

  /// The application is currently under maintenance.
  underMaintenance,

  /// A mandatory update is required for the application.
  updateRequired,
}

/// {@template app_state}
/// Represents the overall state of the application.
///
/// This state includes authentication status, user settings, remote
/// configuration, and UI-related preferences. It acts as the single source
/// of truth for global application state.
/// {@endtemplate}
class AppState extends Equatable {
  /// {@macro app_state}
  const AppState({
    required this.status,
    required this.environment,
    this.user,
    this.remoteConfig,
    this.initialRemoteConfigError,
    this.initialUserPreferencesError,
    this.userContentPreferences,
    this.settings,
    this.selectedBottomNavigationIndex = 0,
  });

  /// The current status of the application, indicating its lifecycle stage.
  final AppLifeCycleStatus status;

  /// The currently authenticated or anonymous user.
  /// Null if no user is logged in or recognized.
  final User? user;

  /// The user's application settings, including display preferences and language.
  /// This is null until successfully fetched from the backend.
  final UserAppSettings? settings;

  /// The remote configuration fetched from the backend.
  /// Contains global settings like maintenance mode, update requirements, and ad configurations.
  final RemoteConfig? remoteConfig;

  /// An error that occurred during the initial remote config fetch.
  /// If not null, indicates a critical issue preventing app startup.
  final HttpException? initialRemoteConfigError;

  /// An error that occurred during the initial user preferences fetch.
  /// If not null, indicates a critical issue preventing app startup.
  final HttpException? initialUserPreferencesError;

  /// The user's content preferences, including followed countries, sources,
  /// topics, and saved headlines.
  /// This is null until successfully fetched from the backend.
  final UserContentPreferences? userContentPreferences;

  /// The currently selected index for bottom navigation.
  final int selectedBottomNavigationIndex;

  /// The current application environment (e.g., demo, development, production).
  final local_config.AppEnvironment environment;

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

  /// The current headline image style, derived from [settings].
  /// Defaults to [HeadlineImageStyle.smallThumbnail] if [settings] are not yet loaded.
  HeadlineImageStyle get headlineImageStyle {
    return settings?.feedPreferences.headlineImageStyle ??
        HeadlineImageStyle.smallThumbnail;
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
    settings,
    remoteConfig,
    initialRemoteConfigError,
    initialUserPreferencesError,
    userContentPreferences,
    selectedBottomNavigationIndex,
    environment,
  ];

  /// Creates a copy of this [AppState] with the given fields replaced with
  /// the new values.
  AppState copyWith({
    AppLifeCycleStatus? status,
    User? user,
    UserAppSettings? settings,
    RemoteConfig? remoteConfig,
    bool clearAppConfig = false,
    HttpException? initialRemoteConfigError,
    HttpException? initialUserPreferencesError,
    UserContentPreferences? userContentPreferences,
    int? selectedBottomNavigationIndex,
    local_config.AppEnvironment? environment,
  }) {
    return AppState(
      status: status ?? this.status,
      user: user ?? this.user,
      settings: settings ?? this.settings,
      remoteConfig: clearAppConfig ? null : remoteConfig ?? this.remoteConfig,
      initialRemoteConfigError:
          initialRemoteConfigError ?? this.initialRemoteConfigError,
      initialUserPreferencesError:
          initialUserPreferencesError ?? this.initialUserPreferencesError,
      userContentPreferences:
          userContentPreferences ?? this.userContentPreferences,
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      environment: environment ?? this.environment,
    );
  }
}
