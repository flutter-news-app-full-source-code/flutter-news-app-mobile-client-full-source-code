part of 'app_bloc.dart';

/// Represents the application's authentication status.
enum AppStatus {
  /// The application is initializing and the status is unknown.
  initial,

  /// The user is authenticated.
  authenticated,

  /// The user is unauthenticated.
  unauthenticated,

  /// The user is anonymous (signed in using an anonymous provider).
  anonymous,

  /// Fetching the essential AppConfig.
  configFetching,

  /// Fetching the essential AppConfig failed.
  configFetchFailed,
}

class AppState extends Equatable {
  /// {@macro app_state}
  const AppState({
    required this.settings,
    required this.selectedBottomNavigationIndex,
    this.themeMode = ThemeMode.system,
    this.appTextScaleFactor = AppTextScaleFactor.medium,
    this.flexScheme = FlexScheme.material,
    this.fontFamily,
    this.status = AppStatus.initial,
    this.user,
    this.locale,
    this.appConfig,
    this.environment,
  });

  /// The index of the currently selected item in the bottom navigation bar.
  final int selectedBottomNavigationIndex;

  /// The overall theme mode (light, dark, system).
  final ThemeMode themeMode;

  /// The text scale factor for the app's UI.
  final AppTextScaleFactor appTextScaleFactor;

  /// The active color scheme defined by FlexColorScheme.
  final FlexScheme flexScheme;

  /// The active font family name (e.g., from Google Fonts).
  /// Null uses the default font family defined in the FlexColorScheme theme.
  final String? fontFamily;

  /// The current authentication status of the application.
  final AppStatus status;

  /// The current user details. Null if unauthenticated.
  final User? user;

  /// User-specific application settings.
  final UserAppSettings settings;

  /// The current application locale.
  final Locale? locale;

  /// The global application configuration (remote config).
  final AppConfig? appConfig;

  /// The current application environment (e.g., production, development, demo).
  final local_config.AppEnvironment? environment;

  /// Creates a copy of the current state with updated values.
  AppState copyWith({
    int? selectedBottomNavigationIndex,
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    String? fontFamily,
    AppTextScaleFactor? appTextScaleFactor,
    AppStatus? status,
    User? user,
    UserAppSettings? settings,
    Locale? locale,
    AppConfig? appConfig,
    local_config.AppEnvironment? environment,
    bool clearFontFamily = false,
    bool clearLocale = false,
    bool clearAppConfig = false,
    bool clearEnvironment = false,
  }) {
    return AppState(
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
      fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
      appTextScaleFactor: appTextScaleFactor ?? this.appTextScaleFactor,
      status: status ?? this.status,
      user: user ?? this.user,
      settings: settings ?? this.settings,
      locale: clearLocale ? null : locale ?? this.locale,
      appConfig: clearAppConfig ? null : appConfig ?? this.appConfig,
      environment: clearEnvironment ? null : environment ?? this.environment,
    );
  }

  @override
  List<Object?> get props => [
    selectedBottomNavigationIndex,
    themeMode,
    flexScheme,
    fontFamily,
    appTextScaleFactor,
    status,
    user,
    settings,
    locale,
    appConfig,
    environment,
  ];
}
