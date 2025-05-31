import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart'; // Added
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/widgets/widgets.dart';

/// {@template followed_categories_list_page}
/// Displays a list of categories the user is currently following.
/// Allows unfollowing and navigating to add more categories.
/// {@endtemplate}
class FollowedCategoriesListPage extends StatelessWidget {
  /// {@macro followed_categories_list_page}
  const FollowedCategoriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followedCategoriesPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addCategoriesTooltip,
            onPressed: () {
              context.goNamed(Routes.addCategoryToFollowName);
            },
          ),
        ],
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.status == AccountStatus.initial ||
              (state.status == AccountStatus.loading &&
                  state.preferences == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              message: state.errorMessage ?? l10n.unknownError,
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                    AccountLoadContentPreferencesRequested(
                      userId: state.user!.id,
                    ),
                  );
                }
              },
            );
          }

          final followedCategories = state.preferences?.followedCategories;

          if (followedCategories == null || followedCategories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.category_outlined, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.noFollowedCategoriesMessage,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.addCategoriesButtonLabel),
                      onPressed: () {
                        context.goNamed(Routes.addCategoryToFollowName);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: followedCategories.length,
            itemBuilder: (context, index) {
              final category = followedCategories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading:
                      category.iconUrl != null &&
                              Uri.tryParse(category.iconUrl!)?.isAbsolute ==
                                  true
                          ? SizedBox(
                            width: 36,
                            height: 36,
                            child: Image.network(
                              category.iconUrl!,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.category_outlined),
                            ),
                          )
                          : const Icon(Icons.category_outlined),
                  title: Text(category.name),
                  onTap: () {
                    // Added onTap for navigation
                    context.push(
                      Routes.categoryDetails,
                      extra: EntityDetailsPageArguments(entity: category),
                    );
                  },
                  trailing: IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: l10n.unfollowCategoryTooltip(category.name),
                    onPressed: () {
                      context.read<AccountBloc>().add(
                        AccountFollowCategoryToggled(category: category),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
