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
  const AppState({
    this.selectedBottomNavigationIndex = 0,
    this.themeMode = ThemeMode.system,
    this.status = AppStatus.unauthenticated,
  });
  final int selectedBottomNavigationIndex;
  final ThemeMode themeMode;
  final AppStatus status;

  AppState copyWith({
    int? selectedBottomNavigationIndex,
    ThemeMode? themeMode,
    AppStatus? status,
  }) {
    return AppState(
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      themeMode: themeMode ?? this.themeMode,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [selectedBottomNavigationIndex, themeMode, status];
}
