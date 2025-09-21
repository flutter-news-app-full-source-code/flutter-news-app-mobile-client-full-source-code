// ignore_for_file: avoid_dynamic_calls

import 'dart:developer';

import 'package:bloc/bloc.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final dynamic oldState = change.currentState;
    final dynamic newState = change.nextState;

    // Initialize state information strings.
    // By default, truncate the full string representation of the state
    // to the first 250 characters to prevent excessively long logs.
    var oldStateInfo = oldState.toString().substring(
      0,
      oldState.toString().length > 250 ? 250 : oldState.toString().length,
    );
    var newStateInfo = newState.toString().substring(
      0,
      newState.toString().length > 250 ? 250 : newState.toString().length,
    );

    try {
      // Attempt to access a 'status' property on the state objects.
      // Many BLoC states use a 'status' property (e.g., Loading, Success, Failure)
      // to represent their current lifecycle phase. If this property exists
      // and is not null, prioritize logging its value for conciseness.
      if (oldState.status != null) {
        oldStateInfo = 'status: ${oldState.status}';
      }
      if (newState.status != null) {
        newStateInfo = 'status: ${newState.status}';
      }
    } catch (e) {
      // This catch block handles cases where:
      // 1. The 'status' property does not exist on the state object (NoSuchMethodError).
      // 2. Accessing 'status' throws any other runtime error.
      // In such scenarios, the `oldStateInfo` and `newStateInfo` variables
      // will retain their initially truncated string representations,
      // providing a fallback for states without a 'status' property.
      // Log the error for debugging purposes, but do not rethrow to avoid
      // crashing the observer.
      log('Error accessing status property for ${bloc.runtimeType}: $e');
    }

    // Log the state change, including the BLoC type and the old and new state information.
    log('onChange(${bloc.runtimeType}, $oldStateInfo -> $newStateInfo)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}
