import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Required for HtDataRepository
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/headlines-feed/bloc/categories_filter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/widgets/widgets.dart';
import 'package:ht_shared/ht_shared.dart';

/// {@template add_category_to_follow_page}
/// A page that allows users to browse and select categories to follow.
/// {@endtemplate}
class AddCategoryToFollowPage extends StatelessWidget {
  /// {@macro add_category_to_follow_page}
  const AddCategoryToFollowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // It's better to provide CategoriesFilterBloc here if it's specific to this page
    // or ensure it's provided higher up if shared more broadly for "add" flows.
    // For now, creating a new instance.
    return BlocProvider(
      create: (context) => CategoriesFilterBloc(
        categoriesRepository: context.read<HtDataRepository<Category>>(),
      )..add(CategoriesFilterRequested()), // Removed const
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addCategoriesPageTitle),
        ),
        body: BlocBuilder<CategoriesFilterBloc, CategoriesFilterState>(
          builder: (context, categoriesState) {
            if (categoriesState.status == CategoriesFilterStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (categoriesState.status == CategoriesFilterStatus.failure) {
              var errorMessage = l10n.categoryFilterError;
              if (categoriesState.error is HtHttpException) {
                errorMessage = (categoriesState.error! as HtHttpException).message;
              } else if (categoriesState.error != null) {
                errorMessage = categoriesState.error.toString();
              }
              return FailureStateWidget(
                message: errorMessage,
                onRetry: () => context
                    .read<CategoriesFilterBloc>()
                    .add(CategoriesFilterRequested()), // Removed const
              );
            }
            if (categoriesState.categories.isEmpty) {
              return FailureStateWidget(
                message: l10n.categoryFilterEmptyHeadline,
              ); // Re-use existing key
            }

            // Use AccountBloc to check which categories are already followed
            return BlocBuilder<AccountBloc, AccountState>(
              buildWhen: (previous, current) =>
                  previous.preferences?.followedCategories != current.preferences?.followedCategories ||
                  previous.status != current.status, // Rebuild if status changes too
              builder: (context, accountState) {
                final followedCategories =
                    accountState.preferences?.followedCategories ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: categoriesState.categories.length,
                  itemBuilder: (context, index) {
                    final category = categoriesState.categories[index];
                    final isFollowed = followedCategories
                        .any((fc) => fc.id == category.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: category.iconUrl != null &&
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
                        trailing: IconButton(
                          icon: isFollowed
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : const Icon(Icons.add_circle_outline),
                          tooltip: isFollowed
                              ? l10n.unfollowCategoryTooltip(category.name)
                              : l10n.followCategoryTooltip(category.name), // New
                          onPressed: () {
                            context.read<AccountBloc>().add(
                                  AccountFollowCategoryToggled(
                                    category: category,
                                  ),
                                );
                          },
                        ),
                        // Optional: onTap could also toggle
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
