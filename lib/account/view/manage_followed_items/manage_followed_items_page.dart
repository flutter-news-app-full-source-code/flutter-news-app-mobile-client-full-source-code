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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.accountContentPreferencesTile,
        ), // "Content Preferences"
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l10n.headlinesFeedFilterCategoryLabel), // "Categories"
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.followedCategoriesListName);
            },
          ),
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.source_outlined),
            title: Text(l10n.headlinesFeedFilterSourceLabel), // "Sources"
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(Routes.followedSourcesListName);
            },
          ),
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          // ListTile for Followed Countries removed
        ],
      ),
    );
  }
}
