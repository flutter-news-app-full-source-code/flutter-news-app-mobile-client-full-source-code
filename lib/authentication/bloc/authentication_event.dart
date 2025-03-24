part of 'authentication_bloc.dart';

/// {@template authentication_event}
/// Base class for authentication events.
/// {@endtemplate}
sealed class AuthenticationEvent extends Equatable {
  /// {@macro authentication_event}
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

/// {@template authentication_user_changed}
/// Event triggered when the user's authentication state changes.
/// {@endtemplate}
final class AuthenticationUserChanged extends AuthenticationEvent {
  /// {@macro authentication_user_changed}
  const AuthenticationUserChanged(this.user);

  /// The updated [User] object.
  final User user;

  @override
  List<Object> get props => [user];
}

/// {@template authentication_email_sign_in_requested}
/// Event triggered when the user requests to sign in with email and password.
/// {@endtemplate}
final class AuthenticationEmailSignInRequested extends AuthenticationEvent {
  /// {@macro authentication_email_sign_in_requested}
  const AuthenticationEmailSignInRequested({
    required this.email,
    required this.password,
  });

  /// The user's email address.
  final String email;

  /// The user's password.
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// {@template authentication_google_sign_in_requested}
/// Event triggered when the user requests to sign in with Google.
/// {@endtemplate}
final class AuthenticationGoogleSignInRequested extends AuthenticationEvent {
  /// {@macro authentication_google_sign_in_requested}
  const AuthenticationGoogleSignInRequested();
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

/// {@template authentication_delete_account_requested}
/// Event triggered when the user requests to delete their account.
/// {@endtemplate}
final class AuthenticationDeleteAccountRequested extends AuthenticationEvent {
  /// {@macro authentication_delete_account_requested}
  const AuthenticationDeleteAccountRequested();
}
