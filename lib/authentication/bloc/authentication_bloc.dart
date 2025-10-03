import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

const _requestCodeCooldownDuration = Duration(seconds: 60);

/// {@template authentication_bloc}
/// Bloc responsible for managing the authentication state of the application.
/// {@endtemplate}
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  /// {@macro authentication_bloc}
  AuthenticationBloc({required AuthRepository authenticationRepository})
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
    on<AuthenticationCooldownCompleted>(_onAuthenticationCooldownCompleted);
    on<AuthenticationLinkingInitiated>(_onAuthenticationLinkingInitiated);
  }

  final AuthRepository _authenticationRepository;
  late final StreamSubscription<User?> _userAuthSubscription;
  Timer? _cooldownTimer;

  /// Handles [_AuthenticationUserChanged] events.
  ///
  /// Updates the authentication status and user, and resets the authentication
  /// flow to `signIn` if the user becomes unauthenticated.
  Future<void> _onAuthenticationUserChanged(
    _AuthenticationUserChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (event.user != null) {
      emit(
        state.copyWith(
          status: AuthenticationStatus.authenticated,
          user: event.user,
          // When a user is authenticated, ensure the flow is reset to signIn
          // unless it's explicitly a linking flow that just completed.
          // For now, we reset to signIn as the linking context is handled
          // by the router redirect.
          flow: AuthFlow.signIn,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthenticationStatus.unauthenticated,
          user: null,
          // When a user logs out, reset the flow to standard sign-in.
          flow: AuthFlow.signIn,
        ),
      );
    }
  }

  /// Handles [AuthenticationRequestSignInCodeRequested] events.
  Future<void> _onAuthenticationRequestSignInCodeRequested(
    AuthenticationRequestSignInCodeRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (state.cooldownEndTime != null &&
        state.cooldownEndTime!.isAfter(DateTime.now())) {
      return;
    }

    emit(state.copyWith(status: AuthenticationStatus.requestCodeInProgress));
    try {
      await _authenticationRepository.requestSignInCode(event.email);
      final cooldownEndTime = DateTime.now().add(_requestCodeCooldownDuration);
      emit(
        state.copyWith(
          status: AuthenticationStatus.requestCodeSuccess,
          email: event.email,
          cooldownEndTime: cooldownEndTime,
        ),
      );

      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(
        _requestCodeCooldownDuration,
        () => add(const AuthenticationCooldownCompleted()),
      );
    } on HttpException catch (e) {
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
    } on HttpException catch (e) {
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
    } on HttpException catch (e) {
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
  ///
  /// Resets the authentication flow to `signIn` upon sign-out.
  Future<void> _onAuthenticationSignOutRequested(
    AuthenticationSignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    try {
      await _authenticationRepository.signOut();
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting the unauthenticated state.
      // Also, explicitly reset the flow to signIn.
      emit(state.copyWith(flow: AuthFlow.signIn));
    } on HttpException catch (e) {
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
    _cooldownTimer?.cancel();
    return super.close();
  }

  void _onAuthenticationCooldownCompleted(
    AuthenticationCooldownCompleted event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(
      state.copyWith(
        status: AuthenticationStatus.initial,
        clearCooldownEndTime: true,
      ),
    );
  }

  /// Handles [AuthenticationLinkingInitiated] events.
  ///
  /// Sets the authentication flow to `linkAccount`.
  void _onAuthenticationLinkingInitiated(
    AuthenticationLinkingInitiated event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(state.copyWith(flow: AuthFlow.linkAccount));
  }
}
