import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

part 'user_limit_event.dart';
part 'user_limit_state.dart';

/// {@template user_limit_bloc}
/// Manages the state related to user preference limits.
///
/// This BLoC checks if a user has exceeded limits for followed items or
/// saved headlines based on their [AppUserRole] and the [RemoteConfig].
/// It emits states that guide the UI to prompt users to link accounts or
/// upgrade subscriptions when limits are reached.
/// {@endtemplate}
class UserLimitBloc extends Bloc<UserLimitEvent, UserLimitState> {
  /// {@macro user_limit_bloc}
  UserLimitBloc({required AppBloc appBloc})
      : _appBloc = appBloc,
        super(UserLimitInitial()) {
    on<CheckLimitRequested>(_onCheckLimitRequested);
    on<LimitActionTaken>(_onLimitActionTaken);
  }

  final AppBloc _appBloc;

  /// Handles the [CheckLimitRequested] event.
  ///
  /// Checks if the user has exceeded a specific limit based on their role
  /// and the application's remote configuration.
  Future<void> _onCheckLimitRequested(
    CheckLimitRequested event,
    Emitter<UserLimitState> emit,
  ) async {
    emit(UserLimitLoading());

    final currentUser = _appBloc.state.user;
    final userPreferences = _appBloc.state.userContentPreferences;
    final remoteConfig = _appBloc.state.remoteConfig;

    if (currentUser == null || userPreferences == null || remoteConfig == null) {
      emit(
        UserLimitFailure(
          exception: OperationFailedException(
            'User, preferences, or remote config not available.',
          ),
        ),
      );
      return;
    }

    final userRole = currentUser.appRole;
    final userPreferenceConfig = remoteConfig.userPreferenceConfig;

    int currentCount = 0;
    int limit = 0;
    LimitAction action = LimitAction.none;

    switch (event.limitType) {
      case LimitType.followedTopics:
        currentCount = userPreferences.followedTopics.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestFollowedItemsLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedFollowedItemsLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumFollowedItemsLimit;
            action = LimitAction.none; // Premium users have no practical limit
        }
      case LimitType.followedSources:
        currentCount = userPreferences.followedSources.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestFollowedItemsLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedFollowedItemsLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumFollowedItemsLimit;
            action = LimitAction.none;
        }
      case LimitType.followedCountries:
        currentCount = userPreferences.followedCountries.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestFollowedItemsLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedFollowedItemsLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumFollowedItemsLimit;
            action = LimitAction.none;
        }
      case LimitType.savedHeadlines:
        currentCount = userPreferences.savedHeadlines.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestSavedHeadlinesLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedSavedHeadlinesLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumSavedHeadlinesLimit;
            action = LimitAction.none;
        }
    }

    // If the action is to add an item, we check if currentCount is already at or above the limit.
    // If the action is to remove an item, we don't check limits.
    // For 'follow' and 'save' actions, we assume the check is for adding.
    final isAddingItem = event.entityId != null ||
        (event.limitType == LimitType.savedHeadlines &&
            !userPreferences.savedHeadlines.any((h) => h.id == event.entityId));

    if (isAddingItem && currentCount >= limit && action != LimitAction.none) {
      emit(
        LimitExceeded(
          limitType: event.limitType,
          userRole: userRole,
          action: action,
        ),
      );
    } else {
      emit(UserLimitSuccess());
    }
  }

  /// Handles the [LimitActionTaken] event, resetting the state to initial.
  void _onLimitActionTaken(
    LimitActionTaken event,
    Emitter<UserLimitState> emit,
  ) {
    emit(UserLimitInitial());
  }
}
