import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ht_authentication_firebase/ht_authentication_firebase.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({required HtAuthenticationRepository authenticationRepository})
      : _authenticationRepository = authenticationRepository,
        super(const AppState()) {
    on<AppNavigationIndexChanged>(_onAppNavigationIndexChanged);
    on<AppThemeChanged>(_onAppThemeChanged);
    on<AppUserChanged>(_onAppUserChanged);

    _userSubscription = _authenticationRepository.user.listen(
      (user) => add(AppUserChanged(user)),
    );
  }

  final HtAuthenticationRepository _authenticationRepository;
  late final StreamSubscription<User> _userSubscription;

  void _onAppNavigationIndexChanged(
    AppNavigationIndexChanged event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(selectedBottomNavigationIndex: event.index));
    // event.context.goNamed(Routes.getRouteNameByIndex(event.index)); // Removed direct navigation
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

  void _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) {
    if (event.user.isAnonymous) {
      emit(state.copyWith(status: AppStatus.unauthenticated));
    } else {
      emit(state.copyWith(status: AppStatus.authenticated));
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
