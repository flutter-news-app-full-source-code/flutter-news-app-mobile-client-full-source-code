import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/shared.dart';
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
    final isAnonymous = context.select(
      (AppBloc bloc) => bloc.state.user?.isAnonymous ?? true,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.accountPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.accountSignOutTile,
            onPressed: () =>
                context.read<AppBloc>().add(const AppLogoutRequested()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            // The main column for the page content
            children: [
              _ProfileHeader(),
              const SizedBox(height: AppSpacing.lg),
              _NavigationSections(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final user = context.select((AppBloc bloc) => bloc.state.user);
    final isAnonymous = user?.isAnonymous ?? true;

    return Column(
      children: [
        Row(
          children: [
            UserAvatar(user: user, radius: 32),
            const SizedBox(width: AppSpacing.md),
            if (user != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnonymous ? l10n.guestUserDisplayName : user.name ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isAnonymous)
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(isAnonymous ? Icons.sync : Icons.edit_outlined),
            label: Text(
              isAnonymous
                  ? l10n.accountPageSyncProgressButton
                  : l10n.accountEditProfileButton,
            ),
            onPressed: () async {
              if (isAnonymous) {
                context.goNamed(Routes.accountLinkingName);
              } else {
                await context.pushNamed(Routes.editProfileName);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _NavigationSections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final areRewardsEnabled = context.select(
      (AppBloc bloc) =>
          bloc.state.remoteConfig?.features.rewards.enabled ?? false,
    );
    // Using a simple Column instead of a Card with a Column.
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.bookmark_outline),
          title: Text(l10n.accountSavedHeadlinesTile),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(Routes.accountSavedHeadlinesName),
        ),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(l10n.accountContentPreferencesTile),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(Routes.manageFollowedItemsName),
        ),
        BlocSelector<AppBloc, AppState, bool>(
          selector: (state) => state.hasUnreadInAppNotifications,
          builder: (context, showIndicator) {
            return ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: NotificationIndicator(
                showIndicator: showIndicator,
                child: Text(l10n.accountNotificationsTile),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(Routes.notificationsCenterName),
            );
          },
        ),
        if (areRewardsEnabled)
          ListTile(
            leading: const Icon(Icons.card_giftcard_outlined),
            title: Text(l10n.accountRewardsTile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(Routes.rewardsName),
          ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(l10n.accountSettingsTile),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(Routes.settingsName),
        ),
      ],
    );
  }
}
