import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({
    required HtAuthRepository authenticationRepository,
    required HtDataRepository<UserContentPreferences>
        userContentPreferencesRepository,
  })  : _authenticationRepository = authenticationRepository,
        _userContentPreferencesRepository = userContentPreferencesRepository,
        super(const AccountState()) {
    // Listen to user changes from HtAuthRepository
    _userSubscription =
        _authenticationRepository.authStateChanges.listen((user) {
      add(AccountUserChanged(user));
    });

    // Register event handlers
    on<AccountUserChanged>(_onAccountUserChanged);
    on<AccountLoadUserPreferences>(_onAccountLoadUserPreferences);
    on<AccountSaveHeadlineToggled>(_onAccountSaveHeadlineToggled);
    on<AccountFollowCategoryToggled>(_onAccountFollowCategoryToggled);
    on<AccountFollowSourceToggled>(_onAccountFollowSourceToggled);
    // AccountFollowCountryToggled handler removed
    on<AccountClearUserPreferences>(_onAccountClearUserPreferences);
  }

  final HtAuthRepository _authenticationRepository;
  final HtDataRepository<UserContentPreferences>
      _userContentPreferencesRepository;
  late StreamSubscription<User?> _userSubscription;

  Future<void> _onAccountUserChanged(
    AccountUserChanged event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(user: event.user));
    if (event.user != null) {
      add(AccountLoadUserPreferences(userId: event.user!.id));
    } else {
      // Clear preferences if user is null (logged out)
      emit(state.copyWith(clearPreferences: true, status: AccountStatus.initial));
    }
  }

  Future<void> _onAccountLoadUserPreferences(
    AccountLoadUserPreferences event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: event.userId,
        userId: event.userId, // Scope to the current user
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: preferences,
          clearErrorMessage: true,
        ),
      );
    } on NotFoundException {
      // If preferences not found, create a default one for the user
      final defaultPreferences = UserContentPreferences(id: event.userId);
      try {
        await _userContentPreferencesRepository.create(
          item: defaultPreferences,
          userId: event.userId,
        );
        emit(
          state.copyWith(
            status: AccountStatus.success,
            preferences: defaultPreferences,
            clearErrorMessage: true,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: AccountStatus.failure,
            errorMessage: 'Failed to create default preferences.',
          ),
        );
      }
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onAccountSaveHeadlineToggled(
    AccountSaveHeadlineToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlySaved =
        currentPrefs.savedHeadlines.any((h) => h.id == event.headline.id);
    final List<Headline> updatedSavedHeadlines;

    if (isCurrentlySaved) {
      updatedSavedHeadlines = List.from(currentPrefs.savedHeadlines)
        ..removeWhere((h) => h.id == event.headline.id);
    } else {
      updatedSavedHeadlines = List.from(currentPrefs.savedHeadlines)
        ..add(event.headline);
    }

    final updatedPrefs =
        currentPrefs.copyWith(savedHeadlines: updatedSavedHeadlines);

    try {
      await _userContentPreferencesRepository.update(
        id: state.user!.id,
        item: updatedPrefs,
        userId: state.user!.id,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: updatedPrefs,
          clearErrorMessage: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Failed to update saved headlines.',
        ),
      );
    }
  }

  Future<void> _onAccountFollowCategoryToggled(
    AccountFollowCategoryToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlyFollowed = currentPrefs.followedCategories
        .any((c) => c.id == event.category.id);
    final List<Category> updatedFollowedCategories;

    if (isCurrentlyFollowed) {
      updatedFollowedCategories = List.from(currentPrefs.followedCategories)
        ..removeWhere((c) => c.id == event.category.id);
    } else {
      updatedFollowedCategories = List.from(currentPrefs.followedCategories)
        ..add(event.category);
    }

    final updatedPrefs =
        currentPrefs.copyWith(followedCategories: updatedFollowedCategories);

    try {
      await _userContentPreferencesRepository.update(
        id: state.user!.id,
        item: updatedPrefs,
        userId: state.user!.id,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: updatedPrefs,
          clearErrorMessage: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Failed to update followed categories.',
        ),
      );
    }
  }

  Future<void> _onAccountFollowSourceToggled(
    AccountFollowSourceToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlyFollowed =
        currentPrefs.followedSources.any((s) => s.id == event.source.id);
    final List<Source> updatedFollowedSources;

    if (isCurrentlyFollowed) {
      updatedFollowedSources = List.from(currentPrefs.followedSources)
        ..removeWhere((s) => s.id == event.source.id);
    } else {
      updatedFollowedSources = List.from(currentPrefs.followedSources)
        ..add(event.source);
    }

    final updatedPrefs =
        currentPrefs.copyWith(followedSources: updatedFollowedSources);

    try {
      await _userContentPreferencesRepository.update(
        id: state.user!.id,
        item: updatedPrefs,
        userId: state.user!.id,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: updatedPrefs,
          clearErrorMessage: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Failed to update followed sources.',
        ),
      );
    }
  }

  // _onAccountFollowCountryToggled method removed

  Future<void> _onAccountClearUserPreferences(
    AccountClearUserPreferences event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      // Create a new default preferences object to "clear" existing ones
      final defaultPreferences = UserContentPreferences(id: event.userId);
      await _userContentPreferencesRepository.update(
        id: event.userId,
        item: defaultPreferences,
        userId: event.userId,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: defaultPreferences,
          clearErrorMessage: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Failed to clear user preferences.',
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
