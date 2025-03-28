import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';

part 'account_linking_event.dart';
part 'account_linking_state.dart';

/// {@template account_linking_bloc}
/// BLoC responsible for handling the logic for linking an anonymous account
/// to a permanent one (e.g., Google, Email Link).
/// {@endtemplate}
class AccountLinkingBloc
    extends Bloc<AccountLinkingEvent, AccountLinkingState> {
  /// {@macro account_linking_bloc}
  AccountLinkingBloc({
    required HtAuthenticationRepository authenticationRepository,
  }) : _authenticationRepository = authenticationRepository,
       super(const AccountLinkingState()) {
    on<AccountLinkingGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AccountLinkingEmailLinkSignInRequested>(_onEmailLinkSignInRequested);
  }

  final HtAuthenticationRepository _authenticationRepository;

  /// Handles the [AccountLinkingGoogleSignInRequested] event.
  Future<void> _onGoogleSignInRequested(
    AccountLinkingGoogleSignInRequested event,
    Emitter<AccountLinkingState> emit,
  ) async {
    emit(state.copyWith(status: AccountLinkingStatus.loading));
    try {
      await _authenticationRepository.signInWithGoogle();
      // Success is implicit via AppBloc observing the user stream change.
      // Reset state locally or emit success if specific UI feedback needed.
      emit(state.copyWith(status: AccountLinkingStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountLinkingStatus.failure,
          errorMessage: 'Google Sign-In failed: $e',
        ),
      );
    }
  }

  /// Handles the [AccountLinkingEmailLinkSignInRequested] event.
  Future<void> _onEmailLinkSignInRequested(
    AccountLinkingEmailLinkSignInRequested event,
    Emitter<AccountLinkingState> emit,
  ) async {
    emit(state.copyWith(status: AccountLinkingStatus.loading));
    try {
      await _authenticationRepository.sendSignInLinkToEmail(email: event.email);
      emit(state.copyWith(status: AccountLinkingStatus.emailLinkSent));
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountLinkingStatus.failure,
          errorMessage: 'Failed to send email link: $e',
        ),
      );
    }
  }
}
