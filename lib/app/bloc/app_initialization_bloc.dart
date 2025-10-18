import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart'
    show AppInitializer;
import 'package:logging/logging.dart';

part 'app_initialization_event.dart';
part 'app_initialization_state.dart';

/// {@template app_initialization_bloc}
/// A BLoC dedicated to managing the application's startup and initialization
/// process.
///
/// This BLoC is responsible for orchestrating the initial data fetch via the
/// [AppInitializer] and handling both success and failure states. It provides
/// a clean separation of concerns, isolating the complex startup logic from
/// the main `AppBloc`.
/// {@endtemplate}
class AppInitializationBloc
    extends Bloc<AppInitializationEvent, AppInitializationState> {
  /// {@macro app_initialization_bloc}
  AppInitializationBloc({
    required AppInitializer appInitializer,
    required Logger logger,
  }) : _appInitializer = appInitializer,
       _logger = logger,
       super(const AppInitializationInProgress()) {
    on<AppInitializationStarted>(_runInitialization);
    on<AppInitializationRetried>(_runInitialization);
  }

  final AppInitializer _appInitializer;
  final Logger _logger;

  /// Runs the core initialization logic.
  ///
  /// This method is triggered by both [AppInitializationStarted] and
  /// [AppInitializationRetried] events. It ensures the UI shows a loading
  /// state and then attempts to initialize the app.
  Future<void> _runInitialization(
    AppInitializationEvent event,
    Emitter<AppInitializationState> emit,
  ) async {
    _logger.info('Running app initialization...');
    // Always emit in-progress state first, especially for retries.
    emit(const AppInitializationInProgress());

    try {
      final result = await _appInitializer.initializeApp();

      switch (result) {
        case final InitializationSuccess success:
          _logger.info('App initialization successful.');
          emit(AppInitializationSucceeded(success));
        case final InitializationFailure failure:
          _logger.warning('App initialization failed: ${failure.status}');
          emit(AppInitializationFailed(failure));
      }
    } catch (e, s) {
      _logger.severe(
        'An unexpected error occurred during initialization',
        e,
        s,
      );
      emit(
        AppInitializationFailed(
          InitializationFailure(
            status: AppLifeCycleStatus.criticalError,
            error: UnknownException(
              'An unexpected error occurred during app initialization: $e',
            ),
          ),
        ),
      );
    }
  }
}
