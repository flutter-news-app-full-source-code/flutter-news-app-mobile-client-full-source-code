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

    var oldStateInfo = oldState.runtimeType.toString();
    var newStateInfo = newState.runtimeType.toString();

    try {
      // Attempt to access a 'status' property if it exists
      if (oldState.status != null) {
        oldStateInfo = 'status: ${oldState.status}';
      }
      if (newState.status != null) {
        newStateInfo = 'status: ${newState.status}';
      }
    } catch (_) {
      // If 'status' property does not exist, or is null,
      // or if there's any other error accessing it,
      // fall back to runtimeType (which is already set).
    }

    log('onChange(${bloc.runtimeType}, $oldStateInfo -> $newStateInfo)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}
