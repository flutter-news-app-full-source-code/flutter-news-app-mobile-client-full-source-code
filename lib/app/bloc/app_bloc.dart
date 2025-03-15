import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/router/routes.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<AppNavigationIndexChanged>(_onAppNavigationIndexChanged);
    on<AppThemeChanged>(_onAppThemeChanged);
  }

  void _onAppNavigationIndexChanged(
    AppNavigationIndexChanged event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(selectedBottomNavigationIndex: event.index));
    event.context.goNamed(Routes.getRouteNameByIndex(event.index));
  }

  void _onAppThemeChanged(
    AppThemeChanged event,
    Emitter<AppState> emit,
  ) {
    emit(
      state.copyWith(
        themeMode: state.themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }
}
