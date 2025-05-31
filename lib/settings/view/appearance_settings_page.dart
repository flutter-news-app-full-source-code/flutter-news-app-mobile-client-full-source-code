import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template appearance_settings_page}
/// A menu page for navigating to theme and font appearance settings.
/// {@endtemplate}
class AppearanceSettingsPage extends StatelessWidget {
  /// {@macro appearance_settings_page}
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // SettingsBloc is watched to ensure settings are loaded,
    // though this page itself doesn't dispatch events.
    final settingsState = context.watch<SettingsBloc>().state;

    if (settingsState.status != SettingsStatus.success) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(
              l10n.settingsAppearanceThemeSubPageTitle,
            ), // Use new l10n key
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.settingsAppearanceThemeName);
            },
          ),
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.font_download_outlined),
            title: Text(
              l10n.settingsAppearanceFontSubPageTitle,
            ), // Use new l10n key
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.settingsAppearanceFontName);
            },
          ),
        ],
      ),
    );
  }
}
