import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Import the User model and AuthenticationStatus enum
import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // Needed for AppBloc and AppState access
// Remove direct import of app_state.dart when using part of
import 'package:ht_main/l10n/l10n.dart'; // Added import
import 'package:ht_main/router/routes.dart'; // Needed for route names

/// {@template account_page}
/// Page widget for the Account feature.
/// Provides the [AccountBloc] to its descendants.
/// {@endtemplate}
class AccountPage extends StatelessWidget {
  /// {@macro account_page}
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => AccountBloc(
            authenticationRepository:
                context.read<HtAuthenticationRepository>(),
          ),
      // Use BlocListener if specific feedback (like snackbars for errors)
      // is needed from AccountBloc actions, though redirects are handled
      // globally.
      child: const _AccountView(),
    );
  }
}

/// {@template account_view}
/// Displays the user's account information and actions.
/// Adapts UI based on authentication status (authenticated vs. anonymous).
/// {@endtemplate}
class _AccountView extends StatelessWidget {
  /// {@macro account_view}
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Watch AppBloc for user details and authentication status
    final user = context.watch<AppBloc>().state.user;
    final status = user.authenticationStatus; // Use status from User model

    // Determine if the user is anonymous
    final isAnonymous = status == AuthenticationStatus.anonymous;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountPageTitle)),
      body: ListView(
        // Use ListView for potential scrolling if content grows
        padding: const EdgeInsets.all(16),
        children: [
          // --- User Header ---
          _buildUserHeader(context, user, isAnonymous),
          const SizedBox(height: 24),

          // --- Action Tiles ---
          _buildSettingsTile(context),
          const Divider(), // Visual separator
          if (isAnonymous)
            _buildBackupTile(context) // Show Backup CTA for anonymous
          else
            _buildLogoutTile(context), // Show Logout for authenticated
          const Divider(),
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
        const SizedBox(height: 16),
        Text(
          isAnonymous
              ? l10n.accountAnonymousUser
              : user.displayName ?? l10n.accountNoNameUser,
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          // Convert enum to user-friendly string
          _authenticationStatusToString(
            context,
            user.authenticationStatus,
          ), // Pass context
          style: textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
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

  /// Builds the ListTile for logging out (for authenticated users).
  Widget _buildLogoutTile(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
      title: Text(
        l10n.accountSignOutTile,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      onTap: () {
        // Add the logout event to the AccountBloc
        context.read<AccountBloc>().add(const AccountLogoutRequested());
        // Global redirect will be handled by AppBloc/GoRouter
      },
    );
  }

  /// Builds the ListTile prompting anonymous users to sign in/connect.
  Widget _buildBackupTile(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(Icons.link), // Icon suggesting connection/linking
      title: Text(l10n.accountConnectPrompt), // New l10n key needed
      subtitle: Text(l10n.accountConnectBenefit), // New l10n key needed
      isThreeLine: true, // Allow more space for subtitle
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to the authentication page in linking mode
        context.goNamed(
          Routes.authenticationName,
          queryParameters: {'context': 'linking'},
        );
      },
    );
  }

  /// Helper to convert AuthenticationStatus enum to a display string.
  String _authenticationStatusToString(
    BuildContext context,
    AuthenticationStatus status,
  ) {
    final l10n = context.l10n;
    switch (status) {
      case AuthenticationStatus.authenticated:
        return l10n.accountStatusAuthenticated;
      case AuthenticationStatus.anonymous:
        return l10n.accountStatusAnonymous;
      case AuthenticationStatus.unauthenticated:
        return l10n.accountStatusUnauthenticated;
    }
  }
}
