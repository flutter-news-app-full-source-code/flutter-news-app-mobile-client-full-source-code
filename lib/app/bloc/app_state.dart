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
}

class AppState extends Equatable {
  /// {@macro app_state}
  const AppState({
    required this.settings, // Add settings property
    required this.selectedBottomNavigationIndex,
    this.themeMode = ThemeMode.system,
    this.appTextScaleFactor =
        AppTextScaleFactor.medium, // Default text scale factor (enum)
    this.flexScheme = FlexScheme.material,
    this.fontFamily,
    this.status = AppStatus.initial,
    this.user, // User is now nullable and defaults to null
    this.locale, // Added locale
  });

  /// The index of the currently selected item in the bottom navigation bar.
  final int selectedBottomNavigationIndex;

  /// The overall theme mode (light, dark, system).
  final ThemeMode themeMode;

  /// The text scale factor for the app's UI.
  final AppTextScaleFactor appTextScaleFactor; // Change type to enum

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
  final UserAppSettings settings; // Add settings property

  /// The current application locale.
  final Locale? locale; // Added locale

  /// Creates a copy of the current state with updated values.
  AppState copyWith({
    int? selectedBottomNavigationIndex,
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    String? fontFamily,
    AppTextScaleFactor? appTextScaleFactor, // Change type to enum
    AppStatus? status,
    User? user,
    UserAppSettings? settings, // Add settings to copyWith
    Locale? locale, // Added locale
    bool clearFontFamily = false,
    bool clearLocale = false, // Added to allow clearing locale
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
      settings: settings ?? this.settings, // Copy settings
      locale: clearLocale ? null : locale ?? this.locale, // Added locale
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
    settings, // Include settings in props
    locale, // Added locale to props
  ];
}
