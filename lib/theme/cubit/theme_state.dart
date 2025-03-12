part of 'theme_cubit.dart';

abstract class ThemeState {
  final ThemeData themeData;

  const ThemeState({required this.themeData});
}

class LightThemeState extends ThemeState {
  LightThemeState() : super(themeData: lightTheme());
}

class DarkThemeState extends ThemeState {
  DarkThemeState() : super(themeData: darkTheme());
}
