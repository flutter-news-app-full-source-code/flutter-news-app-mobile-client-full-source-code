import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/settings/bloc/settings_bloc.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_preferences_client/ht_preferences_client.dart';

/// {@template feed_settings_page}
/// A page for configuring feed display settings.
/// {@endtemplate}
class FeedSettingsPage extends StatelessWidget {
  /// {@macro feed_settings_page}
  const FeedSettingsPage({super.key});

  // Helper to map FeedListTileType enum to user-friendly strings
  String _tileTypeToString(FeedListTileType type, AppLocalizations l10n) {
    switch (type) {
      case FeedListTileType.imageTop:
        return l10n.settingsFeedTileTypeImageTop; // Add l10n key
      case FeedListTileType.imageStart:
        return l10n.settingsFeedTileTypeImageStart; // Add l10n key
      case FeedListTileType.textOnly:
        return l10n.settingsFeedTileTypeTextOnly; // Add l10n key
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
        appBar: AppBar(
          title: Text(l10n.settingsFeedDisplayTitle),
        ), // Reuse title
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsFeedDisplayTitle), // Reuse title
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // --- Feed Tile Type ---
          _buildDropdownSetting<FeedListTileType>(
            context: context,
            title: l10n.settingsFeedTileTypeLabel, // Add l10n key
            currentValue: state.feedSettings.feedListTileType,
            items: FeedListTileType.values,
            itemToString: (type) => _tileTypeToString(type, l10n),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.add(SettingsFeedTileTypeChanged(value));
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
