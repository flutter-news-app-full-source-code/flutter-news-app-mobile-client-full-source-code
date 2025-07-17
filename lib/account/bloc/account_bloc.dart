import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/app/config/config.dart' as local_config;
import 'package:ht_shared/ht_shared.dart';
import 'package:logging/logging.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({
    required HtAuthRepository authenticationRepository,
    required HtDataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required local_config.AppEnvironment environment,
    Logger? logger,
  }) : _authenticationRepository = authenticationRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _environment = environment,
       _logger = logger ?? Logger('AccountBloc'),
       super(const AccountState()) {
    // Listen to user changes from HtAuthRepository
    _userSubscription = _authenticationRepository.authStateChanges.listen((
      user,
    ) {
      add(AccountUserChanged(user));
    });

    // Register event handlers
    on<AccountUserChanged>(_onAccountUserChanged);
    on<AccountLoadUserPreferences>(_onAccountLoadUserPreferences);
    on<AccountSaveHeadlineToggled>(_onAccountSaveHeadlineToggled);
    on<AccountFollowTopicToggled>(_onAccountFollowTopicToggled);
    on<AccountFollowSourceToggled>(_onAccountFollowSourceToggled);
    on<AccountClearUserPreferences>(_onAccountClearUserPreferences);
  }

  final HtAuthRepository _authenticationRepository;
  final HtDataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final local_config.AppEnvironment _environment;
  final Logger _logger;
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
      emit(
        state.copyWith(clearPreferences: true, status: AccountStatus.initial),
      );
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
        userId: event.userId,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: preferences,
          clearErrorMessage: true,
        ),
      );
    } on NotFoundException {
      // In demo mode, a short delay is introduced here to mitigate a race
      // condition during anonymous to authenticated data migration.
      // This ensures that the DemoDataMigrationService has a chance to
      // complete its migration of UserContentPreferences before AccountBloc
      // attempts to create a new default preference for the authenticated user.
      // This is a temporary stub for the demo environment only and is not
      // needed in production/development where backend handles migration.
      if (_environment == local_config.AppEnvironment.demo) {
        // ignore: inference_failure_on_instance_creation
        await Future.delayed(const Duration(milliseconds: 50));
        // After delay, re-attempt to read the preferences. This is crucial
        // because migration might have completed during the delay.
        try {
          final migratedPreferences =
              await _userContentPreferencesRepository.read(
            id: event.userId,
            userId: event.userId,
          );
          emit(
            state.copyWith(
              status: AccountStatus.success,
              preferences: migratedPreferences,
              clearErrorMessage: true,
            ),
          );
          return; // Exit if successfully read after migration
        } on NotFoundException {
          // Still not found after delay, proceed to create default.
          _logger.info(
            '[AccountBloc] UserContentPreferences still not found after '
            'migration delay. Creating default preferences.',
          );
        }
      }
      // If preferences not found (either initially or after re-attempt), create
      // a default one for the user.
      final defaultPreferences = UserContentPreferences(
        id: event.userId,
        followedCountries: const [],
        followedSources: const [],
        followedTopics: const [],
        savedHeadlines: const [],
      );
      try {
        await _userContentPreferencesRepository.create(
          item: defaultPreferences,
          userId: event.userId,
        );
        emit(
          state.copyWith(
            preferences: defaultPreferences,
            clearErrorMessage: true,
            status: AccountStatus.success,
          ),
        );
      } on ConflictException {
        // If a conflict occurs during creation (e.g., another process
        // created it concurrently), attempt to read it again to get the existing
        // one. This can happen if the migration service created it right after
        // the second NotFoundException.
        _logger.info(
          '[AccountBloc] Conflict during creation of UserContentPreferences. '
          'Attempting to re-read.',
        );
        final existingPreferences = await _userContentPreferencesRepository
            .read(id: event.userId, userId: event.userId);
        emit(
          state.copyWith(
            status: AccountStatus.success,
            preferences: existingPreferences,
            clearErrorMessage: true,
          ),
        );
      } on HtHttpException catch (e) {
        _logger.severe(
          'Failed to create default preferences with HtHttpException: $e',
        );
        emit(
          state.copyWith(
            status: AccountStatus.failure,
            errorMessage: e.message,
          ),
        );
      } catch (e, st) {
        _logger.severe(
          'Failed to create default preferences with unexpected error: $e',
          e,
          st,
        );
        emit(
          state.copyWith(
            status: AccountStatus.failure,
            errorMessage: OperationFailedException(
              'Failed to create default preferences: $e',
            ).message,
          ),
        );
      }
    } on HtHttpException catch (e) {
      _logger.severe('AccountLoadUserPreferences failed with HtHttpException: $e');
        emit(
          state.copyWith(
            preferences: defaultPreferences,
            clearErrorMessage: true,
            status: AccountStatus.success,
          ),
        );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: OperationFailedException(
            'An unexpected error occurred: $e',
          ).message,
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
    final isCurrentlySaved = currentPrefs.savedHeadlines.any(
      (h) => h.id == event.headline.id,
    );
    final List<Headline> updatedSavedHeadlines;

    if (isCurrentlySaved) {
      updatedSavedHeadlines = List.from(currentPrefs.savedHeadlines)
        ..removeWhere((h) => h.id == event.headline.id);
    } else {
      updatedSavedHeadlines = List.from(currentPrefs.savedHeadlines)
        ..add(event.headline);
    }

    final updatedPrefs = currentPrefs.copyWith(
      savedHeadlines: updatedSavedHeadlines,
    );

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
      _logger.severe('AccountSaveHeadlineToggled failed with HtHttpException: $e');
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e, st) {
      _logger.severe(
        'AccountSaveHeadlineToggled failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: OperationFailedException(
            'Failed to update saved headlines: $e',
          ).message,
        ),
      );
    }
  }

  Future<void> _onAccountFollowTopicToggled(
    AccountFollowTopicToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlyFollowed = currentPrefs.followedTopics.any(
      (t) => t.id == event.topic.id,
    );
    final List<Topic> updatedFollowedCategories;

    updatedFollowedCategories = isCurrentlyFollowed
        ? List.from(currentPrefs.followedTopics)
      ..removeWhere((t) => t.id == event.topic.id)
        : List.from(currentPrefs.followedTopics)
      ..add(event.topic);

    final updatedPrefs = currentPrefs.copyWith(
      followedTopics: updatedFollowedCategories,
    );

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
      _logger.severe('AccountFollowTopicToggled failed with HtHttpException: $e');
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e, st) {
      _logger.severe(
        'AccountFollowTopicToggled failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: OperationFailedException(
            'Failed to update followed topics: $e',
          ).message,
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
    final isCurrentlyFollowed = currentPrefs.followedSources.any(
      (s) => s.id == event.source.id,
    );
    final List<Source> updatedFollowedSources;

    if (isCurrentlyFollowed) {
      updatedFollowedSources = List.from(currentPrefs.followedSources)
        ..removeWhere((s) => s.id == event.source.id);
    } else {
      updatedFollowedSources = List.from(currentPrefs.followedSources)
        ..add(event.source);
    }

    final updatedPrefs = currentPrefs.copyWith(
      followedSources: updatedFollowedSources,
    );

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
      _logger.severe('AccountFollowSourceToggled failed with HtHttpException: $e');
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e, st) {
      _logger.severe(
        'AccountFollowSourceToggled failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: OperationFailedException(
            'Failed to update followed sources: $e',
          ).message,
        ),
      );
    }
  }

  Future<void> _onAccountClearUserPreferences(
    AccountClearUserPreferences event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      // Create a new default preferences object to "clear" existing ones
      final defaultPreferences = UserContentPreferences(
        id: event.userId,
        followedCountries: const [],
        followedSources: const [],
        followedTopics: const [],
        savedHeadlines: const [],
      );
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
      _logger.severe('AccountClearUserPreferences failed with HtHttpException: $e');
      emit(
        state.copyWith(status: AccountStatus.failure, errorMessage: e.message),
      );
    } catch (e, st) {
      _logger.severe(
        'AccountClearUserPreferences failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: OperationFailedException(
            'Failed to clear user preferences: $e',
          ).message,
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
