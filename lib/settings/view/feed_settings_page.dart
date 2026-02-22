import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template feed_settings_page}
/// A page for configuring feed display settings.
/// {@endtemplate}
class FeedSettingsPage extends StatelessWidget {
  /// {@macro feed_settings_page}
  const FeedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final settings = context.select((AppBloc bloc) => bloc.state.settings);

    if (settings == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsLayoutAndReadingTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLayoutAndReadingTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxDialogContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SectionTitle(title: l10n.settingsFeedTileTypeLabel),
              const SizedBox(height: AppSpacing.md),
              _LayoutStyleSelector(settings: settings),
              const SizedBox(height: AppSpacing.xxl),
              _SectionTitle(title: l10n.settingsFeedClickBehaviorLabel),
              const SizedBox(height: AppSpacing.md),
              _OpenLinksInSelector(settings: settings),
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

class _LayoutStyleSelector extends StatelessWidget {
  const _LayoutStyleSelector({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return SegmentedButton<FeedItemImageStyle>(
      segments: [
        ButtonSegment(
          value: FeedItemImageStyle.largeThumbnail,
          label: Text(l10n.settingsFeedTileTypeImageTop),
          icon: const Icon(Icons.image_outlined),
        ),
        ButtonSegment(
          value: FeedItemImageStyle.smallThumbnail,
          label: Text(l10n.settingsFeedTileTypeImageStart),
          icon: const Icon(Icons.image_aspect_ratio_outlined),
        ),
        ButtonSegment(
          value: FeedItemImageStyle.hidden,
          label: Text(l10n.settingsFeedTileTypeTextOnly),
          icon: const Icon(Icons.short_text),
        ),
      ],
      selected: {settings.feedSettings.feedItemImageStyle},
      onSelectionChanged: (newSelection) {
        context.read<AppBloc>().add(
          AppSettingsChanged(
            settings.copyWith(
              feedSettings: settings.feedSettings.copyWith(
                feedItemImageStyle: newSelection.first,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OpenLinksInSelector extends StatelessWidget {
  const _OpenLinksInSelector({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<FeedItemClickBehavior>(
          title: Text(l10n.settingsFeedClickBehaviorDefault),
          value: FeedItemClickBehavior.defaultBehavior,
          groupValue: settings.feedSettings.feedItemClickBehavior,
          onChanged: (value) => _onChanged(context, value),
        ),
        RadioListTile<FeedItemClickBehavior>(
          title: Text(l10n.settingsFeedClickBehaviorInApp),
          value: FeedItemClickBehavior.internalNavigation,
          groupValue: settings.feedSettings.feedItemClickBehavior,
          onChanged: (value) => _onChanged(context, value),
        ),
        RadioListTile<FeedItemClickBehavior>(
          title: Text(l10n.settingsFeedClickBehaviorSystem),
          value: FeedItemClickBehavior.externalNavigation,
          groupValue: settings.feedSettings.feedItemClickBehavior,
          onChanged: (value) => _onChanged(context, value),
        ),
      ],
    );
  }

  void _onChanged(BuildContext context, FeedItemClickBehavior? value) {
    if (value != null) {
      context.read<AppBloc>().add(
        AppSettingsChanged(
          settings.copyWith(
            feedSettings: settings.feedSettings.copyWith(
              feedItemClickBehavior: value,
            ),
          ),
        ),
      );
    }
  }
}
