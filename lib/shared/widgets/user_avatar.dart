import 'package:core/core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template user_avatar}
/// A widget that displays a user's avatar.
///
/// If the user has an email, it displays the first letter of the email,
/// capitalized. Otherwise, it displays a generic person icon.
/// {@endtemplate}
class UserAvatar extends StatelessWidget {
  /// {@macro user_avatar}
  const UserAvatar({
    this.user,
    this.radius = AppSpacing.lg,
    this.overrideImage,
    super.key,
  });

  /// The user to display the avatar for. Can be null.
  final User? user;

  /// The radius of the circle avatar. Defaults to [AppSpacing.lg].
  final double radius;

  /// An optional image provider to override the user's photo.
  /// Used for showing a preview of a newly selected image.
  final ImageProvider? overrideImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final optimisticAvatar = context.select(
      (AppBloc bloc) => bloc.state.optimisticAvatarBytes,
    );

    final localUser = user;
    // Determine which content to show based on a priority order.
    Widget child;
    ImageProvider? backgroundImage;

    // Priority 1: An explicit override image (used for local previews on the
    // edit page).
    if (overrideImage != null) {
      backgroundImage = overrideImage;
      child = const SizedBox.shrink();
      // Priority 2: An optimistic avatar from a recent upload, held in the
      // global state.
    } else if (optimisticAvatar != null) {
      backgroundImage = MemoryImage(optimisticAvatar);
      child = const SizedBox.shrink();
      // Priority 3: The permanent, backend-confirmed photo URL.
    } else if (localUser?.photoUrl != null && localUser!.photoUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(localUser.photoUrl!);
      child = const SizedBox.shrink();
    } else if (localUser?.mediaAssetId != null &&
        localUser!.mediaAssetId!.isNotEmpty) {
      // Show a "processing" state if mediaAssetId exists but photoUrl doesn't.
      child = CupertinoActivityIndicator(color: colorScheme.onPrimaryContainer);
    } else if (localUser != null &&
        !localUser.isAnonymous &&
        localUser.name != null &&
        localUser.name!.isNotEmpty) {
      // Show initial for non-anonymous users with a name.
      child = Text(
        localUser.name!.substring(0, 1).toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
          fontSize: radius * 0.8,
        ),
      );
    } else {
      // Fallback for anonymous users or users without a name.
      child = Icon(
        Icons.person_outline,
        color: colorScheme.onPrimaryContainer,
        size: radius,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: backgroundImage,
      child: child,
    );
  }
}
