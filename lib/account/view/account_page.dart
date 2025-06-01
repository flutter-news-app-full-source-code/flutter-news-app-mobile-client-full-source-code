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
    final status = appState.status;
    final isAnonymous = status == AppStatus.anonymous;
    final theme = Theme.of(context); // Get theme for AppBar
    final textTheme = theme.textTheme; // Get textTheme for AppBar

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.accountPageTitle,
          style: textTheme.titleLarge, // Consistent AppBar title style
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.paddingMedium), // Adjusted padding
        children: [
          _buildUserHeader(context, user, isAnonymous),
          const SizedBox(height: AppSpacing.lg), // Adjusted spacing
          ListTile(
            leading: Icon(Icons.tune_outlined, color: theme.colorScheme.primary),
            title: Text(
              l10n.accountContentPreferencesTile,
              style: textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.manageFollowedItemsName);
            },
          ),
          const Divider(indent: AppSpacing.paddingMedium, endIndent: AppSpacing.paddingMedium),
          ListTile(
            leading: Icon(Icons.bookmark_outline, color: theme.colorScheme.primary),
            title: Text(
              l10n.accountSavedHeadlinesTile,
              style: textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.accountSavedHeadlinesName);
            },
          ),
          const Divider(indent: AppSpacing.paddingMedium, endIndent: AppSpacing.paddingMedium),
          _buildSettingsTile(context),
          const Divider(indent: AppSpacing.paddingMedium, endIndent: AppSpacing.paddingMedium),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User? user, bool isAnonymous) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme; // Get colorScheme

    final avatarIcon = Icon(
      Icons.person_outline, // Use outlined version
      size: AppSpacing.xxl, // Standardized size
      color: colorScheme.onPrimaryContainer,
    );

    final String displayName;
    final Widget statusWidget;

    if (isAnonymous) {
      displayName = l10n.accountAnonymousUser;
      statusWidget = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md), // Increased padding
        child: ElevatedButton.icon( // Changed to ElevatedButton
          icon: const Icon(Icons.link_outlined),
          label: Text(l10n.accountSignInPromptButton),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm,
            ),
            textStyle: textTheme.labelLarge,
          ),
          onPressed: () {
            context.goNamed(
              Routes.authenticationName,
              queryParameters: {'context': 'linking'},
            );
          },
        ),
      );
    } else {
      displayName = user?.email ?? l10n.accountNoNameUser;
      statusWidget = Column(
        mainAxisSize: MainAxisSize.min, // To keep column tight
        children: [
          if (user?.role != null) ...[ // Show role only if available
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.accountRoleLabel(user!.role.name),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.md), // Consistent spacing
          OutlinedButton.icon( // Changed to OutlinedButton.icon
            icon: Icon(Icons.logout, color: colorScheme.error),
            label: Text(l10n.accountSignOutTile),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm,
              ),
              textStyle: textTheme.labelLarge,
            ),
            onPressed: () {
              context
                  .read<AuthenticationBloc>()
                  .add(const AuthenticationSignOutRequested());
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        CircleAvatar(
          radius: AppSpacing.xxl - AppSpacing.sm, // Standardized radius (40)
          backgroundColor: colorScheme.primaryContainer,
          child: avatarIcon,
        ),
        const SizedBox(height: AppSpacing.md), // Adjusted spacing
        Text(
          displayName,
          style: textTheme.headlineSmall, // More prominent style
          textAlign: TextAlign.center,
        ),
        statusWidget,
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ListTile(
      leading: Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
      title: Text(l10n.accountSettingsTile, style: textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.goNamed(Routes.settingsName);
      },
    );
  }
}
