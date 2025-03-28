part of 'account_linking_bloc.dart'; // Renamed part of directive

/// Enum representing the status of the Account Linking operations. // Updated doc
enum AccountLinkingStatus {
  // Renamed enum
  /// Initial state, nothing has happened yet.
  initial,

  /// An authentication/linking operation is in progress.
  loading,

  /// An authentication/linking operation succeeded.
  /// The global AppBloc state change will handle navigation.
  success,

  /// An authentication/linking operation failed.
  failure,

  /// Email link has been sent successfully (for email link flow).
  emailLinkSent,
}

/// Represents the state of the Account Linking feature.
class AccountLinkingState extends Equatable {
  const AccountLinkingState({
    this.status = AccountLinkingStatus.initial,
    this.errorMessage,
  });

  /// The current status of the linking operations.
  final AccountLinkingStatus status;

  /// An optional error message if an operation failed.
  final String? errorMessage;

  /// Creates a copy of the current state with updated values.
  AccountLinkingState copyWith({
    // Renamed return type
    AccountLinkingStatus? status,
    String? errorMessage,
    bool forceErrorMessage = false,
  }) {
    // Determine if the error message should be cleared.
    // Clear it if the status is changing *unless* the new status is failure
    // or the forceErrorMessage flag is true.
    final shouldClearError =
        status != null &&
        status != this.status &&
        status != AccountLinkingStatus.failure &&
        !forceErrorMessage;

    return AccountLinkingState(
      status: status ?? this.status,
      errorMessage:
          shouldClearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
