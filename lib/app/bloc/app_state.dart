part of 'app_bloc.dart';

/// Represents the application's authentication status.
enum AppStatus {
  /// The application is initializing and the status is unknown.
  initial,

  /// The user is authenticated.
  authenticated,

  /// The user is not authenticated.
  unauthenticated,

  /// The user is anonymous (signed in using an anonymous provider).
  anonymous,
}

class AppState extends Equatable {
  /// {@macro app_state}
  AppState({
    this.selectedBottomNavigationIndex = 0,
    this.themeMode = ThemeMode.system,
    this.appFontSize = FontSize.medium, // Default font size
    this.flexScheme = FlexScheme.material,
    this.fontFamily,
    this.status = AppStatus.initial,
    User? user,
  }) : user = user ?? User();

  /// The index of the currently selected item in the bottom navigation bar.
  final int selectedBottomNavigationIndex;

  /// The overall theme mode (light, dark, system).
  final ThemeMode themeMode;

  /// The font size for the app's UI.
  final FontSize appFontSize;

  /// The active color scheme defined by FlexColorScheme.
  final FlexScheme flexScheme;

  /// The active font family name (e.g., from Google Fonts).
  /// Null uses the default font family defined in the FlexColorScheme theme.
  final String? fontFamily;

  /// The current authentication status of the application.
  final AppStatus status;

  /// The current user details. Defaults to an empty user.
  final User user;

  /// Creates a copy of the current state with updated values.
  AppState copyWith({
    int? selectedBottomNavigationIndex,
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    String? fontFamily,
    FontSize? appFontSize, // Added
    AppStatus? status,
    User? user,
    bool clearFontFamily = false,
  }) {
    return AppState(
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
      fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
      appFontSize: appFontSize ?? this.appFontSize, // Added
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
        selectedBottomNavigationIndex,
        themeMode,
        flexScheme,
        fontFamily,
        appFontSize, // Added
        status,
        user,
      ];
}
