//
// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_authentication_client/ht_authentication_client.dart';
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
    // Remove kvStorageService from constructor
  }) : _authenticationRepository = authenticationRepository,
       super(AuthenticationInitial()) {
    on<AuthenticationSendSignInLinkRequested>(
      _onAuthenticationSendSignInLinkRequested,
    );
    on<AuthenticationSignInWithLinkAttempted>(
      _onAuthenticationSignInWithLinkAttempted,
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

  /// Handles [AuthenticationSendSignInLinkRequested] events.
  Future<void> _onAuthenticationSendSignInLinkRequested(
    AuthenticationSendSignInLinkRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    // Validate email format (basic check)
    if (event.email.isEmpty || !event.email.contains('@')) {
      emit(const AuthenticationFailure('Please enter a valid email address.'));
      return;
    }
    emit(AuthenticationLinkSending()); // Indicate link sending
    try {
      // Simply call the repository method, email temprary storage storage
      // is handled internally
      await _authenticationRepository.sendSignInLinkToEmail(email: event.email);
      emit(AuthenticationLinkSentSuccess()); // Confirm link sent
    } on SendSignInLinkException catch (e) {
      emit(AuthenticationFailure('Failed to send link: ${e.error}'));
    } catch (e) {
      // Catch any other unexpected errors
      emit(AuthenticationFailure('An unexpected error occurred: $e'));
      // Optionally log the stackTrace here
    }
  }

  /// Handles [AuthenticationSignInWithLinkAttempted] events.
  /// This assumes the event is dispatched after the app receives the deep link.
  Future<void> _onAuthenticationSignInWithLinkAttempted(
    AuthenticationSignInWithLinkAttempted event, // Event no longer has email
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading()); // General loading for sign-in attempt
    try {
      // Call the updated repository method (no email needed here)
      await _authenticationRepository.signInWithEmailLink(
        emailLink: event.emailLink,
      );
      // On success, AppBloc should react to the user stream change from the repo.
      // Resetting to Initial state here.
      emit(AuthenticationInitial());
    } on InvalidSignInLinkException catch (e) {
      emit(
        AuthenticationFailure(
          'Sign in failed: Invalid or expired link. ${e.error}',
        ),
      );
    } catch (e) {
      // Catch any other unexpected errors
      emit(
        AuthenticationFailure(
          'An unexpected error occurred during sign in: $e',
        ),
      );
      // Optionally log the stackTrace here
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
