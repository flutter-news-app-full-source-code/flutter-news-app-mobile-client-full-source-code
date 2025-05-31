import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_shared/ht_shared.dart' show AppLanguage;

// Defines the available languages and their display names.
// In a real app, this might come from a configuration or be more dynamic.
const Map<String, String> _supportedLanguages = {
  'en': 'English',
  'ar': 'العربية (Arabic)',
};

/// {@template language_settings_page}
/// A page for selecting the application language.
/// {@endtemplate}
class LanguageSettingsPage extends StatelessWidget {
  /// {@macro language_settings_page}
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final settingsState = settingsBloc.state;

    if (settingsState.status != SettingsStatus.success ||
        settingsState.userAppSettings == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)), // Placeholder l10n key
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentLanguage = settingsState.userAppSettings!.language;

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.status == SettingsStatus.success) {
          context.read<AppBloc>().add(const AppSettingsRefreshed());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)), // Placeholder l10n key
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: _supportedLanguages.length,
          separatorBuilder: (context, index) =>
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          itemBuilder: (context, index) {
            final languageCode = _supportedLanguages.keys.elementAt(index);
            final languageName = _supportedLanguages.values.elementAt(index);
            final isSelected = languageCode == currentLanguage;

            return ListTile(
              title: Text(languageName),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                if (!isSelected) {
                  // Dispatch event to SettingsBloc
                  context
                      .read<SettingsBloc>()
                      .add(SettingsLanguageChanged(languageCode));
                }
              },
            );
          },
        ),
      ),
    );
  }
}
