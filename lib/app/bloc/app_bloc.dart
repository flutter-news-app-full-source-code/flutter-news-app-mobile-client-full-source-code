import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<AppNavigationIndexChanged>((event, emit) {
      emit(state.copyWith(selectedBottomNavigationIndex: event.index));
    });
    on<AppThemeChanged>((event, emit) {
      emit(
        state.copyWith(
          themeMode: state.themeMode == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );
    });
  }
}
