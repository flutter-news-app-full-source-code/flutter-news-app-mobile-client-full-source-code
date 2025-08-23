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

class AccountLoadUserPreferences extends AccountEvent {
  // Corrected name
  const AccountLoadUserPreferences({required this.userId});
  final String userId;

  @override
  List<Object> get props => [userId];
}

class AccountSaveHeadlineToggled extends AccountEvent {
  const AccountSaveHeadlineToggled({required this.headline});
  final Headline headline;

  @override
  List<Object> get props => [headline];
}

class AccountFollowTopicToggled extends AccountEvent {
  const AccountFollowTopicToggled({required this.topic});
  final Topic topic;

  @override
  List<Object> get props => [topic];
}

class AccountFollowSourceToggled extends AccountEvent {
  const AccountFollowSourceToggled({required this.source});
  final Source source;

  @override
  List<Object> get props => [source];
}

class AccountFollowCountryToggled extends AccountEvent {
  const AccountFollowCountryToggled({required this.country});
  final Country country;

  @override
  List<Object> get props => [country];
}

class AccountClearUserPreferences extends AccountEvent {
  const AccountClearUserPreferences({required this.userId});
  final String userId;

  @override
  List<Object> get props => [userId];
}
