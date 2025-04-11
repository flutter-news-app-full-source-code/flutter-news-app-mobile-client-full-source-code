import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_preferences_client/ht_preferences_client.dart';

/// {@template article_settings_page}
/// A page for configuring article display settings.
/// {@endtemplate}
class ArticleSettingsPage extends StatelessWidget {
  /// {@macro article_settings_page}
  const ArticleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // SettingsBloc is provided by the parent route.
    return const _ArticleSettingsView();
  }
}

class _ArticleSettingsView extends StatelessWidget {
  const _ArticleSettingsView();

  // Helper to map FontSize enum to user-friendly strings
  String _fontSizeToString(FontSize size, AppLocalizations l10n) {
    switch (size) {
      case FontSize.small:
        return l10n.settingsAppearanceFontSizeSmall; // Reuse key
      case FontSize.large:
        return l10n.settingsAppearanceFontSizeLarge; // Reuse key
      case FontSize.medium:
      default:
        return l10n.settingsAppearanceFontSizeMedium; // Reuse key
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final state = settingsBloc.state;

    // Ensure we have loaded state before building controls
    if (state.status != SettingsStatus.success) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsArticleDisplayTitle)), // Reuse title
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsArticleDisplayTitle), // Reuse title
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // --- Article Font Size ---
          _buildDropdownSetting<FontSize>(
            context: context,
            title: l10n.settingsArticleFontSizeLabel, // Add l10n key
            currentValue: state.articleSettings.articleFontSize,
            items: FontSize.values,
            itemToString: (size) => _fontSizeToString(size, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsArticleFontSizeChanged(value));
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
