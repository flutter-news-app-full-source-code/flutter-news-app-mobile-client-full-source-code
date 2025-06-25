import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart';

/// {@template settings_page}
/// The main page for accessing different application settings categories.
///
/// Provides navigation to sub-pages for specific settings domains like
/// Appearance, Feed Display, Article Display, and Notifications.
/// {@endtemplate}
class SettingsPage extends StatelessWidget {
  /// {@macro settings_page}
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback if it can't pop, perhaps go to account page directly
              context.goNamed(Routes.accountName);
            }
          },
        ),
        title: Text(l10n.settingsTitle),
      ),
      // Use BlocBuilder to react to loading/error states if needed,
      // though the main list is often static.
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // Handle loading state if initial load happens here,
          // otherwise assume BLoC is loaded before page entry via router.
          if (state.status == SettingsStatus.loading) {
            return LoadingStateWidget(
              icon: Icons.settings_outlined,
              headline: l10n.settingsLoadingHeadline,
              subheadline: l10n.settingsLoadingSubheadline,
            );
          }

          // Handle error state
          if (state.status == SettingsStatus.failure) {
            return FailureStateWidget(
              message: state.error?.toString() ?? l10n.settingsErrorDefault,
              onRetry: () {
                // Access AppBloc to get the current user ID for retry
                final appBloc = context.read<AppBloc>();
                final userId = appBloc.state.user?.id;
                if (userId != null) {
                  context.read<SettingsBloc>().add(
                    SettingsLoadRequested(userId: userId),
                  );
                } else {
                  // Handle case where user is null on retry, though unlikely
                  // if router guards are effective.
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.unknownError)));
                }
              },
            );
          }

          // Display the list of settings categories
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.language_outlined,
                title: l10n.settingsLanguageTitle,
                onTap: () => context.goNamed(Routes.settingsLanguageName),
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              _buildSettingsTile(
                context: context,
                icon: Icons.palette_outlined,
                title: l10n.settingsAppearanceTitle,
                onTap: () => context.goNamed(Routes.settingsAppearanceName),
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              _buildSettingsTile(
                context: context,
                icon: Icons.feed_outlined,
                title: l10n.settingsFeedDisplayTitle,
                onTap: () => context.goNamed(Routes.settingsFeedName),
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              // _buildSettingsTile(
              //   context: context,
              //   icon: Icons.notifications_outlined,
              //   title: l10n.settingsNotificationsTitle,
              //   onTap: () => context.goNamed(Routes.settingsNotificationsName),
              // ),
            ],
          );
        },
      ),
    );
  }

  /// Helper to build a consistent ListTile for navigating to a settings sub-page.
  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
