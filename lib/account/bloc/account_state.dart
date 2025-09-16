part of 'account_bloc.dart';

enum AccountStatus { initial, loading, success, failure }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.user,
    this.error,
  });

  final AccountStatus status;
  final User? user;
  final HttpException? error;

  AccountState copyWith({
    AccountStatus? status,
    User? user,
    HttpException? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, user, error];
}
