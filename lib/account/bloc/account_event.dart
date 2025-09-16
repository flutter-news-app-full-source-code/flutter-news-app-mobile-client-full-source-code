part of 'account_bloc.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class AccountUserChanged extends AccountEvent {
  // Corrected name
  const AccountUserChanged(this.user);
  final User? user;

  @override
  List<Object?> get props => [user];
}


class AccountClearUserPreferences extends AccountEvent {
  const AccountClearUserPreferences({required this.userId});
  final String userId;

  @override
  List<Object> get props => [userId];
}
