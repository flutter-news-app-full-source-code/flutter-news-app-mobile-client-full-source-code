//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_categories_client/ht_categories_client.dart';
import 'package:ht_categories_repository/ht_categories_repository.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart'; // For loading/error widgets

/// {@template category_filter_page}
/// A page dedicated to selecting news categories for filtering headlines.
///
/// Fetches categories paginatively, allows multiple selections, and returns
/// the selected list via `context.pop` when the user applies the changes.
/// {@endtemplate}
class CategoryFilterPage extends StatefulWidget {
  /// {@macro category_filter_page}
  const CategoryFilterPage({super.key});

  @override
  State<CategoryFilterPage> createState() => _CategoryFilterPageState();
}

/// State for the [CategoryFilterPage].
///
/// Manages the local selection state ([_pageSelectedCategories]), fetches
/// categories from the [HtCategoriesRepository], handles pagination using a
/// [ScrollController], and displays loading/error/empty/loaded states.
class _CategoryFilterPageState extends State<CategoryFilterPage> {
  /// Stores the categories selected by the user on this page.
  /// Initialized from the `extra` parameter passed during navigation.
  late Set<Category> _pageSelectedCategories;

  /// List of all categories fetched from the repository.
  List<Category> _allCategories = [];

  /// Flag indicating if the initial category list is being loaded.
  bool _isLoading = true;

  /// Flag indicating if more categories are being loaded for pagination.
  bool _isLoadingMore = false;

  /// Flag indicating if more categories are available to fetch.
  bool _hasMore = true;

  /// Cursor for fetching the next page of categories.
  String? _cursor;

  /// Stores any error message that occurred during fetching.
  String? _error;

  /// Scroll controller to detect when the user reaches the end of the list
  /// for pagination.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize local selections from the data passed via 'extra'
    // Need to access GoRouterState *after* the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialSelection =
          GoRouterState.of(context).extra as List<Category>?;
      _pageSelectedCategories = Set.from(initialSelection ?? []);
      _fetchCategories(); // Initial fetch
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Fetches categories from the [HtCategoriesRepository].
  ///
  /// Handles both initial fetch and pagination (`loadMore = true`). Updates
  /// loading states, fetched data ([_allCategories]), pagination info
  /// ([_cursor], [_hasMore]), and error state ([_error]).
  Future<void> _fetchCategories({bool loadMore = false}) async {
    // Prevent unnecessary fetches
    if (!loadMore && _isLoading) return;
    if (loadMore && (_isLoadingMore || !_hasMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null; // Clear previous error on initial load/refresh
      }
    });

    try {
      final repo = context.read<HtCategoriesRepository>();
      final response = await repo.getCategories(
        limit: 20, // Adjust limit as needed
        startAfterId: loadMore ? _cursor : null,
      );

      setState(() {
        if (loadMore) {
          _allCategories.addAll(response.items);
        } else {
          _allCategories = response.items;
        }
        _cursor = response.cursor;
        _hasMore = response.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = e.toString(); // Store error message
      });
    }
  }

  /// Callback function for scroll events.
  ///
  /// Checks if the user has scrolled near the bottom of the list and triggers
  /// fetching more categories if available.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Fetch more when nearing the bottom
    if (currentScroll >= (maxScroll * 0.9) && _hasMore && !_isLoadingMore) {
      _fetchCategories(loadMore: true);
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
              // Pop with the final selection from this page
              context.pop(_pageSelectedCategories.toList());
            },
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  /// Builds the main content body based on the current loading/error/data state.
  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      // Show initial loading indicator
      return LoadingStateWidget(
        icon: Icons.category_outlined,
        headline: l10n.categoryFilterLoadingHeadline,
        subheadline: l10n.categoryFilterLoadingSubheadline,
      );
    }

    if (_error != null) {
      return FailureStateWidget(message: _error!, onRetry: _fetchCategories);
    }

    if (_allCategories.isEmpty) {
      return InitialStateWidget(
        // Or a dedicated "No Items" widget
        icon: Icons.search_off,
        headline: l10n.categoryFilterEmptyHeadline,
        subheadline: l10n.categoryFilterEmptySubheadline,
      );
    }

    // Use ListView.builder for performance with potentially long lists
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        bottom: AppSpacing.xxl,
      ), // Padding at the bottom
      itemCount:
          _allCategories.length + (_hasMore ? 1 : 0), // Add space for loader
      itemBuilder: (context, index) {
        if (index >= _allCategories.length) {
          // Loading indicator for pagination
          return _isLoadingMore
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
              : const SizedBox.shrink(); // Hide if not loading more
        }

        final category = _allCategories[index];
        final isSelected = _pageSelectedCategories.contains(category);

        return CheckboxListTile(
          title: Text(category.name),
          // Optionally show icon if available
          secondary:
              category.iconUrl != null
                  ? SizedBox(
                    width: 40, // Consistent size for icons
                    height: 40,
                    child: Image.network(
                      category.iconUrl!,
                      fit: BoxFit.contain,
                      // Add error builder for network images
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.category), // Placeholder icon
                    ),
                  )
                  : null,
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _pageSelectedCategories.add(category);
              } else {
                _pageSelectedCategories.remove(category);
              }
            });
          },
        );
      },
    );
  }
}
