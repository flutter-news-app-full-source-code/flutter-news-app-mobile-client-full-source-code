part of 'app_bloc.dart';

/// Represents the application's authentication status.
enum AppStatus {
  /// The user is authenticated.
  authenticated,

  /// The user is not authenticated.
  unauthenticated,

  /// The user is anonymous (signed in using an anonymous provider).
  anonymous,
}

class AppState extends Equatable {
  AppState({
    this.selectedBottomNavigationIndex = 0,
    this.themeMode = ThemeMode.system,
    this.status = AppStatus.unauthenticated,
    User? user,
  }) : user = user ?? User();

  final int selectedBottomNavigationIndex;
  final ThemeMode themeMode;
  final AppStatus status;
  final User user;

  AppState copyWith({
    int? selectedBottomNavigationIndex,
    ThemeMode? themeMode,
    AppStatus? status,
    User? user,
  }) {
    return AppState(
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      themeMode: themeMode ?? this.themeMode,
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
    selectedBottomNavigationIndex,
    themeMode,
    status,
    user,
  ];
}
