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

  /// Fetching the essential RemoteConfig.
  configFetching,

  /// Fetching the essential RemoteConfig failed.
  configFetchFailed,

  /// A new version of the app is required.
  updateRequired,

  /// The app is currently under maintenance.
  underMaintenance,
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
    this.status = AppStatus.initial, // Changed from AppStatus
    this.user,
    this.locale = const Locale('en'), // Default to English
    this.remoteConfig,
    this.environment,
    this.pageTransitionCount = 0, // New field for tracking page transitions
    required this.showInterstitialAdStream, // New stream for interstitial ad signals
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
  final Locale locale;

  /// The global application configuration (remote config).
  final RemoteConfig? remoteConfig;

  /// The current application environment (e.g., production, development, demo).
  final local_config.AppEnvironment? environment;

  /// Tracks the number of page transitions since the last interstitial ad was shown.
  /// This count is used to determine when to display an interstitial ad.
  final int pageTransitionCount;

  /// A stream that emits a signal when an interstitial ad should be shown.
  ///
  /// This stream is used by the [AdNavigatorObserver] to trigger the display
  /// of interstitial ads based on the [AppBloc]'s logic.
  final Stream<void> showInterstitialAdStream;

  /// Creates a copy of the current state with updated values.
  AppState copyWith({
    int? selectedBottomNavigationIndex,
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    String? fontFamily,
    AppTextScaleFactor? appTextScaleFactor,
    AppStatus? status, // Changed from AppStatus
    User? user,
    UserAppSettings? settings,
    Locale? locale,
    RemoteConfig? remoteConfig,
    local_config.AppEnvironment? environment,
    int? pageTransitionCount, // New parameter for pageTransitionCount
    Stream<void>? showInterstitialAdStream, // New parameter for the stream
    bool clearFontFamily = false,
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
      locale: locale ?? this.locale,
      remoteConfig: clearAppConfig ? null : remoteConfig ?? this.remoteConfig,
      environment: clearEnvironment ? null : environment ?? this.environment,
      pageTransitionCount: pageTransitionCount ?? this.pageTransitionCount,
      showInterstitialAdStream:
          showInterstitialAdStream ?? this.showInterstitialAdStream,
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
    remoteConfig,
    environment,
    pageTransitionCount,
    showInterstitialAdStream, // Include in props
  ];
}
