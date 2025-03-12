part of 'app_bloc.dart';

class AppState extends Equatable {
  const AppState({
    this.selectedBottomNavigationIndex = 0,
    this.themeMode = ThemeMode.system,
  });
  final int selectedBottomNavigationIndex;
  final ThemeMode themeMode;

  AppState copyWith({
    int? selectedBottomNavigationIndex,
    ThemeMode? themeMode,
  }) {
    return AppState(
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [selectedBottomNavigationIndex, themeMode];
}
