part of 'app_initialization_bloc.dart';

/// {@template app_initialization_event}
/// Base class for all events related to the application initialization process.
/// {@endtemplate}
abstract class AppInitializationEvent extends Equatable {
  /// {@macro app_initialization_event}
  const AppInitializationEvent();

  @override
  List<Object> get props => [];
}

/// {@template app_initialization_started}
/// Event dispatched to begin the application initialization process.
/// {@endtemplate}
class AppInitializationStarted extends AppInitializationEvent {
  /// {@macro app_initialization_started}
  const AppInitializationStarted();
}

/// {@template app_initialization_retried}
/// Event dispatched when a failed initialization is retried by the user.
/// {@endtemplate}
class AppInitializationRetried extends AppInitializationEvent {
  /// {@macro app_initialization_retried}
  const AppInitializationRetried();
}
