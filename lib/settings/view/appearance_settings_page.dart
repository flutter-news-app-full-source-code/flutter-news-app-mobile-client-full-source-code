import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_preferences_client/ht_preferences_client.dart';

/// {@template appearance_settings_page}
/// A page for configuring appearance-related settings like theme and fonts.
/// {@endtemplate}
class AppearanceSettingsPage extends StatelessWidget {
  /// {@macro appearance_settings_page}
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // SettingsBloc is provided by the parent route.
    return const _AppearanceSettingsView();
  }
}

class _AppearanceSettingsView extends StatelessWidget {
  const _AppearanceSettingsView();

  // Helper to map AppThemeMode enum to user-friendly strings
  String _themeModeToString(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.settingsAppearanceThemeModeLight; // Add l10n key
      case AppThemeMode.dark:
        return l10n.settingsAppearanceThemeModeDark; // Add l10n key
      case AppThemeMode.system:
        return l10n.settingsAppearanceThemeModeSystem; // Add l10n key
    }
  }

  // Helper to map AppThemeName enum to user-friendly strings
  String _themeNameToString(AppThemeName name, AppLocalizations l10n) {
    switch (name) {
      case AppThemeName.red:
        return l10n.settingsAppearanceThemeNameRed; // Add l10n key
      case AppThemeName.blue:
        return l10n.settingsAppearanceThemeNameBlue; // Add l10n key
      case AppThemeName.grey:
        return l10n.settingsAppearanceThemeNameGrey; // Add l10n key
    }
  }

  // Helper to map FontSize enum to user-friendly strings
  String _fontSizeToString(FontSize size, AppLocalizations l10n) {
    switch (size) {
      case FontSize.small:
        return l10n.settingsAppearanceFontSizeSmall; // Add l10n key
      case FontSize.large:
        return l10n.settingsAppearanceFontSizeLarge; // Add l10n key
      case FontSize.medium:
        return l10n.settingsAppearanceFontSizeMedium; // Add l10n key
    }
  }

  // Helper to map AppFontType enum to user-friendly strings
  // (Using the enum name directly might be sufficient if they are clear)
  String _fontTypeToString(AppFontType type, AppLocalizations l10n) {
    // Consider adding specific l10n keys if needed, e.g., l10n.fontRoboto
    return type.name; // Example: 'roboto', 'openSans'
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final state = settingsBloc.state;

    // Ensure we have loaded state before building controls
    if (state.status != SettingsStatus.success) {
      // Can show a minimal loading/error or rely on parent page handling
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
        body: const Center(
          child: CircularProgressIndicator(),
        ), // Simple loading
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsAppearanceTitle), // Reuse title key
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // --- Theme Mode ---
          _buildDropdownSetting<AppThemeMode>(
            context: context,
            title: l10n.settingsAppearanceThemeModeLabel, // Add l10n key
            currentValue: state.themeSettings.themeMode,
            items: AppThemeMode.values,
            itemToString: (mode) => _themeModeToString(mode, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsAppThemeModeChanged(value));
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Theme Name ---
          _buildDropdownSetting<AppThemeName>(
            context: context,
            title: l10n.settingsAppearanceThemeNameLabel, // Add l10n key
            currentValue: state.themeSettings.themeName,
            items: AppThemeName.values,
            itemToString: (name) => _themeNameToString(name, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsAppThemeNameChanged(value));
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- App Font Size ---
          _buildDropdownSetting<FontSize>(
            context: context,
            title: l10n.settingsAppearanceAppFontSizeLabel, // Add l10n key
            currentValue: state.appSettings.appFontSize,
            items: FontSize.values,
            itemToString: (size) => _fontSizeToString(size, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsAppFontSizeChanged(value));
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- App Font Type ---
          _buildDropdownSetting<AppFontType>(
            context: context,
            title: l10n.settingsAppearanceAppFontTypeLabel, // Add l10n key
            currentValue: state.appSettings.appFontType,
            items: AppFontType.values,
            itemToString: (type) => _fontTypeToString(type, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsAppFontTypeChanged(value));
              }
            },
          ),
        ],
      ),
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
          items:
              items.map((T value) {
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
