import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_shared/ht_shared.dart'; // Use types from ht_shared

/// {@template appearance_settings_page}
/// A page for configuring appearance-related settings like theme and fonts.
/// {@endtemplate}
class AppearanceSettingsPage extends StatelessWidget {
  /// {@macro appearance_settings_page}
  const AppearanceSettingsPage({super.key});

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

  // Helper to map AppTextScaleFactor enum to user-friendly strings
  String _textScaleFactorToString(
    AppTextScaleFactor size,
    AppLocalizations l10n,
  ) {
    switch (size) {
      case AppTextScaleFactor.small:
        return l10n.settingsAppearanceFontSizeSmall;
      case AppTextScaleFactor.large:
        return l10n.settingsAppearanceFontSizeLarge;
      case AppTextScaleFactor.medium:
        return l10n.settingsAppearanceFontSizeMedium;
      case AppTextScaleFactor.extraLarge:
        return l10n.settingsAppearanceFontSizeExtraLarge; // Add l10n key
    }
  }

  // Helper to map font family string to user-friendly strings
  String _fontFamilyToString(String fontFamily, AppLocalizations l10n) {
    // This mapping might need to be more sophisticated if supporting multiple
    // specific fonts. For now, just return the string or a placeholder.
    // Consider adding specific l10n keys if needed, e.g., l10n.fontRoboto
    return fontFamily == 'SystemDefault'
        ? l10n
            .settingsAppearanceFontFamilySystemDefault // Add l10n key
        : fontFamily;
  }

  // TODO(cline): Replace with localized strings once localization issue is resolved.
  // Helper to map AppFontWeight enum to user-friendly strings (currently uses enum name)
  String _fontWeightToString(AppFontWeight weight, AppLocalizations l10n) {
    switch (weight) {
      case AppFontWeight.light:
        return 'Light'; // Temporary: Use enum name or placeholder
      case AppFontWeight.regular:
        return 'Regular'; // Temporary: Use enum name or placeholder
      case AppFontWeight.bold:
        return 'Bold'; // Temporary: Use enum name or placeholder
    }
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
                context.read<SettingsBloc>().add(
                  SettingsAppThemeNameChanged(value),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Text Scale Factor ---
          _buildDropdownSetting<AppTextScaleFactor>(
            context: context,
            title:
                l10n.settingsAppearanceAppFontSizeLabel, // Reusing key for text size
            currentValue: state.userAppSettings!.displaySettings.textScaleFactor,
            items: AppTextScaleFactor.values,
            itemToString: (size) => _textScaleFactorToString(size, l10n),
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(
                  SettingsAppFontSizeChanged(value),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Font Family ---
          _buildDropdownSetting<String>(
            // Font family is a String
            context: context,
            title:
                l10n.settingsAppearanceAppFontTypeLabel, // Reusing key for font family
            currentValue: state.userAppSettings!.displaySettings.fontFamily,
            items: const [
              'SystemDefault',
            ], // Only SystemDefault supported for now
            itemToString: (fontFamily) => _fontFamilyToString(fontFamily, l10n),
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(
                  SettingsAppFontTypeChanged(value),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Font Weight ---
          _buildDropdownSetting<AppFontWeight>(
            context: context,
            title: l10n.settingsAppearanceFontWeightLabel, // Add l10n key
            currentValue: state.userAppSettings!.displaySettings.fontWeight,
            items: AppFontWeight.values,
            itemToString:
                (weight) => _fontWeightToString(weight, l10n), // Use helper
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsAppFontWeightChanged(value));
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
