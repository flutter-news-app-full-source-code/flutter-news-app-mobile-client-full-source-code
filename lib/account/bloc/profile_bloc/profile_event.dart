part of 'profile_bloc.dart';

/// Abstract base class for all events in the [ProfileBloc].
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the user's name input changes.
class ProfileNameChanged extends ProfileEvent {
  const ProfileNameChanged(this.name);

  final String name;

  @override
  List<Object> get props => [name];
}

/// Dispatched when the user selects a new profile image.
class ProfileImageChanged extends ProfileEvent {
  const ProfileImageChanged(this.imageBytes);

  final Uint8List imageBytes;

  @override
  List<Object> get props => [imageBytes];
}

/// Dispatched when the user requests to save their profile changes.
class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested();
}

/// Dispatched when the user requests to delete their account.
class ProfileDeletionRequested extends ProfileEvent {
  const ProfileDeletionRequested();
}
