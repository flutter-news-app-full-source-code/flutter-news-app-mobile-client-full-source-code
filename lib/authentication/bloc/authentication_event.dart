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

/// {@template authentication_send_sign_in_link_requested}
/// Event triggered when the user requests a sign-in link to be sent
/// to their email.
/// {@endtemplate}
final class AuthenticationSendSignInLinkRequested extends AuthenticationEvent {
  /// {@macro authentication_send_sign_in_link_requested}
  const AuthenticationSendSignInLinkRequested({required this.email});

  /// The user's email address.
  final String email;

  @override
  List<Object> get props => [email];
}

/// {@template authentication_sign_in_with_link_attempted}
/// Event triggered when the app attempts to sign in using an email link.
/// This is typically triggered by a deep link handler.
/// {@endtemplate}
final class AuthenticationSignInWithLinkAttempted extends AuthenticationEvent {
  /// {@macro authentication_sign_in_with_link_attempted}
  const AuthenticationSignInWithLinkAttempted({required this.emailLink});

  /// The sign-in link received by the app.
  final String emailLink;

  @override
  List<Object> get props => [emailLink];
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
