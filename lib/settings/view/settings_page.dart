import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart'; // Assuming sub-routes will be added here
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart'; // For loading/error

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
    // The SettingsBloc is expected to be provided by the GoRouter route definition.
    // No need to provide it here again.
    return const _SettingsView();
  }
}

/// The actual view widget for the main settings page.
class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        // Standard back button provided by Scaffold/GoRouter
        title: Text(l10n.settingsTitle), // Add l10n key: settingsTitle
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
              headline: l10n.settingsLoadingHeadline, // Add l10n key
              subheadline: l10n.settingsLoadingSubheadline, // Add l10n key
            );
          }

          // Handle error state
          if (state.status == SettingsStatus.failure) {
            return FailureStateWidget(
              message: state.error?.toString() ?? l10n.settingsErrorDefault, // Add l10n key
              onRetry: () => context
                  .read<SettingsBloc>()
                  .add(const SettingsLoadRequested()),
            );
          }

          // Display the list of settings categories
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.palette_outlined,
                title: l10n.settingsAppearanceTitle, // Add l10n key
                onTap: () => context.goNamed(Routes.settingsAppearanceName),
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              _buildSettingsTile(
                context: context,
                icon: Icons.feed_outlined,
                title: l10n.settingsFeedDisplayTitle, // Add l10n key
                onTap: () => context.goNamed(Routes.settingsFeedName),
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              _buildSettingsTile(
                context: context,
                icon: Icons.article_outlined,
                title: l10n.settingsArticleDisplayTitle, // Add l10n key
                onTap: () => context.goNamed(Routes.settingsArticleName),
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              _buildSettingsTile(
                context: context,
                icon: Icons.notifications_outlined,
                title: l10n.settingsNotificationsTitle, // Add l10n key
                onTap: () => context.goNamed(Routes.settingsNotificationsName),
              ),
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
