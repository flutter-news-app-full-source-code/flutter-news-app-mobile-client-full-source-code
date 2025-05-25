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
