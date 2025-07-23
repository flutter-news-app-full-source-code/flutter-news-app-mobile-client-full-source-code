import 'package:core/core.dart' show AppFontWeight, AppTextScaleFactor;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/bloc/settings_bloc.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template font_settings_page}
/// A page for configuring font-related settings like size, family, and weight.
/// {@endtemplate}
class FontSettingsPage extends StatelessWidget {
  /// {@macro font_settings_page}
  const FontSettingsPage({super.key});

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
        return l10n.settingsAppearanceFontSizeExtraLarge;
    }
  }

  // Helper to map font family string to user-friendly strings
  String _fontFamilyToString(String fontFamily, AppLocalizations l10n) {
    return fontFamily == 'SystemDefault'
        ? l10n.settingsAppearanceFontFamilySystemDefault
        : fontFamily;
  }

  // Helper to map AppFontWeight enum to user-friendly strings
  String _fontWeightToString(AppFontWeight weight, AppLocalizations l10n) {
    switch (weight) {
      case AppFontWeight.light:
        return l10n.settingsAppearanceFontWeightLight;
      case AppFontWeight.regular:
        return l10n.settingsAppearanceFontWeightRegular;
      case AppFontWeight.bold:
        return l10n.settingsAppearanceFontWeightBold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final state = settingsBloc.state;

    if (state.status != SettingsStatus.success ||
        state.userAppSettings == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, settingsState) {
        // Renamed state to avoid conflict
        if (settingsState.status == SettingsStatus.success) {
          context.read<AppBloc>().add(const AppSettingsRefreshed());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // --- Text Scale Factor ---
            _buildDropdownSetting<AppTextScaleFactor>(
              context: context,
              title: l10n.settingsAppearanceAppFontSizeLabel,
              currentValue:
                  state.userAppSettings!.displaySettings.textScaleFactor,
              items: AppTextScaleFactor.values,
              itemToString: (size) => _textScaleFactorToString(size, l10n),
              onChanged: (value) {
                if (value != null) {
                  settingsBloc.add(SettingsAppFontSizeChanged(value));
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Font Family ---
            _buildDropdownSetting<String>(
              context: context,
              title: l10n.settingsAppearanceAppFontTypeLabel,
              currentValue: state.userAppSettings!.displaySettings.fontFamily,
              items: const [
                'SystemDefault',
                'Roboto',
                'OpenSans',
                'Lato',
                'Montserrat',
                'Merriweather',
              ],
              itemToString: (fontFamily) =>
                  _fontFamilyToString(fontFamily, l10n),
              onChanged: (value) {
                if (value != null) {
                  settingsBloc.add(SettingsAppFontTypeChanged(value));
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Font Weight ---
            _buildDropdownSetting<AppFontWeight>(
              context: context,
              title: l10n.settingsAppearanceFontWeightLabel,
              currentValue: state.userAppSettings!.displaySettings.fontWeight,
              items: AppFontWeight.values,
              itemToString: (weight) => _fontWeightToString(weight, l10n),
              onChanged: (value) {
                if (value != null) {
                  settingsBloc.add(SettingsAppFontWeightChanged(value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
