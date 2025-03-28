part of 'account_bloc.dart';

/// Base class for all events related to the Account feature.
abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered when the user requests to navigate to the settings page.
class AccountSettingsNavigationRequested extends AccountEvent {
  const AccountSettingsNavigationRequested();
}

/// Event triggered when the user requests to log out.
class AccountLogoutRequested extends AccountEvent {
  const AccountLogoutRequested();
}

/// Event triggered when the user (anonymous) requests to backup/link account.
class AccountBackupNavigationRequested extends AccountEvent {
  const AccountBackupNavigationRequested();
}
