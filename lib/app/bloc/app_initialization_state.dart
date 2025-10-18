part of 'app_initialization_bloc.dart';


/// {@template app_initialization_state}
/// Base class for all states related to the application initialization process.
/// {@endtemplate}
sealed class AppInitializationState extends Equatable {
  /// {@macro app_initialization_state}
  const AppInitializationState();

  @override
  List<Object> get props => [];
}

/// {@template app_initialization_in_progress}
/// State indicating that the application initialization is currently in
/// progress.
/// {@endtemplate}
final class AppInitializationInProgress extends AppInitializationState {
  /// {@macro app_initialization_in_progress}
  const AppInitializationInProgress();
}

/// {@template app_initialization_success}
/// State indicating that the application has been successfully initialized.
///
/// Contains the successful initialization data.
/// {@endtemplate}
final class AppInitializationSucceeded extends AppInitializationState {
  /// {@macro app_initialization_success}
  const AppInitializationSucceeded(this.initializationSuccess);

  /// The result of a successful initialization, containing all necessary
  /// pre-loaded data like remote config and user settings.
  final InitializationSuccess initializationSuccess;

  @override
  List<Object> get props => [initializationSuccess];
}

/// {@template app_initialization_failure}
/// State indicating that the application initialization has failed.
///
/// Contains the failure details.
/// {@endtemplate}
final class AppInitializationFailed extends AppInitializationState {
  /// {@macro app_initialization_failure}
  const AppInitializationFailed(this.initializationFailure);

  /// The result of a failed initialization, containing the reason for the
  /// failure (e.g., maintenance mode, critical error).
  final InitializationFailure initializationFailure;

  @override
  List<Object> get props => [initializationFailure];
}
