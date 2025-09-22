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
    // to the first 150 characters to prevent excessively long logs.
    final oldStateInfo = oldState.toString().substring(
      0,
      oldState.toString().length > 150 ? 150 : oldState.toString().length,
    );
    final newStateInfo = newState.toString().substring(
      0,
      newState.toString().length > 150 ? 150 : newState.toString().length,
    );

    // Log the state change, including the BLoC type and the old and new state information.
    log('onChange(${bloc.runtimeType}, $oldStateInfo -> $newStateInfo)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}
