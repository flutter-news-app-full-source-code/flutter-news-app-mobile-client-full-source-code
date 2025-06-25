import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template manage_followed_items_page}
/// Page for navigating to lists of followed content types like
/// categories, sources, and countries.
/// {@endtemplate}
class ManageFollowedItemsPage extends StatelessWidget {
  /// {@macro manage_followed_items_page}
  const ManageFollowedItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            leading: Icon(Icons.category_outlined, color: colorScheme.primary),
            title: Text(
              l10n.headlinesFeedFilterCategoryLabel,
              style: textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.followedCategoriesListName);
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
          // ListTile for Followed Countries removed
        ],
      ),
    );
  }
}
