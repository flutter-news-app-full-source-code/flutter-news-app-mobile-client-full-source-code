part of 'settings_bloc.dart';

/// Enum representing the possible statuses of the settings feature.
enum SettingsStatus {
  /// Initial state, before any loading attempt.
  initial,

  /// Settings are currently being loaded from the repository.
  loading,

  /// Settings have been successfully loaded or updated.
  success,

  /// An error occurred while loading or updating settings.
  failure,
}

/// {@template settings_state}
/// Represents the state of the settings feature, including loading status
/// and the current values of all user-configurable application settings.
/// {@endtemplate}
class SettingsState extends Equatable {
  /// {@macro settings_state}
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.userAppSettings, // Nullable, populated after successful load
    this.error,
  });

  /// The current status of loading/updating settings.
  final SettingsStatus status;

  /// Current user application settings.
  /// Null if settings haven't been loaded or if there's no authenticated user
  /// context for settings yet.
  final UserAppSettings? userAppSettings;

  /// An optional error object if the status is [SettingsStatus.failure].
  final Object? error;

  /// Creates a copy of the current state with updated values.
  SettingsState copyWith({
    SettingsStatus? status,
    UserAppSettings? userAppSettings,
    Object? error,
    bool clearError = false, // Flag to explicitly clear error
    bool clearUserAppSettings = false, // Flag to explicitly clear settings
  }) {
    return SettingsState(
      status: status ?? this.status,
      userAppSettings:
          clearUserAppSettings ? null : userAppSettings ?? this.userAppSettings,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, userAppSettings, error];
}
