import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_shared/ht_shared.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// {@template authentication_bloc}
/// Bloc responsible for managing the authentication state of the application.
/// {@endtemplate}
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  /// {@macro authentication_bloc}
  AuthenticationBloc({required HtAuthRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(const AuthenticationState()) {
    // Listen to authentication state changes from the repository
    _userAuthSubscription = _authenticationRepository.authStateChanges.listen(
      (user) => add(_AuthenticationUserChanged(user: user)),
    );

    on<_AuthenticationUserChanged>(_onAuthenticationUserChanged);
    on<AuthenticationRequestSignInCodeRequested>(
      _onAuthenticationRequestSignInCodeRequested,
    );
    on<AuthenticationVerifyCodeRequested>(_onAuthenticationVerifyCodeRequested);
    on<AuthenticationAnonymousSignInRequested>(
      _onAuthenticationAnonymousSignInRequested,
    );
    on<AuthenticationSignOutRequested>(_onAuthenticationSignOutRequested);
  }

  final HtAuthRepository _authenticationRepository;
  late final StreamSubscription<User?> _userAuthSubscription;

  /// Handles [_AuthenticationUserChanged] events.
  Future<void> _onAuthenticationUserChanged(
    _AuthenticationUserChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (event.user != null) {
      emit(
        state.copyWith(
          status: AuthenticationStatus.authenticated,
          user: event.user,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthenticationStatus.unauthenticated,
          user: null,
        ),
      );
    }
  }

  /// Handles [AuthenticationRequestSignInCodeRequested] events.
  Future<void> _onAuthenticationRequestSignInCodeRequested(
    AuthenticationRequestSignInCodeRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.requestCodeInProgress));
    try {
      await _authenticationRepository.requestSignInCode(event.email);
      emit(
        state.copyWith(
          status: AuthenticationStatus.requestCodeSuccess,
          email: event.email,
        ),
      );
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          exception: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles [AuthenticationVerifyCodeRequested] events.
  Future<void> _onAuthenticationVerifyCodeRequested(
    AuthenticationVerifyCodeRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    try {
      await _authenticationRepository.verifySignInCode(event.email, event.code);
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting the authenticated state.
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          exception: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles [AuthenticationAnonymousSignInRequested] events.
  Future<void> _onAuthenticationAnonymousSignInRequested(
    AuthenticationAnonymousSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    try {
      await _authenticationRepository.signInAnonymously();
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting the authenticated state.
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          exception: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles [AuthenticationSignOutRequested] events.
  Future<void> _onAuthenticationSignOutRequested(
    AuthenticationSignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    try {
      await _authenticationRepository.signOut();
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting the unauthenticated state.
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          exception: UnknownException(e.toString()),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _userAuthSubscription.cancel();
    return super.close();
  }
}
