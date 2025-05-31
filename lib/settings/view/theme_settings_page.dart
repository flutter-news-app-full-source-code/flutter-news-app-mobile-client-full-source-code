import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // Import AppBloc and events
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_shared/ht_shared.dart' show AppBaseTheme, AppAccentTheme;

/// {@template theme_settings_page}
/// A page for configuring theme-related settings like base and accent themes.
/// {@endtemplate}
class ThemeSettingsPage extends StatelessWidget {
  /// {@macro theme_settings_page}
  const ThemeSettingsPage({super.key});

  // Helper to map AppBaseTheme enum to user-friendly strings
  String _baseThemeToString(AppBaseTheme mode, AppLocalizations l10n) {
    switch (mode) {
      case AppBaseTheme.light:
        return l10n.settingsAppearanceThemeModeLight;
      case AppBaseTheme.dark:
        return l10n.settingsAppearanceThemeModeDark;
      case AppBaseTheme.system:
        return l10n.settingsAppearanceThemeModeSystem;
    }
  }

  // Helper to map AppAccentTheme enum to user-friendly strings
  String _accentThemeToString(AppAccentTheme name, AppLocalizations l10n) {
    switch (name) {
      case AppAccentTheme.newsRed:
        return l10n.settingsAppearanceThemeNameRed;
      case AppAccentTheme.defaultBlue:
        return l10n.settingsAppearanceThemeNameBlue;
      case AppAccentTheme.graphiteGray:
        return l10n.settingsAppearanceThemeNameGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final state = settingsBloc.state;

    // Ensure we have loaded state before building controls
    // This page should only be reached if settings are successfully loaded
    // by the parent ShellRoute providing SettingsBloc.
    if (state.status != SettingsStatus.success ||
        state.userAppSettings == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, settingsState) { // Renamed state to avoid conflict
        if (settingsState.status == SettingsStatus.success) {
          // Check if it's a successful update, not just initial load
          // A more robust check might involve comparing previous and current userAppSettings
          // For now, refreshing on any success after an interaction is reasonable.
          // Ensure AppBloc is available in context before reading
          context.read<AppBloc>().add(const AppSettingsRefreshed());
        }
        // Optionally, show a SnackBar for errors if not handled globally
        // if (settingsState.status == SettingsStatus.failure && settingsState.error != null) {
        //   ScaffoldMessenger.of(context)
        //     ..hideCurrentSnackBar()
        //     ..showSnackBar(SnackBar(content: Text('Error: ${settingsState.error}')));
        // }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
        body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // --- Base Theme ---
          _buildDropdownSetting<AppBaseTheme>(
            context: context,
            title: l10n.settingsAppearanceThemeModeLabel,
            currentValue: state.userAppSettings!.displaySettings.baseTheme,
            items: AppBaseTheme.values,
            itemToString: (mode) => _baseThemeToString(mode, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsAppThemeModeChanged(value));
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Accent Theme ---
          _buildDropdownSetting<AppAccentTheme>(
            context: context,
            title: l10n.settingsAppearanceThemeNameLabel,
            currentValue: state.userAppSettings!.displaySettings.accentTheme,
            items: AppAccentTheme.values,
            itemToString: (name) => _accentThemeToString(name, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsAppThemeNameChanged(value));
              }
            },
          ),
        ],
      ),
      ), // Correctly close BlocListener's child Scaffold
    );
  }

  /// Generic helper to build a setting row with a title and a dropdown.
  Widget _buildDropdownSetting<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<T> items,
    required String Function(T) itemToString,
    required ValueChanged<T?> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          value: currentValue,
          items: items.map((T value) {
            return DropdownMenuItem<T>(
              value: value,
              child: Text(itemToString(value)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}
