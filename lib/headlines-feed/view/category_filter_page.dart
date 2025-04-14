// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_categories_client/ht_categories_client.dart';
// Removed repository import: import 'package:ht_categories_repository/ht_categories_repository.dart';
import 'package:ht_main/headlines-feed/bloc/categories_filter_bloc.dart'; // Import the BLoC
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart'; // For loading/error widgets

/// {@template category_filter_page}
/// A page dedicated to selecting news categories for filtering headlines.
///
/// Uses [CategoriesFilterBloc] to fetch categories paginatively, allows
/// multiple selections, and returns the selected list via `context.pop`
/// when the user applies the changes.
/// {@endtemplate}
class CategoryFilterPage extends StatefulWidget {
  /// {@macro category_filter_page}
  const CategoryFilterPage({super.key});

  @override
  State<CategoryFilterPage> createState() => _CategoryFilterPageState();
}

/// State for the [CategoryFilterPage].
///
/// Manages the local selection state ([_pageSelectedCategories]) and interacts
/// with [CategoriesFilterBloc] for data fetching and pagination.
class _CategoryFilterPageState extends State<CategoryFilterPage> {
  /// Stores the categories selected by the user *on this specific page*.
  /// This state is local to the `CategoryFilterPage` lifecycle.
  /// It's initialized in `initState` using the list of previously selected
  /// categories passed via the `extra` parameter during navigation from
  /// `HeadlinesFilterPage`. This ensures the checkboxes reflect the state
  /// from the main filter page when this page loads.
  late Set<Category> _pageSelectedCategories;

  /// Scroll controller to detect when the user reaches the end of the list
  /// for pagination.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialization needs to happen after the first frame to safely access
    // GoRouterState.of(context).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Retrieve the list of categories that were already selected on the
      //    previous page (HeadlinesFilterPage). This list is passed dynamically
      //    via the `extra` parameter in the `context.pushNamed` call.
      final initialSelection =
          GoRouterState.of(context).extra as List<Category>?;

      // 2. Initialize the local selection state (`_pageSelectedCategories`) for this
      //    page. Use a Set for efficient add/remove/contains operations.
      //    This ensures the checkboxes on this page are initially checked
      //    correctly based on the selections made previously.
      _pageSelectedCategories = Set.from(initialSelection ?? []);

      // 3. Trigger the page-specific BLoC (CategoriesFilterBloc) to start
      //    fetching the list of *all available* categories that the user can
      //    potentially select from. The BLoC handles fetching, pagination,
      //    loading states, and errors for the *list of options*.
      context.read<CategoriesFilterBloc>().add(CategoriesFilterRequested());
    });
    // Add listener for pagination logic.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Callback function for scroll events.
  ///
  /// Checks if the user has scrolled near the bottom of the list and triggers
  /// fetching more categories via the BLoC if available.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final bloc = context.read<CategoriesFilterBloc>();
    // Fetch more when nearing the bottom, if BLoC has more and isn't already loading more
    if (currentScroll >= (maxScroll * 0.9) &&
        bloc.state.hasMore &&
        bloc.state.status != CategoriesFilterStatus.loadingMore) {
      bloc.add(CategoriesFilterLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        // Default back button will pop without result (cancelling)
        title: Text(l10n.headlinesFeedFilterCategoryLabel),
        actions: [
          // Apply Button
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              // When the user taps 'Apply' (checkmark), pop the current route
              // and return the final list of selected categories (`_pageSelectedCategories`)
              // from this page back to the previous page (`HeadlinesFilterPage`).
              // `HeadlinesFilterPage` receives this list in its `onResult` callback.
              context.pop(_pageSelectedCategories.toList());
            },
          ),
        ],
      ),
      // Use BlocBuilder to react to state changes from CategoriesFilterBloc
      body: BlocBuilder<CategoriesFilterBloc, CategoriesFilterState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
    );
  }

  /// Builds the main content body based on the current [CategoriesFilterState].
  Widget _buildBody(BuildContext context, CategoriesFilterState state) {
    final l10n = context.l10n;

    // Handle initial loading state
    if (state.status == CategoriesFilterStatus.loading) {
      return LoadingStateWidget(
        icon: Icons.category_outlined,
        headline: l10n.categoryFilterLoadingHeadline,
        subheadline: l10n.categoryFilterLoadingSubheadline,
      );
    }

    // Handle failure state (show error and retry button)
    // Only show full error screen if not loading more (i.e., initial load failed)
    if (state.status == CategoriesFilterStatus.failure &&
        state.categories.isEmpty) {
      return FailureStateWidget(
        message: state.error?.toString() ?? l10n.unknownError,
        onRetry: () => context
            .read<CategoriesFilterBloc>()
            .add(CategoriesFilterRequested()),
      );
    }

    // Handle empty state (after successful load but no categories found)
    if (state.status == CategoriesFilterStatus.success &&
        state.categories.isEmpty) {
      return InitialStateWidget(
        icon: Icons.search_off,
        headline: l10n.categoryFilterEmptyHeadline,
        subheadline: l10n.categoryFilterEmptySubheadline,
      );
    }

    // Handle loaded state (success or loading more)
    // Show the list, potentially with a loading indicator at the bottom
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        bottom: AppSpacing.xxl, // Padding at the bottom for loader/content
      ),
      // Add 1 to item count if loading more or if failed during load more
      itemCount: state.categories.length +
          ((state.status == CategoriesFilterStatus.loadingMore ||
                  (state.status == CategoriesFilterStatus.failure &&
                      state.categories.isNotEmpty))
              ? 1
              : 0),
      itemBuilder: (context, index) {
        // Check if we need to render the loading/error indicator at the end
        if (index >= state.categories.length) {
          if (state.status == CategoriesFilterStatus.loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == CategoriesFilterStatus.failure) {
            // Show a smaller error indicator at the bottom if load more failed
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              child: Center(
                child: Text(
                  l10n.loadMoreError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink(); // Should not happen if hasMore is false
          }
        }

        // Render the actual category item
        final category = state.categories[index];
        final isSelected = _pageSelectedCategories.contains(category);

        return CheckboxListTile(
          title: Text(category.name),
          secondary: category.iconUrl != null
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.network(
                    category.iconUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.category), // Placeholder icon
                  ),
                )
              : null,
          value: isSelected,
          onChanged: (bool? value) {
            // When a checkbox state changes, update the local selection set
            // (`_pageSelectedCategories`) for this page.
            setState(() {
              if (value == true) {
                // Add the category if checked.
                _pageSelectedCategories.add(category);
              } else {
                // Remove the category if unchecked.
                _pageSelectedCategories.remove(category);
              }
            });
          },
        );
      },
    );
  }
}
