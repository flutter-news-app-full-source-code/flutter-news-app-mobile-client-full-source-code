import 'package:core/core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template theme_and_font_settings_page}
/// A page for configuring theme accent color and font settings.
/// {@endtemplate}
class ThemeAndFontSettingsPage extends StatelessWidget {
  /// {@macro theme_and_font_settings_page}
  const ThemeAndFontSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final settings = context.select((AppBloc bloc) => bloc.state.settings);

    if (settings == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAccentColorAndFontsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAccentColorAndFontsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxDialogContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SectionTitle(title: l10n.settingsAccentColorLabel),
              const SizedBox(height: AppSpacing.md),
              _AccentThemeSelector(settings: settings),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(title: l10n.settingsAppearanceFontWeightLabel),
              const SizedBox(height: AppSpacing.md),
              _FontWeightSelector(settings: settings),
              const SizedBox(height: AppSpacing.xxl),
              _FontFamilySelector(settings: settings),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _AccentThemeSelector extends StatelessWidget {
  const _AccentThemeSelector({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: AppAccentTheme.values.map((theme) {
        final isSelected = settings.displaySettings.accentTheme == theme;
        final color = _getThemeColor(context, theme);

        return GestureDetector(
          onTap: () {
            context.read<AppBloc>().add(
              AppSettingsChanged(
                settings.copyWith(
                  displaySettings: settings.displaySettings.copyWith(
                    accentTheme: theme,
                  ),
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getThemeColor(BuildContext context, AppAccentTheme theme) {
    final FlexScheme scheme;
    switch (theme) {
      case AppAccentTheme.defaultBlue:
        scheme = FlexScheme.shadBlue;
      case AppAccentTheme.newsRed:
        scheme = FlexScheme.shadRed;
      case AppAccentTheme.graphiteGray:
        scheme = FlexScheme.shadGray;
    }
    final themeData = FlexThemeData.light(scheme: scheme);
    return themeData.primaryColor;
  }
}

class _FontWeightSelector extends StatelessWidget {
  const _FontWeightSelector({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return SegmentedButton<AppFontWeight>(
      segments: [
        ButtonSegment(
          value: AppFontWeight.light,
          label: Text(l10n.settingsAppearanceFontWeightLight),
        ),
        ButtonSegment(
          value: AppFontWeight.regular,
          label: Text(l10n.settingsAppearanceFontWeightRegular),
        ),
        ButtonSegment(
          value: AppFontWeight.bold,
          label: Text(l10n.settingsAppearanceFontWeightBold),
        ),
      ],
      selected: {settings.displaySettings.fontWeight},
      onSelectionChanged: (newSelection) {
        context.read<AppBloc>().add(
          AppSettingsChanged(
            settings.copyWith(
              displaySettings: settings.displaySettings.copyWith(
                fontWeight: newSelection.first,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FontFamilySelector extends StatelessWidget {
  const _FontFamilySelector({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final fontDisplayNames = {
      'SystemDefault': l10n.settingsAppearanceFontFamilySystemDefault,
      'Roboto': l10n.settingsAppearanceFontFamilyRoboto,
      'OpenSans': l10n.settingsAppearanceFontFamilyOpenSans,
    };

    return DropdownButtonFormField<String>(
      value: settings.displaySettings.fontFamily,
      decoration: InputDecoration(
        labelText: l10n.settingsFontFamilyLabel,
        border: const OutlineInputBorder(),
      ),
      items: fontDisplayNames.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          context.read<AppBloc>().add(
            AppSettingsChanged(
              settings.copyWith(
                displaySettings: settings.displaySettings.copyWith(
                  fontFamily: value,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
