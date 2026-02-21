part of 'profile_bloc.dart';

/// The status of the profile editing process.
enum ProfileStatus {
  /// Initial state, form is ready.
  idle,

  /// The profile is being updated.
  loading,

  /// The profile was updated successfully.
  success,

  /// An error occurred during the update.
  failure,
}

/// {@template profile_state}
/// Represents the state of the user's profile editing form.
/// {@endtemplate}
class ProfileState extends Equatable {
  /// {@macro profile_state}
  const ProfileState({
    this.status = ProfileStatus.idle,
    this.name = '',
    this.error,
  });

  /// The current status of the profile update process.
  final ProfileStatus status;

  /// The current value of the name input field.
  final String name;

  /// An error that occurred during the update process.
  final HttpException? error;

  @override
  List<Object?> get props => [status, name, error];

  /// Creates a copy of this [ProfileState] with updated values.
  ProfileState copyWith({
    ProfileStatus? status,
    String? name,
    HttpException? error,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      name: name ?? this.name,
      error: clearError ? null : error ?? this.error,
    );
  }
}
