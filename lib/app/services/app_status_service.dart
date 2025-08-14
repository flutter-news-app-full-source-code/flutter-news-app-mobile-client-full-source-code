import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart';

/// {@template app_status_service}
/// A service dedicated to monitoring the application's lifecycle and
/// proactively triggering status checks.
///
/// This service ensures that the application can react to server-side
/// status changes (like maintenance mode or forced updates) in real-time,
/// both when the app is resumed from the background and during extended
/// foreground sessions.
///
/// It works by:
/// 1.  Implementing [WidgetsBindingObserver] to listen for app lifecycle events.
/// 2.  Triggering a remote configuration fetch via the [AppBloc] whenever the
///     app is resumed (`AppLifecycleState.resumed`).
/// 3.  Using a periodic [Timer] to trigger fetches at a regular interval,
///     catching status changes even if the app remains in the foreground.
/// {@endtemplate}
class AppStatusService with WidgetsBindingObserver {
  /// {@macro app_status_service}
  ///
  /// Requires a [BuildContext] to access the [AppBloc] and a [Duration]
  /// for the periodic check interval.
  AppStatusService({
    required BuildContext context,
    required Duration checkInterval,
    required AppEnvironment environment,
  }) : _context = context,
       _checkInterval = checkInterval,
       _environment = environment {
    // Immediately register this service as a lifecycle observer.
    WidgetsBinding.instance.addObserver(this);
    // Start the periodic checks.
    _startPeriodicChecks();
  }

  /// The build context used to look up the AppBloc.
  final BuildContext _context;

  /// The interval at which to perform periodic status checks.
  final Duration _checkInterval;

  /// The current application environment.
  final AppEnvironment _environment;

  /// The timer responsible for periodic checks.
  Timer? _timer;

  /// Starts the periodic timer to trigger config fetches.
  ///
  /// This ensures that even if the app stays in the foreground, it will
  /// eventually learn about new server-side status changes.
  void _startPeriodicChecks() {
    // Cancel any existing timer to prevent duplicates.
    _timer?.cancel();
    // Create a new periodic timer.
    _timer = Timer.periodic(_checkInterval, (_) {
      // In demo mode, periodic checks are not needed as there's no backend.
      if (_environment == AppEnvironment.demo) {
        print('[AppStatusService] Demo mode: Skipping periodic check.');
        return;
      }
      print(
        '[AppStatusService] Periodic check triggered. Requesting AppConfig fetch.',
      );
      // Add the event to the AppBloc to fetch the latest config.
      _context.read<AppBloc>().add(
        const AppConfigFetchRequested(isBackgroundCheck: true),
      );
    });
  }

  /// Overridden from [WidgetsBindingObserver].
  ///
  /// This method is called whenever the application's lifecycle state changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // In demo mode, we disable the app resume check. This is especially
    // useful on web, where switching browser tabs would otherwise trigger
    // a reload, which is unnecessary and can be distracting for demos.
    if (_environment == AppEnvironment.demo) {
      print('[AppStatusService] Demo mode: Skipping app lifecycle check.');
      return;
    }

    // We are only interested in the 'resumed' state.
    if (state == AppLifecycleState.resumed) {
      print('[AppStatusService] App resumed. Requesting AppConfig fetch.');
      // When the app comes to the foreground, immediately trigger a check.
      // This is crucial for catching maintenance mode that was enabled
      // while the app was in the background.
      _context.read<AppBloc>().add(
        const AppConfigFetchRequested(isBackgroundCheck: true),
      );
    }
  }

  /// Cleans up resources used by the service.
  ///
  /// This must be called when the service is no longer needed (e.g., when
  /// the main app widget is disposed) to prevent memory leaks from the
  /// timer and the observer registration.
  void dispose() {
    print('[AppStatusService] Disposing service.');
    // Stop the periodic timer.
    _timer?.cancel();
    // Remove this object from the list of lifecycle observers.
    WidgetsBinding.instance.removeObserver(this);
  }
}
