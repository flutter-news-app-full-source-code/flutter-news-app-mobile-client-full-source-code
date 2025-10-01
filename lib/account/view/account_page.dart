import 'package:core/core.dart' hide AppStatus;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template account_view}
/// Displays the user's account information and actions.
/// Adapts UI based on authentication status (authenticated vs. anonymous).
/// {@endtemplate}
class AccountPage extends StatelessWidget {
  /// {@macro account_view}
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    // Watch AppBloc for user details and authentication status
    final appState = context.watch<AppBloc>().state;
    final user = appState.user;
    final status = appState.status;
    final isAnonymous = status == AppLifeCycleStatus.anonymous;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountPageTitle, style: textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.paddingMedium),
        children: [
          _buildUserHeader(context, user, isAnonymous),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: Icon(
              Icons.tune_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              l10n.accountContentPreferencesTile,
              style: textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.manageFollowedItemsName);
            },
          ),
          const Divider(
            indent: AppSpacing.paddingMedium,
            endIndent: AppSpacing.paddingMedium,
          ),
          ListTile(
            leading: Icon(
              Icons.bookmark_outline,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              l10n.accountSavedHeadlinesTile,
              style: textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.accountSavedHeadlinesName);
            },
          ),
          const Divider(
            indent: AppSpacing.paddingMedium,
            endIndent: AppSpacing.paddingMedium,
          ),
          _buildSettingsTile(context),
          const Divider(
            indent: AppSpacing.paddingMedium,
            endIndent: AppSpacing.paddingMedium,
          ),
        ],
      ),
    );
  }

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
          // Changed to ElevatedButton
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
            context.goNamed(
              Routes.authenticationName,
              queryParameters: {'authContext': 'linking'},
            );
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
            // Changed to OutlinedButton.icon
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

  Widget _buildSettingsTile(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
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
