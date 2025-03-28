import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({required HtAuthenticationRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(AppState()) {
    on<AppThemeChanged>(_onAppThemeChanged);
    on<AppUserChanged>(_onAppUserChanged);

    _userSubscription = _authenticationRepository.user.listen(
      (user) => add(AppUserChanged(user)),
    );
  }

  final HtAuthenticationRepository _authenticationRepository;
  late final StreamSubscription<User> _userSubscription;

  void _onAppThemeChanged(AppThemeChanged event, Emitter<AppState> emit) {
    emit(
      state.copyWith(
        themeMode:
            state.themeMode == ThemeMode.system
                ? ThemeMode.system
                : state.themeMode == ThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.light,
      ),
    );
  }

  void _onAppUserChanged(AppUserChanged event, Emitter<AppState> emit) {
    // Determine the AppStatus based on the user's AuthenticationStatus
    final AppStatus status;
    switch (event.user.authenticationStatus) {
      case AuthenticationStatus.unauthenticated:
        status = AppStatus.unauthenticated;
      case AuthenticationStatus.anonymous:
        status = AppStatus.anonymous;
      case AuthenticationStatus.authenticated:
        status = AppStatus.authenticated;
      // Or handle as error
    }
    // Emit the new state including both the updated status and the user object
    emit(state.copyWith(status: status, user: event.user));
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
