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
    this.appSettings,
    this.error,
  });

  /// The current status of loading/updating settings.
  final SettingsStatus status;

  /// Current user application settings. Null if settings haven't been loaded.
  final AppSettings? appSettings;

  /// An optional error object if the status is [SettingsStatus.failure].
  final Object? error;

  /// Creates a copy of the current state with updated values.
  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? appSettings,
    Object? error,
    bool clearError = false,
    bool clearAppSettings = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      appSettings: clearAppSettings ? null : appSettings ?? this.appSettings,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, appSettings, error];
}
