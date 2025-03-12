part of 'theme_cubit.dart';

abstract class ThemeState {
  const ThemeState({required this.themeData});
  final ThemeData themeData;
}

class LightThemeState extends ThemeState {
  LightThemeState() : super(themeData: lightTheme());
}

class DarkThemeState extends ThemeState {
  DarkThemeState() : super(themeData: darkTheme());
}
