import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

const _requestCodeCooldownDuration = Duration(seconds: 60);

/// {@template authentication_bloc}
/// Bloc responsible for managing the authentication state of the application.
/// {@endtemplate}
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  /// {@macro authentication_bloc}
  AuthenticationBloc({
    required AuthRepository authenticationRepository,
    required AnalyticsService analyticsService,
  }) : _authenticationRepository = authenticationRepository,
       _analyticsService = analyticsService,
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
  }

  final AuthRepository _authenticationRepository;
  final AnalyticsService _analyticsService;
  late final StreamSubscription<User?> _userAuthSubscription;
  Timer? _cooldownTimer;

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
      // On success, the authStateChanges stream will fire. The global AppBloc
      // listener will handle the entire post-login sequence.
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.userLogin,
          payload: const UserLoginPayload(authMethod: 'email'),
        ),
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

  /// Handles [AuthenticationAnonymousSignInRequested] events.
  Future<void> _onAuthenticationAnonymousSignInRequested(
    AuthenticationAnonymousSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    try {
      await _authenticationRepository.signInAnonymously();
      // On success, the authStateChanges stream will fire.
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.userLogin,
          payload: const UserLoginPayload(authMethod: 'anonymous'),
        ),
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
}
