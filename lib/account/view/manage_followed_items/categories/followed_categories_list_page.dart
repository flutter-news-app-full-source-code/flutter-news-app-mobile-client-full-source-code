import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart'; // Import for Arguments
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/widgets/widgets.dart';
import 'package:ht_shared/ht_shared.dart';

/// {@template followed_categories_list_page}
/// Page to display and manage categories followed by the user.
/// {@endtemplate}
class FollowedCategoriesListPage extends StatelessWidget {
  /// {@macro followed_categories_list_page}
  const FollowedCategoriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final followedCategories =
        context.watch<AccountBloc>().state.preferences?.followedCategories ??
            [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followed Categories'), // Placeholder
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Category to Follow', // Placeholder
            onPressed: () {
              context.goNamed(Routes.addCategoryToFollowName);
            },
          ),
        ],
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.status == AccountStatus.loading &&
              state.preferences == null) {
            return LoadingStateWidget(
              icon: Icons.category_outlined,
              headline: 'Loading Followed Categories...', // Placeholder
              subheadline: l10n.pleaseWait, // Assuming this exists
            );
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              message: state.errorMessage ?? 'Could not load followed categories.', // Placeholder
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                        AccountLoadUserPreferences(
                          userId: state.user!.id,
                        ),
                      );
                }
              },
            );
          }

          if (followedCategories.isEmpty) {
            return const InitialStateWidget(
              icon: Icons.no_sim_outlined, // Placeholder icon
              headline: 'No Followed Categories', // Placeholder
              subheadline: 'Start following categories to see them here.', // Placeholder
            );
          }

          return ListView.builder(
            itemCount: followedCategories.length,
            itemBuilder: (context, index) {
              final category = followedCategories[index];
              return ListTile(
                leading: category.iconUrl != null
                    ? SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.network(
                          category.iconUrl!,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.category_outlined),
                        ),
                      )
                    : const Icon(Icons.category_outlined),
                title: Text(category.name),
                subtitle: category.description != null
                    ? Text(
                        category.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  tooltip: 'Unfollow Category', // Placeholder
                  onPressed: () {
                    context.read<AccountBloc>().add(
                          AccountFollowCategoryToggled(category: category),
                        );
                  },
                ),
                onTap: () {
                  context.push(
                    Routes.categoryDetails,
                    extra: EntityDetailsPageArguments(entity: category),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
