import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template user_avatar}
/// A widget that displays a user's avatar.
///
/// If the user has an email, it displays the first letter of the email,
/// capitalized. Otherwise, it displays a generic person icon.
/// {@endtemplate}
class UserAvatar extends StatelessWidget {
  /// {@macro user_avatar}
  const UserAvatar({this.user, super.key});

  /// The user to display the avatar for. Can be null.
  final User? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasEmail = user?.email.isNotEmpty ?? false;

    return CircleAvatar(
      radius: AppSpacing.lg,
      backgroundColor: colorScheme.primaryContainer,
      child: hasEmail
          ? Text(
              user!.email.substring(0, 1).toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            )
          : Icon(Icons.person_outline, color: colorScheme.onPrimaryContainer),
    );
  }
}
