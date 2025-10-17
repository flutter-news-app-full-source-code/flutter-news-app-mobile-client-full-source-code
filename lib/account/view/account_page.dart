import 'package:core/core.dart' hide AppStatus;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
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
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final avatarIcon = Icon(
      Icons.person_outline,
      size: AppSpacing.xxl,
      color: colorScheme.onPrimaryContainer,
    );

    final String displayName;
    final Widget statusWidget;

    if (isAnonymous) {
      displayName = l10n.accountAnonymousUser;
      statusWidget = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.link_outlined),
          label: Text(l10n.accountSignInPromptButton),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            textStyle: textTheme.labelLarge,
          ),
          onPressed: () {
            // Navigate directly to the linking flow.
            context.goNamed(Routes.accountLinkingName);
          },
        ),
      );
    } else {
      displayName = user?.email ?? l10n.accountNoNameUser;
      statusWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            icon: Icon(Icons.logout, color: colorScheme.error),
            label: Text(l10n.accountSignOutTile),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              textStyle: textTheme.labelLarge,
            ),
            onPressed: () {
              // Dispatch sign-out event.
              context.read<AuthenticationBloc>().add(
                const AuthenticationSignOutRequested(),
              );
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        CircleAvatar(
          radius: AppSpacing.xxl - AppSpacing.sm,
          backgroundColor: colorScheme.primaryContainer,
          child: avatarIcon,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          displayName,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        statusWidget,
      ],
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
