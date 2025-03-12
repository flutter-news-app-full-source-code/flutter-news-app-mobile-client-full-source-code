import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:ht_main/theme/theme.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(LightThemeState());

  void toggleTheme() {
    emit(state is LightThemeState ? DarkThemeState() : LightThemeState());
  }
}
