import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template manage_followed_items_page}
/// Page for navigating to lists of followed content types like
/// topics, sources, and countries.
/// {@endtemplate}
class ManageFollowedItemsPage extends StatelessWidget {
  /// {@macro manage_followed_items_page}
  const ManageFollowedItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.accountContentPreferencesTile,
          style: textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.paddingSmall),
        children: [
          ListTile(
            leading: Icon(Icons.topic_outlined, color: colorScheme.primary),
            title: Text(
              l10n.headlinesFeedFilterTopicLabel,
              style: textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.followedTopicsListName);
            },
          ),
          const Divider(
            indent: AppSpacing.paddingMedium,
            endIndent: AppSpacing.paddingMedium,
          ),
          ListTile(
            leading: Icon(Icons.source_outlined, color: colorScheme.primary),
            title: Text(
              l10n.headlinesFeedFilterSourceLabel,
              style: textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.followedSourcesListName);
            },
          ),
          const Divider(
            indent: AppSpacing.paddingMedium,
            endIndent: AppSpacing.paddingMedium,
          ),
        ],
      ),
    );
  }
}
