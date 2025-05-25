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
/// and the current values of all user-configurable settings.
/// {@endtemplate}
class SettingsState extends Equatable {
  /// {@macro settings_state}
  const SettingsState({
    this.status = SettingsStatus.initial,
    // Use new models from ht_shared
    this.userAppSettings = const UserAppSettings(
      id: '',
    ), // Provide a default empty instance
    this.userContentPreferences = const UserContentPreferences(
      id: '',
    ), // Provide a default empty instance
    this.error,
  });

  /// The current status of loading/updating settings.
  final SettingsStatus status;

  /// Current user application settings.
  final UserAppSettings userAppSettings;

  /// Current user content preferences.
  final UserContentPreferences userContentPreferences;

  /// An optional error object if the status is [SettingsStatus.failure].
  final Object? error;

  /// Creates a copy of the current state with updated values.
  SettingsState copyWith({
    SettingsStatus? status,
    UserAppSettings? userAppSettings, // Update parameter type
    UserContentPreferences? userContentPreferences, // Update parameter type
    Object? error,
    bool clearError = false, // Flag to explicitly clear error
  }) {
    return SettingsState(
      status: status ?? this.status,
      userAppSettings: userAppSettings ?? this.userAppSettings, // Update field
      userContentPreferences:
          userContentPreferences ?? this.userContentPreferences, // Update field
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    userAppSettings, // Update field
    userContentPreferences, // Update field
    error,
  ];
}
