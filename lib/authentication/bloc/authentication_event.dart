part of 'authentication_bloc.dart';

/// {@template authentication_event}
/// Base class for authentication events.
/// {@endtemplate}
sealed class AuthenticationEvent extends Equatable {
  /// {@macro authentication_event}
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

/// {@template authentication_request_sign_in_code_requested}
/// Event triggered when the user requests a sign-in code to be sent
/// to their email.
/// {@endtemplate}
final class AuthenticationRequestSignInCodeRequested
    extends AuthenticationEvent {
  /// {@macro authentication_request_sign_in_code_requested}
  const AuthenticationRequestSignInCodeRequested({required this.email});

  /// The user's email address.
  final String email;

  @override
  List<Object> get props => [email];
}

/// {@template authentication_verify_code_requested}
/// Event triggered when the user attempts to sign in using an email and code.
/// {@endtemplate}
final class AuthenticationVerifyCodeRequested extends AuthenticationEvent {
  /// {@macro authentication_verify_code_requested}
  const AuthenticationVerifyCodeRequested({
    required this.email,
    required this.code,
  });

  /// The user's email address.
  final String email;

  /// The verification code received by the user.
  final String code;

  @override
  List<Object> get props => [email, code];
}

/// {@template authentication_anonymous_sign_in_requested}
/// Event triggered when the user requests to sign in anonymously.
/// {@endtemplate}
final class AuthenticationAnonymousSignInRequested extends AuthenticationEvent {
  /// {@macro authentication_anonymous_sign_in_requested}
  const AuthenticationAnonymousSignInRequested();
}

/// {@template authentication_sign_out_requested}
/// Event triggered when the user requests to sign out.
/// {@endtemplate}
final class AuthenticationSignOutRequested extends AuthenticationEvent {
  /// {@macro authentication_sign_out_requested}
  const AuthenticationSignOutRequested();
}

/// {@template _authentication_user_changed}
/// Internal event triggered when the authentication state changes.
/// {@endtemplate}
final class _AuthenticationUserChanged extends AuthenticationEvent {
  /// {@macro _authentication_user_changed}
  const _AuthenticationUserChanged({required this.user});

  /// The current authenticated user, or null if unauthenticated.
  final User? user;

  @override
  List<Object?> get props => [user];
}

/// {@template authentication_cooldown_completed}
/// Event triggered when the sign-in code request cooldown has completed.
/// {@endtemplate}
final class AuthenticationCooldownCompleted extends AuthenticationEvent {
  /// {@macro authentication_cooldown_completed}
  const AuthenticationCooldownCompleted();
}

/// {@template authentication_linking_initiated}
/// Event triggered when an anonymous user initiates the account linking flow.
///
/// This event must be dispatched *before* navigating to the authentication
/// route (`Routes.authenticationName`) when an anonymous user intends to
/// link their account to an email. It sets the `AuthFlow` in the
/// `AuthenticationBloc` to `linkAccount`, which is then used by the
/// `GoRouter`'s redirect logic to permit access to the authentication UI
/// in the correct context.
/// {@endtemplate}
final class AuthenticationLinkingInitiated extends AuthenticationEvent {
  /// {@macro authentication_linking_initiated}
  const AuthenticationLinkingInitiated();
}

/// {@template authentication_flow_reset}
/// Event triggered to reset the authentication flow context.
///
/// This event is dispatched when the authentication UI is dismissed
/// or when an authentication flow (like linking an account) has successfully
/// completed, ensuring that the `AuthFlow` state in the `AuthenticationBloc`
/// reverts to `signIn` for subsequent authentication attempts or a clean state.
/// {@endtemplate}
final class AuthenticationFlowReset extends AuthenticationEvent {
  /// {@macro authentication_flow_reset}
  const AuthenticationFlowReset();
}
