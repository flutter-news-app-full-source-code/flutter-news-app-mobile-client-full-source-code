import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_authentication_firebase/ht_authentication_firebase.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// {@template authentication_bloc}
/// Bloc responsible for managing the authentication state of the application.
/// {@endtemplate}
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  /// {@macro authentication_bloc}
  AuthenticationBloc({
    required HtAuthenticationRepository authenticationRepository,
  })  : _authenticationRepository = authenticationRepository,
        super(AuthenticationInitial()) {
    on<AuthenticationEmailSignInRequested>(
      _onAuthenticationEmailSignInRequested,
    );
    on<AuthenticationGoogleSignInRequested>(
      _onAuthenticationGoogleSignInRequested,
    );
    on<AuthenticationAnonymousSignInRequested>(
      _onAuthenticationAnonymousSignInRequested,
    );
    on<AuthenticationSignOutRequested>(_onAuthenticationSignOutRequested);
    on<AuthenticationDeleteAccountRequested>(
      _onAuthenticationDeleteAccountRequested,
    );
  }

  final HtAuthenticationRepository _authenticationRepository;

  /// Handles [AuthenticationEmailSignInRequested] events.
  Future<void> _onAuthenticationEmailSignInRequested(
    AuthenticationEmailSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());
    try {
      await _authenticationRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthenticationInitial());
    } on EmailSignInException catch (e) {
      emit(AuthenticationFailure(e.toString()));
    } catch (e) {
      emit(AuthenticationFailure(e.toString()));
    }
  }

  /// Handles [AuthenticationGoogleSignInRequested] events.
  Future<void> _onAuthenticationGoogleSignInRequested(
    AuthenticationGoogleSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());
    try {
      await _authenticationRepository.signInWithGoogle();
      emit(AuthenticationInitial());
    } on GoogleSignInException catch (e) {
      emit(AuthenticationFailure(e.toString()));
    } catch (e) {
      emit(AuthenticationFailure(e.toString()));
    }
  }

  /// Handles [AuthenticationAnonymousSignInRequested] events.
  Future<void> _onAuthenticationAnonymousSignInRequested(
    AuthenticationAnonymousSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());
    try {
      await _authenticationRepository.signInAnonymously();
      emit(AuthenticationInitial());
    } on AnonymousLoginException catch (e) {
      emit(AuthenticationFailure(e.toString()));
    } catch (e) {
      emit(AuthenticationFailure(e.toString()));
    }
  }

  /// Handles [AuthenticationSignOutRequested] events.
  Future<void> _onAuthenticationSignOutRequested(
    AuthenticationSignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());
    try {
      await _authenticationRepository.signOut();
      emit(AuthenticationInitial());
    } on LogoutException catch (e) {
      emit(AuthenticationFailure(e.toString()));
    } catch (e) {
      emit(AuthenticationFailure(e.toString()));
    }
  }

  Future<void> _onAuthenticationDeleteAccountRequested(
    AuthenticationDeleteAccountRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading());
    try {
      await _authenticationRepository.deleteAccount();
      emit(AuthenticationInitial());
    } on DeleteAccountException catch (e) {
      emit(AuthenticationFailure(e.toString()));
    } catch (e) {
      emit(AuthenticationFailure(e.toString()));
    }
  }
}
