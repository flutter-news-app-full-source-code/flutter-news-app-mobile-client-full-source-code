import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart'; // Import AuthenticationBloc
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_shared/ht_shared.dart'; // Import User and AppStatus

/// {@template account_view}
/// Displays the user's account information and actions.
/// Adapts UI based on authentication status (authenticated vs. anonymous).
/// {@endtemplate}
class AccountPage extends StatelessWidget {
  /// {@macro account_view}
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Watch AppBloc for user details and authentication status
    final appState = context.watch<AppBloc>().state;
    final user = appState.user;
    final status = appState.status; // Use AppStatus from AppBloc state

    // Determine if the user is anonymous
    final isAnonymous =
        status == AppStatus.anonymous; // Use AppStatus.anonymous

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountPageTitle)),
      body: ListView(
        // Use ListView for potential scrolling if content grows
        padding: const EdgeInsets.all(AppSpacing.lg), // Use AppSpacing
        children: [
          // --- User Header ---
          _buildUserHeader(context, user, isAnonymous),
          const SizedBox(height: AppSpacing.xl), // Use AppSpacing
          // --- Action Tiles ---
          // Content Preferences Tile
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: Text(l10n.accountContentPreferencesTile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.accountContentPreferencesName);
            },
          ),
          const Divider(), // Divider after Content Preferences
          // Saved Headlines Tile
          ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: Text(l10n.accountSavedHeadlinesTile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.accountSavedHeadlinesName);
            },
          ),
          const Divider(), // Divider after Saved Headlines
          // Settings Tile
          _buildSettingsTile(context),
          const Divider(), // Divider after settings
        ],
      ),
    );
  }

  /// Builds the header section displaying user avatar, name, and status.
  Widget _buildUserHeader(BuildContext context, User? user, bool isAnonymous) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Use a generic icon for the avatar
    const avatarIcon = Icon(Icons.person, size: 40);

    // Determine display name and status text
    final String displayName;
    final Widget statusWidget;

    if (isAnonymous) {
      displayName = l10n.accountAnonymousUser;
      statusWidget = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: TextButton(
          onPressed: () {
            // Navigate to the authentication page in linking mode
            context.goNamed(
              Routes.authenticationName,
              queryParameters: {'context': 'linking'},
            );
          },
          child: Text(l10n.accountSignInPromptButton),
        ),
      );
    } else {
      // For authenticated users, display email and role
      displayName = user?.email ?? l10n.accountNoNameUser;
      statusWidget = Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.accountRoleLabel(user?.role.name ?? 'unknown'), // Display role
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: () {
              // Dispatch AuthenticationSignOutRequested from Auth Bloc
              context.read<AuthenticationBloc>().add(
                const AuthenticationSignOutRequested(),
              );
              // Global redirect will be handled by AppBloc/GoRouter
            },
            child: Text(l10n.accountSignOutTile),
          ),
        ],
      );
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: avatarIcon,
        ),
        const SizedBox(height: AppSpacing.lg), // Use AppSpacing
        Text(
          displayName,
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        statusWidget, // Display sign-in button or role/logout button
      ],
    );
  }

  /// Builds the ListTile for navigating to Settings.
  Widget _buildSettingsTile(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(Icons.settings_outlined),
      title: Text(l10n.accountSettingsTile),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to the existing settings route
        context.goNamed(Routes.settingsName);
      },
    );
  }
}
