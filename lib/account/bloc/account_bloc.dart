import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({
    required AuthRepository authenticationRepository,
    Logger? logger,
  })  : _authenticationRepository = authenticationRepository,
        _logger = logger ?? Logger('AccountBloc'),
        super(const AccountState()) {
    // Listen to user changes from AuthRepository
    _userSubscription = _authenticationRepository.authStateChanges.listen((
      user,
    ) {
      add(AccountUserChanged(user));
    });

    // Register event handlers
    on<AccountUserChanged>(_onAccountUserChanged);
    on<AccountClearUserPreferences>(_onAccountClearUserPreferences);
  }

  final AuthRepository _authenticationRepository;
  final Logger _logger;
  late StreamSubscription<User?> _userSubscription;

  Future<void> _onAccountUserChanged(
    AccountUserChanged event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(user: event.user));
    if (event.user == null) {
      // Clear preferences if user is null (logged out)
      emit(state.copyWith(status: AccountStatus.initial));
    }
  }

  Future<void> _onAccountClearUserPreferences(
    AccountClearUserPreferences event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      // This event is now handled by AppBloc.
      // AccountBloc only dispatches the event to AppBloc.
      // No direct repository interaction here.
      emit(state.copyWith(status: AccountStatus.success, clearError: true));
    } on HttpException catch (e) {
      _logger.severe(
        'AccountClearUserPreferences failed with HttpException: $e',
      );
      emit(state.copyWith(status: AccountStatus.failure, error: e));
    } catch (e, st) {
      _logger.severe(
        'AccountClearUserPreferences failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          error: OperationFailedException(
            'Failed to clear user preferences: $e',
          ),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
