import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/l10n/app_localizations.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_shared/ht_shared.dart' show HeadlineImageStyle;
import 'package:ht_ui_kit/ht_ui_kit.dart';

/// {@template feed_settings_page}
/// A page for configuring feed display settings.
/// {@endtemplate}
class FeedSettingsPage extends StatelessWidget {
  /// {@macro feed_settings_page}
  const FeedSettingsPage({super.key});

  // Helper to map HeadlineImageStyle enum to user-friendly strings
  String _imageStyleToString(HeadlineImageStyle style, AppLocalizations l10n) {
    switch (style) {
      case HeadlineImageStyle.hidden:
        return l10n.settingsFeedTileTypeTextOnly;
      case HeadlineImageStyle.smallThumbnail:
        return l10n.settingsFeedTileTypeImageStart;
      case HeadlineImageStyle.largeThumbnail:
        return l10n.settingsFeedTileTypeImageTop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final state = settingsBloc.state;

    // Ensure we have loaded state before building controls
    if (state.status != SettingsStatus.success) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsFeedDisplayTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, settingsState) {
        if (settingsState.status == SettingsStatus.success) {
          context.read<AppBloc>().add(const AppSettingsRefreshed());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsFeedDisplayTitle)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // --- Feed Tile Type ---
            _buildDropdownSetting<HeadlineImageStyle>(
              context: context,
              title: l10n.settingsFeedTileTypeLabel,
              currentValue:
                  state.userAppSettings!.feedPreferences.headlineImageStyle,
              items: HeadlineImageStyle.values,
              itemToString: (style) => _imageStyleToString(style, l10n),
              onChanged: (value) {
                if (value != null) {
                  settingsBloc.add(SettingsHeadlineImageStyleChanged(value));
                }
              },
            ),
          ],
        ),
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
