import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';


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
    final user = context.watch<AppBloc>().state.user;
    final status = user.authenticationStatus;

    // Determine if the user is anonymous
    final isAnonymous = status == AuthenticationStatus.anonymous;

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
          // Settings Tile is now the first actionable item below the header
          _buildSettingsTile(context),
          const Divider(), // Divider after settings
        ],
      ),
    );
  }

  /// Builds the header section displaying user avatar, name, and status.
  Widget _buildUserHeader(BuildContext context, User user, bool isAnonymous) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Use placeholder if photoUrl is null or empty
    final photoUrl = user.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          backgroundColor: theme.colorScheme.primaryContainer,
          // Show initials or icon if no photo
          child:
              !hasPhoto
                  ? Icon(
                    Icons.person,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                  : null,
        ),
        const SizedBox(height: AppSpacing.lg), // Use AppSpacing
        Text(
          isAnonymous
              ? l10n.accountAnonymousUser
              : user.displayName ?? l10n.accountNoNameUser,
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        // Conditionally display Sign In or Logout button
        if (isAnonymous)
          _buildSignInButton(context)
        else
          _buildLogoutButton(context),
      ],
    );
  }

  /// Builds the sign-in button for anonymous users.
  Widget _buildSignInButton(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
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
  }

  /// Builds the logout button for authenticated users.
  Widget _buildLogoutButton(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
        ),
        onPressed: () {
          context.read<AccountBloc>().add(const AccountLogoutRequested());
          // Global redirect will be handled by AppBloc/GoRouter
        },
        // Assuming l10n.accountSignOutButton exists or will be added
        // Reusing existing tile text for now as button text might differ
        child: Text(l10n.accountSignOutTile),
      ),
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
