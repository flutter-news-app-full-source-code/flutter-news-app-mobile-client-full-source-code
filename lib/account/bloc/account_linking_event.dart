part of 'account_linking_bloc.dart';

/// Base class for all events related to the Account Linking feature.
abstract class AccountLinkingEvent extends Equatable {
  const AccountLinkingEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered when the user attempts to sign in/link with Google.
class AccountLinkingGoogleSignInRequested extends AccountLinkingEvent {
  const AccountLinkingGoogleSignInRequested();
}

/// Event triggered when the user attempts to sign in/link with Email Link.
class AccountLinkingEmailLinkSignInRequested extends AccountLinkingEvent {
  const AccountLinkingEmailLinkSignInRequested({required this.email});

  final String email;

  @override
  List<Object> get props => [email];
}

// Add other events if different authentication methods are needed (e.g., Apple)
