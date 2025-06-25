import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return BlocProvider(
      create: (context) => CategoriesFilterBloc(
        categoriesRepository: context.read<HtDataRepository<Category>>(),
      )..add(CategoriesFilterRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addCategoriesPageTitle, style: textTheme.titleLarge),
        ),
        body: BlocBuilder<CategoriesFilterBloc, CategoriesFilterState>(
          builder: (context, categoriesState) {
            if (categoriesState.status == CategoriesFilterStatus.loading &&
                categoriesState.categories.isEmpty) {
              // Show full loading only if list is empty
              return LoadingStateWidget(
                icon: Icons.category_outlined,
                headline: l10n.categoryFilterLoadingHeadline,
                subheadline: l10n.categoryFilterLoadingSubheadline,
              );
            }
            if (categoriesState.status == CategoriesFilterStatus.failure &&
                categoriesState.categories.isEmpty) {
              // Show full error only if list is empty
              var errorMessage = l10n.categoryFilterError;
              if (categoriesState.error is HtHttpException) {
                errorMessage =
                    (categoriesState.error! as HtHttpException).message;
              } else if (categoriesState.error != null) {
                errorMessage = categoriesState.error.toString();
              }
              return FailureStateWidget(
                message: errorMessage,
                onRetry: () => context.read<CategoriesFilterBloc>().add(
                  CategoriesFilterRequested(),
                ),
              );
            }
            if (categoriesState.categories.isEmpty &&
                categoriesState.status == CategoriesFilterStatus.success) {
              // Show empty only on success
              return InitialStateWidget(
                // Use InitialStateWidget for empty
                icon: Icons.search_off_outlined,
                headline: l10n.categoryFilterEmptyHeadline,
                subheadline: l10n.categoryFilterEmptySubheadline,
              );
            }

            // Handle loading more at the bottom or list display
            final categories = categoriesState.categories;
            final isLoadingMore =
                categoriesState.status == CategoriesFilterStatus.loadingMore;

            return BlocBuilder<AccountBloc, AccountState>(
              buildWhen: (previous, current) =>
                  previous.preferences?.followedCategories !=
                      current.preferences?.followedCategories ||
                  previous.status != current.status,
              builder: (context, accountState) {
                final followedCategories =
                    accountState.preferences?.followedCategories ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    // Consistent padding
                    horizontal: AppSpacing.paddingMedium,
                    vertical: AppSpacing.paddingSmall,
                  ).copyWith(bottom: AppSpacing.xxl),
                  itemCount: categories.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == categories.length && isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (index >= categories.length) {
                      return const SizedBox.shrink();
                    }

                    final category = categories[index];
                    final isFollowed = followedCategories.any(
                      (fc) => fc.id == category.id,
                    );
                    final colorScheme = Theme.of(context).colorScheme;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          // Standardized leading icon/image size
                          width: AppSpacing.xl + AppSpacing.xs,
                          height: AppSpacing.xl + AppSpacing.xs,
                          child:
                              category.iconUrl != null &&
                                  Uri.tryParse(category.iconUrl!)?.isAbsolute ==
                                      true
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.xs,
                                  ),
                                  child: Image.network(
                                    category.iconUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.category_outlined,
                                          color: colorScheme.onSurfaceVariant,
                                          size: AppSpacing.lg,
                                        ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                  ),
                                )
                              : Icon(
                                  Icons.category_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: AppSpacing.lg,
                                ),
                        ),
                        title: Text(
                          category.name,
                          style: textTheme.titleMedium,
                        ),
                        trailing: IconButton(
                          icon: isFollowed
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : Icon(
                                  Icons.add_circle_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          tooltip: isFollowed
                              ? l10n.unfollowCategoryTooltip(category.name)
                              : l10n.followCategoryTooltip(category.name),
                          onPressed: () {
                            context.read<AccountBloc>().add(
                              AccountFollowCategoryToggled(category: category),
                            );
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          // Consistent padding
                          horizontal: AppSpacing.paddingMedium,
                          vertical: AppSpacing.xs,
                        ),
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
