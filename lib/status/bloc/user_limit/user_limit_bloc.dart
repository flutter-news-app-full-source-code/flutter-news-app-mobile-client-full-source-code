import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/user_limit_service.dart'; // Import the new service for LimitType and LimitAction

part 'user_limit_event.dart';
part 'user_limit_state.dart';

/// {@template user_limit_bloc}
/// Manages the state related to user preference limits for UI presentation.
///
/// This BLoC is responsible for reacting to [LimitExceededTriggered] events
/// (dispatched by feature BLoCs after checking limits via [UserLimitService])
/// and emitting states that guide the UI to prompt users to link accounts or
/// upgrade subscriptions when limits are reached. It also handles resetting
/// its state after a user takes action.
/// {@endtemplate}
class UserLimitBloc extends Bloc<UserLimitEvent, UserLimitState> {
  /// {@macro user_limit_bloc}
  UserLimitBloc() : super(UserLimitInitial()) {
    on<LimitExceededTriggered>(_onLimitExceededTriggered);
    on<LimitActionTaken>(_onLimitActionTaken);
  }

  /// Handles the [LimitExceededTriggered] event.
  ///
  /// Emits a [LimitExceeded] state with the details provided in the event,
  /// signaling the UI to display the limit exceeded prompt.
  void _onLimitExceededTriggered(
    LimitExceededTriggered event,
    Emitter<UserLimitState> emit,
  ) {
    emit(
      LimitExceeded(
        limitType: event.limitType,
        userRole: event.userRole,
        action: event.action,
      ),
    );
  }

  /// Handles the [LimitActionTaken] event, resetting the state to initial.
  void _onLimitActionTaken(
    LimitActionTaken event,
    Emitter<UserLimitState> emit,
  ) {
    emit(UserLimitInitial());
  }
}
