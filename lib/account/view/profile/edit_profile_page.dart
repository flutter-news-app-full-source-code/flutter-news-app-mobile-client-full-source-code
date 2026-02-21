import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/profile_bloc/profile_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template edit_profile_page}
/// A page that allows authenticated users to edit their profile information,
/// including their name, email, and profile picture.
/// {@endtemplate}
class EditProfilePage extends StatelessWidget {
  /// {@macro edit_profile_page}
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);

    if (user == null) {
      // This should not happen due to router guards, but as a fallback.
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return BlocProvider<ProfileBloc>(
      create: (context) {
        final bloc = ProfileBloc(
          user: user,
          userRepository: context.read<DataRepository<User>>(),
          mediaRepository: context.read<MediaRepository>(),
          appBloc: context.read<AppBloc>(),
          logger: context.read<Logger>(),
        );
        // Pre-fill the name field with the email prefix if the name is not set.
        if (user.name == null || user.name!.isEmpty) {
          bloc.add(ProfileNameChanged(user.email.split('@').first));
        }
        return bloc;
      },
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  Uint8List? _selectedImageBytes;

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedImageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final user = context.select((AppBloc bloc) => bloc.state.user)!;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.editProfileUpdateSuccessSnackbar)),
            );
          context.pop();
        } else if (state.status == ProfileStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.editProfileUpdateFailureSnackbar),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editProfilePageTitle),
          actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state.status == ProfileStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return TextButton(
                  onPressed: () => context.read<ProfileBloc>().add(
                    ProfileUpdateRequested(imageBytes: _selectedImageBytes),
                  ),
                  child: Text(l10n.saveButtonLabel),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickImage(context),
                child: Stack(
                  children: [
                    UserAvatar(
                      user: user,
                      radius: 60,
                      overrideImage: _selectedImageBytes != null
                          ? MemoryImage(_selectedImageBytes!)
                          : null,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  return TextFormField(
                    initialValue: state.name,
                    decoration: InputDecoration(
                      labelText: l10n.editProfileNameInputLabel,
                    ),
                    onChanged: (value) => context.read<ProfileBloc>().add(
                      ProfileNameChanged(value),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        title: l10n.deleteAccountDialogTitle,
                        content: l10n.deleteAccountDialogContent,
                        confirmButtonText: l10n.deleteAccountDialogConfirm,
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<ProfileBloc>().add(
                        const ProfileDeletionRequested(),
                      );
                    }
                  },
                  child: Text(l10n.deleteAccountButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
