import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template settings_page}
/// The main page for accessing different application settings categories.
///
/// Provides navigation to sub-pages for specific settings domains like
/// Appearance, Feed Display, Article Display, and Notifications.
/// {@endtemplate}
class SettingsPage extends StatefulWidget {
  /// {@macro settings_page}
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  String _accentThemeToString(AppAccentTheme theme, AppLocalizations l10n) {
    switch (theme) {
      case AppAccentTheme.defaultBlue:
        return l10n.settingsAppearanceThemeNameBlue;
      case AppAccentTheme.newsRed:
        return l10n.settingsAppearanceThemeNameRed;
      case AppAccentTheme.graphiteGray:
        return l10n.settingsAppearanceThemeNameGrey;
    }
  }

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
    return behavior == FeedItemClickBehavior.internalNavigation
        ? l10n.settingsFeedClickBehaviorInApp
        : l10n.settingsFeedClickBehaviorSystem;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final appState = context.watch<AppBloc>().state;
    final settings = appState.settings;

    if (settings == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxDialogContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _SectionTitle(title: l10n.settingsAppearanceSectionTitle),
                const SizedBox(height: AppSpacing.md),
                _ThemeModeSetting(settings: settings),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  title: Text(l10n.settingsAccentColorAndFontsTitle),
                  subtitle: Text(
                    '${_accentThemeToString(settings.displaySettings.accentTheme, l10n)}, '
                    '${_fontWeightToString(settings.displaySettings.fontWeight, l10n)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.pushNamed(Routes.settingsAccentColorAndFontsName),
                ),
                const Divider(),
                _SectionTitle(title: l10n.settingsFeedSectionTitle),
                ListTile(
                  title: Text(l10n.settingsLayoutAndReadingTitle),
                  subtitle: Text(
                    '${_imageStyleToString(settings.feedSettings.feedItemImageStyle, l10n)}, '
                    '${_clickBehaviorToString(settings.feedSettings.feedItemClickBehavior, l10n)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(Routes.settingsFeedName),
                ),
                const Divider(),
                _SectionTitle(title: l10n.settingsGeneralSectionTitle),
                _LanguageSetting(settings: settings),
                AboutListTile(
                  icon: const Icon(Icons.info_outline),
                  applicationName: l10n.appName,
                  applicationVersion: _appVersion,
                  applicationLegalese: '© ${DateTime.now().year}',
                  aboutBoxChildren: const [_SocialMediaLinks()],
                ),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}

class _ThemeModeSetting extends StatelessWidget {
  const _ThemeModeSetting({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            l10n.settingsAppearanceThemeModeLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<AppBaseTheme>(
          segments: [
            ButtonSegment(
              value: AppBaseTheme.light,
              label: Text(l10n.settingsAppearanceThemeModeLight),
              icon: const Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: AppBaseTheme.dark,
              label: Text(l10n.settingsAppearanceThemeModeDark),
              icon: const Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment(
              value: AppBaseTheme.system,
              label: Text(l10n.settingsAppearanceThemeModeSystem),
              icon: const Icon(Icons.brightness_auto_outlined),
            ),
          ],
          selected: {settings.displaySettings.baseTheme},
          onSelectionChanged: (newSelection) {
            context.read<AppBloc>().add(
              AppSettingsChanged(
                settings.copyWith(
                  displaySettings: settings.displaySettings.copyWith(
                    baseTheme: newSelection.first,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final supportedLanguages = languagesFixturesData
        .where((l) => l.code == 'en' || l.code == 'ar')
        .toList();

    return ListTile(
      title: Text(l10n.settingsLanguageTitle),
      subtitle: Text(settings.language.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.settingsLanguageTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supportedLanguages.length,
              itemBuilder: (context, index) {
                final language = supportedLanguages[index];
                return RadioListTile<Language>(
                  title: Text(language.name),
                  value: language,
                  groupValue: settings.language,
                  onChanged: (selectedLanguage) {
                    if (selectedLanguage != null) {
                      context.read<AppBloc>().add(
                        AppSettingsChanged(
                          settings.copyWith(language: selectedLanguage),
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialMediaLinks extends StatelessWidget {
  const _SocialMediaLinks();

  @override
  Widget build(BuildContext context) {
    // TODO(fulleni): Move social media URLs to remote config and re-enable this UI.
    return const SizedBox.shrink();
  }

  // Future<void> _launchUrl(String url) async {
  //   if (!await launchUrl(Uri.parse(url))) {
  //     // Could show a snackbar here if needed
  //   }
  // }
}
