import 'dart:async';
import 'dart:typed_data';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:logging/logging.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// {@template profile_bloc}
/// Manages the state for the user profile editing page.
///
/// This BLoC handles form input changes, orchestrates the media upload
/// process for the profile picture, and updates the user's profile data.
/// {@endtemplate}
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  /// {@macro profile_bloc}
  ProfileBloc({
    required User user,
    required DataRepository<User> userRepository,
    required AuthRepository authRepository,
    required MediaRepository mediaRepository,
    required AppBloc appBloc,
    required Logger logger,
  }) : _userRepository = userRepository,
       _authRepository = authRepository,
       _mediaRepository = mediaRepository,
       _appBloc = appBloc,
       _logger = logger,
       super(ProfileState(name: user.name ?? '')) {
    on<ProfileNameChanged>(_onProfileNameChanged);
    on<ProfileImageChanged>(_onProfileImageChanged);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileDeletionRequested>(_onProfileDeletionRequested);
  }

  final DataRepository<User> _userRepository;
  final AuthRepository _authRepository;
  final MediaRepository _mediaRepository;
  final AppBloc _appBloc;
  final Logger _logger;

  void _onProfileNameChanged(
    ProfileNameChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onProfileImageChanged(
    ProfileImageChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(imageBytes: event.imageBytes));
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final currentUser = _appBloc.state.user;
    if (currentUser == null) {
      emit(state.copyWith(status: ProfileStatus.failure));
      return;
    }

    try {
      // Stage 1: Handle image upload if a new image was selected.
      // This is done independently of the profile data update. The backend
      // will handle linking the uploaded asset to the user via a webhook.
      if (state.imageBytes != null) {
        _logger.info('Uploading new profile image...');
        // We call uploadFile but we do not use the returned mediaAssetId to
        // update the user model directly. The client's job is just to upload.
        await _mediaRepository.uploadFile(
          fileBytes: state.imageBytes!,
          fileName: 'profile_image_${currentUser.id}.jpg',
          purpose: MediaAssetPurpose.userProfilePhoto,
        );
        _logger.info(
          'Profile image upload initiated for user ${currentUser.id}.',
        );
      }

      // Stage 2: Handle profile data updates (e.g., name).
      // We only proceed if there are actual changes to update.
      var userToUpdate = currentUser;
      var hasChanges = false;

      if (state.name != currentUser.name) {
        userToUpdate = userToUpdate.copyWith(name: ValueWrapper(state.name));
        hasChanges = true;
      }

      if (!hasChanges) {
        _logger.info('No profile data changes to update. Completing.');
        emit(state.copyWith(status: ProfileStatus.success));
        return;
      }

      _logger.info('Updating user profile data...');
      final updatedUser = currentUser.copyWith(name: ValueWrapper(state.name));

      final persistedUser = await _userRepository.update(
        id: currentUser.id,
        item: updatedUser,
      );

      // Propagate the updated user object to the global AppBloc.
      _appBloc.add(AppUserUpdated(persistedUser));

      emit(state.copyWith(status: ProfileStatus.success));
    } on HttpException catch (e, s) {
      _logger.severe('Failed to update profile', e, s);
      emit(state.copyWith(status: ProfileStatus.failure, error: e));
    }
  }

  Future<void> _onProfileDeletionRequested(
    ProfileDeletionRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    _logger.info('Dispatching AppAccountDeletionRequested to AppBloc.');

    // Delegate the deletion process to the AppBloc, which orchestrates
    // device un-registration and then account deletion.
    _appBloc.add(const AppAccountDeletionRequested());

    // The UI will be updated automatically by the AppBloc's state changes
    // (navigation away from this page). We don't need to emit success here.
  }
}
