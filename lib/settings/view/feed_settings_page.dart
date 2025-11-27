import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/bloc/settings_bloc.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template feed_settings_page}
/// A page for configuring feed display settings.
/// {@endtemplate}
class FeedSettingsPage extends StatelessWidget {
  /// {@macro feed_settings_page}
  const FeedSettingsPage({super.key});

  // Helper to map HeadlineImageStyle enum to user-friendly strings
  String _imageStyleToString(FeedItemImageStyle style, AppLocalizations l10n) {
    switch (style) {
      case FeedItemImageStyle.hidden:
        return l10n.settingsFeedTileTypeTextOnly;
      case FeedItemImageStyle.smallThumbnail:
        return l10n.settingsFeedTileTypeImageStart;
      case FeedItemImageStyle.largeThumbnail:
        return l10n.settingsFeedTileTypeImageTop;
    }
  }

  String _clickBehaviorToString(
    FeedItemClickBehavior behavior,
    AppLocalizations l10n,
  ) {
    switch (behavior) {
      case FeedItemClickBehavior.defaultBehavior:
        return l10n.settingsFeedClickBehaviorDefault;
      case FeedItemClickBehavior.internalNavigation:
        return l10n.settingsFeedClickBehaviorInApp;
      case FeedItemClickBehavior.externalNavigation:
        return l10n.settingsFeedClickBehaviorSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final settingsBloc = context.watch<SettingsBloc>();
    final state = settingsBloc.state;

    // Ensure we have loaded state before building controls
    if (state.status != SettingsStatus.success || state.appSettings == null) {
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
            _buildDropdownSetting<FeedItemImageStyle>(
              context: context,
              title: l10n.settingsFeedTileTypeLabel,
              currentValue: state.appSettings!.feedSettings.feedItemImageStyle,
              items: FeedItemImageStyle.values,
              itemToString: (style) => _imageStyleToString(style, l10n),
              onChanged: (value) {
                if (value != null) {
                  settingsBloc.add(SettingsFeedItemImageStyleChanged(value));
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            // --- Feed Item Click Behavior ---
            _buildDropdownSetting<FeedItemClickBehavior>(
              context: context,
              title: l10n.settingsFeedClickBehaviorLabel,
              currentValue:
                  state.appSettings!.feedSettings.feedItemClickBehavior,
              items: FeedItemClickBehavior.values,
              itemToString: (behavior) =>
                  _clickBehaviorToString(behavior, l10n),
              onChanged: (value) {
                if (value != null) {
                  settingsBloc.add(SettingsFeedItemClickBehaviorChanged(value));
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
