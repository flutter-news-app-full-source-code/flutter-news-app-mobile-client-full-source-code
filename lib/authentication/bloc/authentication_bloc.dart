import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart'; // Import for Logger

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
      _logger = Logger('AuthenticationBloc'), // Initialize logger
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
    on<AuthenticationFlowReset>(_onAuthenticationFlowReset);
  }

  final AuthRepository _authenticationRepository;
  final Logger _logger; // Declare logger
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
    _logger.info(
      '[_onAuthenticationUserChanged] Event received. '
      'Old User ID: ${state.user?.id}, New User ID: ${event.user?.id}. '
      'Current AuthFlow: ${state.flow}.',
    );

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
      _logger.info(
        '[_onAuthenticationUserChanged] User authenticated. '
        'New state status: ${state.status}, New AuthFlow: ${state.flow}.',
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
      _logger.info(
        '[_onAuthenticationUserChanged] User unauthenticated. '
        'New state status: ${state.status}, New AuthFlow: ${state.flow}.',
      );
    }
  }

  /// Handles [AuthenticationRequestSignInCodeRequested] events.
  Future<void> _onAuthenticationRequestSignInCodeRequested(
    AuthenticationRequestSignInCodeRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    _logger.info(
      '[_onAuthenticationRequestSignInCodeRequested] Event received. '
      'Requesting sign-in code for email: ${event.email}. '
      'Current AuthFlow: ${state.flow}.',
    );
    if (state.cooldownEndTime != null &&
        state.cooldownEndTime!.isAfter(DateTime.now())) {
      _logger.warning(
        '[_onAuthenticationRequestSignInCodeRequested] Cooldown active. '
        'Skipping request for email: ${event.email}. '
        'Cooldown ends at: ${state.cooldownEndTime}.',
      );
      return;
    }

    emit(state.copyWith(status: AuthenticationStatus.requestCodeInProgress));
    _logger.info(
      '[_onAuthenticationRequestSignInCodeRequested] Status set to requestCodeInProgress. '
      'Current AuthFlow: ${state.flow}.',
    );
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
      _logger.info(
        '[_onAuthenticationRequestSignInCodeRequested] Sign-in code requested successfully for email: ${event.email}. '
        'Status set to requestCodeSuccess. Cooldown ends at: $cooldownEndTime. '
        'Current AuthFlow: ${state.flow}.',
      );

      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(
        _requestCodeCooldownDuration,
        () => add(const AuthenticationCooldownCompleted()),
      );
    } on HttpException catch (e) {
      _logger.severe(
        '[_onAuthenticationRequestSignInCodeRequested] Failed to request sign-in code for email: ${event.email}. '
        'Exception: ${e.runtimeType} - ${e.message}. '
        'Current AuthFlow: ${state.flow}.',
      );
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      _logger.severe(
        '[_onAuthenticationRequestSignInCodeRequested] Unexpected error requesting sign-in code for email: ${event.email}. '
        'Error: $e. '
        'Current AuthFlow: ${state.flow}.',
      );
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
    _logger.info(
      '[_onAuthenticationVerifyCodeRequested] Event received. '
      'Verifying code for email: ${event.email}. '
      'Current AuthFlow: ${state.flow}.',
    );
    emit(state.copyWith(status: AuthenticationStatus.loading));
    _logger.info(
      '[_onAuthenticationVerifyCodeRequested] Status set to loading. '
      'Current AuthFlow: ${state.flow}.',
    );
    try {
      await _authenticationRepository.verifySignInCode(event.email, event.code);
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting the authenticated state.
      // Also, explicitly reset the flow to signIn after successful verification.
      emit(state.copyWith(flow: AuthFlow.signIn));
      _logger.info(
        '[_onAuthenticationVerifyCodeRequested] Code verified successfully for email: ${event.email}. '
        'AuthFlow reset to: ${state.flow}.',
      );
    } on HttpException catch (e) {
      _logger.severe(
        '[_onAuthenticationVerifyCodeRequested] Failed to verify code for email: ${event.email}. '
        'Exception: ${e.runtimeType} - ${e.message}. '
        'Current AuthFlow: ${state.flow}.',
      );
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      _logger.severe(
        '[_onAuthenticationVerifyCodeRequested] Unexpected error verifying code for email: ${event.email}. '
        'Error: $e. '
        'Current AuthFlow: ${state.flow}.',
      );
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
    _logger.info(
      '[_onAuthenticationAnonymousSignInRequested] Event received. '
      'Anonymous sign-in requested. Current AuthFlow: ${state.flow}.',
    );
    emit(state.copyWith(status: AuthenticationStatus.loading));
    _logger.info(
      '[_onAuthenticationAnonymousSignInRequested] Status set to loading. '
      'Current AuthFlow: ${state.flow}.',
    );
    try {
      await _authenticationRepository.signInAnonymously();
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting the authenticated state.
      // Also, explicitly reset the flow to signIn after successful anonymous sign-in.
      emit(state.copyWith(flow: AuthFlow.signIn));
      _logger.info(
        '[_onAuthenticationAnonymousSignInRequested] Anonymous sign-in successful. '
        'AuthFlow reset to: ${state.flow}.',
      );
    } on HttpException catch (e) {
      _logger.severe(
        '[_onAuthenticationAnonymousSignInRequested] Failed anonymous sign-in. '
        'Exception: ${e.runtimeType} - ${e.message}. '
        'Current AuthFlow: ${state.flow}.',
      );
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      _logger.severe(
        '[_onAuthenticationAnonymousSignInRequested] Unexpected error during anonymous sign-in. '
        'Error: $e. '
        'Current AuthFlow: ${state.flow}.',
      );
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
    _logger.info(
      '[_onAuthenticationSignOutRequested] Event received. '
      'Sign-out requested. Current AuthFlow: ${state.flow}.',
    );
    emit(state.copyWith(status: AuthenticationStatus.loading));
    _logger.info(
      '[_onAuthenticationSignOutRequested] Status set to loading. '
      'Current AuthFlow: ${state.flow}.',
    );
    try {
      await _authenticationRepository.signOut();
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting the unauthenticated state.
      // Also, explicitly reset the flow to signIn.
      emit(state.copyWith(flow: AuthFlow.signIn));
      _logger.info(
        '[_onAuthenticationSignOutRequested] Sign-out successful. '
        'AuthFlow reset to: ${state.flow}.',
      );
    } on HttpException catch (e) {
      _logger.severe(
        '[_onAuthenticationSignOutRequested] Failed to sign out. '
        'Exception: ${e.runtimeType} - ${e.message}. '
        'Current AuthFlow: ${state.flow}.',
      );
      emit(state.copyWith(status: AuthenticationStatus.failure, exception: e));
    } catch (e) {
      _logger.severe(
        '[_onAuthenticationSignOutRequested] Unexpected error during sign-out. '
        'Error: $e. '
        'Current AuthFlow: ${state.flow}.',
      );
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
    _logger.info(
      '[_onAuthenticationCooldownCompleted] Event received. '
      'Cooldown completed. Current AuthFlow: ${state.flow}.',
    );
    emit(
      state.copyWith(
        status: AuthenticationStatus.initial,
        clearCooldownEndTime: true,
      ),
    );
    _logger.info(
      '[_onAuthenticationCooldownCompleted] Status set to initial, cooldown cleared. '
      'Current AuthFlow: ${state.flow}.',
    );
  }

  /// Handles [AuthenticationLinkingInitiated] events.
  ///
  /// Sets the authentication flow to `linkAccount`. This is dispatched by the
  /// UI (e.g., `AccountPage`) when an anonymous user explicitly chooses to
  /// link their account, signaling the `AuthenticationBloc` to prepare for
  /// the account linking process.
  void _onAuthenticationLinkingInitiated(
    AuthenticationLinkingInitiated event,
    Emitter<AuthenticationState> emit,
  ) {
    _logger.info(
      '[_onAuthenticationLinkingInitiated] Event received. '
      'Account linking initiated. Setting flow to AuthFlow.linkAccount. '
      'Previous AuthFlow: ${state.flow}.',
    );
    emit(state.copyWith(flow: AuthFlow.linkAccount));
    _logger.info(
      '[_onAuthenticationLinkingInitiated] AuthFlow updated to: ${state.flow}.',
    );
  }

  /// Handles [AuthenticationFlowReset] events.
  ///
  /// Resets the authentication flow to `signIn`. This is used to ensure
  /// a clean state for the authentication UI when it is dismissed or
  /// after a successful authentication flow (e.g., account linking).
  void _onAuthenticationFlowReset(
    AuthenticationFlowReset event,
    Emitter<AuthenticationState> emit,
  ) {
    _logger.info(
      '[_onAuthenticationFlowReset] Event received. '
      'Resetting authentication flow to signIn. Previous AuthFlow: ${state.flow}.',
    );
    emit(state.copyWith(flow: AuthFlow.signIn));
    _logger.info(
      '[_onAuthenticationFlowReset] AuthFlow reset to: ${state.flow}.',
    );
  }
}
