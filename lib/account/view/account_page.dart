import 'package:core/core.dart' hide AppStatus;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template account_page}
/// A full-screen modal page that displays user account information and actions.
///
/// This page serves as the main entry point for all account-related
/// sections like settings, saved items, and content preferences.
/// {@endtemplate}
class AccountPage extends StatelessWidget {
  /// {@macro account_page}
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    // Watch AppBloc for user details and authentication status
    final appState = context.watch<AppBloc>().state;
    final user = appState.user;
    final status = appState.status;
    final isAnonymous = status == AppLifeCycleStatus.anonymous;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.bottomNavAccountLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(Routes.settingsName),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserHeader(context, user, isAnonymous),
              const SizedBox(height: AppSpacing.lg),
              _buildNavigationList(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header section of the sheet, displaying the user's avatar,
  /// name, and a primary action button (Sign Out or Link Account).
  Widget _buildUserHeader(BuildContext context, User? user, bool isAnonymous) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String statusText;
    final String accountTypeText;
    final Widget actionButton;

    if (isAnonymous) {
      statusText = l10n.accountAnonymousUser;
      accountTypeText = l10n.accountGuestAccount;
      actionButton = _buildSignInButton(context);
    } else {
      statusText = user?.email ?? l10n.accountNoNameUser;

      final String roleDisplayName;
      switch (user?.appRole) {
        case AppUserRole.standardUser:
          roleDisplayName = l10n.accountRoleStandard;
        case AppUserRole.premiumUser:
          roleDisplayName = l10n.accountRolePremium;
        case AppUserRole.guestUser:
          roleDisplayName = l10n.accountGuestAccount;
        case null:
          roleDisplayName = '';
      }
      accountTypeText = roleDisplayName;
      actionButton = _buildSignOutButton(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                width: AppSpacing.xxl + AppSpacing.sm,
                height: AppSpacing.xxl + AppSpacing.sm,
                color: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: AppSpacing.xl,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (accountTypeText.isNotEmpty)
                    Text(
                      accountTypeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            actionButton,
          ],
        ),
      ),
    );
  }

  /// Builds the sign-in button for anonymous users.
  Widget _buildSignInButton(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return ElevatedButton(
      onPressed: () => context.goNamed(Routes.accountLinkingName),
      child: Text(l10n.accountSignInPromptButton),
    );
  }

  /// Builds the sign-out button for authenticated users.
  Widget _buildSignOutButton(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return OutlinedButton(
      onPressed: () => context.read<AuthenticationBloc>().add(
        const AuthenticationSignOutRequested(),
      ),
      child: Text(l10n.accountSignOutTile),
    );
  }

  /// Builds the list of navigation tiles for accessing different
  /// account-related sections.
  Widget _buildNavigationList(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Helper to create a ListTile with consistent styling.
    Widget buildTile({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) {
      return ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: textTheme.titleMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }

    return Column(
      children: [
        buildTile(
          icon: Icons.tune_outlined,
          title: l10n.accountContentPreferencesTile,
          onTap: () => context.pushNamed(Routes.manageFollowedItemsName),
        ),
        const Divider(),
        buildTile(
          icon: Icons.bookmark_outline,
          title: l10n.accountSavedHeadlinesTile,
          onTap: () => context.pushNamed(Routes.accountSavedHeadlinesName),
        ),
        const Divider(),
        buildTile(
          icon: Icons.filter_alt_outlined,
          title: l10n.accountSavedFiltersTile,
          onTap: () => context.pushNamed(Routes.accountSavedFiltersName),
        ),
        const Divider(),
      ],
    );
  }
}
