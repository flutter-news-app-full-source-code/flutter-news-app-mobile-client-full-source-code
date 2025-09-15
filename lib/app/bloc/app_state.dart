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
/// configuration, and UI-related preferences.
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
    this.themeMode = ThemeMode.system,
    this.flexScheme = FlexScheme.blue,
    this.fontFamily,
    this.appTextScaleFactor = AppTextScaleFactor.medium,
    this.selectedBottomNavigationIndex = 0,
    this.locale,
  });

  /// The current status of the application.
  final AppLifeCycleStatus status;

  /// The currently authenticated or anonymous user.
  final User? user;

  /// The user's application settings, including display preferences.
  /// This is null until successfully fetched from the backend.
  final UserAppSettings? settings;

  /// The remote configuration fetched from the backend.
  final RemoteConfig? remoteConfig;

  /// An error that occurred during the initial remote config fetch.
  final HttpException? initialRemoteConfigError;

  /// An error that occurred during the initial user preferences fetch.
  final HttpException? initialUserPreferencesError;

  /// The user's content preferences, including followed countries, sources, topics, and saved headlines.
  final UserContentPreferences? userContentPreferences;

  /// The current theme mode (light, dark, or system).
  final ThemeMode themeMode;

  /// The current FlexColorScheme scheme for accent colors.
  final FlexScheme flexScheme;

  /// The currently selected font family.
  final String? fontFamily;

  /// The current text scale factor.
  final AppTextScaleFactor appTextScaleFactor;

  /// The currently selected index for bottom navigation.
  final int selectedBottomNavigationIndex;

  /// The current application environment.
  final local_config.AppEnvironment environment;

  /// The currently selected locale for localization.
  final Locale? locale;

  @override
  List<Object?> get props => [
    status,
    user,
    settings,
    remoteConfig,
    initialRemoteConfigError,
    initialUserPreferencesError,
    userContentPreferences,
    themeMode,
    flexScheme,
    fontFamily,
    appTextScaleFactor,
    selectedBottomNavigationIndex,
    environment,
    locale,
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
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    String? fontFamily,
    AppTextScaleFactor? appTextScaleFactor,
    int? selectedBottomNavigationIndex,
    local_config.AppEnvironment? environment,
    Locale? locale,
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
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
      fontFamily: fontFamily ?? this.fontFamily,
      appTextScaleFactor: appTextScaleFactor ?? this.appTextScaleFactor,
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      environment: environment ?? this.environment,
      locale: locale ?? this.locale,
    );
  }
}
