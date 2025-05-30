//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/headlines-search/models/search_model_type.dart'; // Import SearchModelType
import 'package:ht_main/router/routes.dart'; // Import Routes
import 'package:ht_shared/ht_shared.dart'; // Import shared models
// Import new item widgets
import 'package:ht_main/headlines-search/widgets/category_item_widget.dart';
import 'package:ht_main/headlines-search/widgets/country_item_widget.dart';
import 'package:ht_main/headlines-search/widgets/source_item_widget.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart'; // Import AppSpacing
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/initial_state_widget.dart';

/// Page widget responsible for providing the BLoC for the headlines search feature.
class HeadlinesSearchPage extends StatelessWidget {
  const HeadlinesSearchPage({super.key});

  /// Defines the route for this page.
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HeadlinesSearchPage());
  }

  @override
  Widget build(BuildContext context) {
    return const _HeadlinesSearchView();
  }
}

/// Private View widget that builds the UI for the headlines search page.
/// It listens to the HeadlinesSearchBloc state and displays the appropriate UI.
class _HeadlinesSearchView extends StatefulWidget {
  const _HeadlinesSearchView(); // Private constructor

  @override
  State<_HeadlinesSearchView> createState() => _HeadlinesSearchViewState();
}

class _HeadlinesSearchViewState extends State<_HeadlinesSearchView> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _showClearButton = false;
  SearchModelType _selectedModelType = SearchModelType.headline; // Initial selection

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(() {
      setState(() {
        _showClearButton = _textController.text.isNotEmpty;
      });
    });
    // Set initial model type in BLoC if not already set (e.g. on first load)
    // Though BLoC state now defaults, this ensures UI and BLoC are in sync.
    context
        .read<HeadlinesSearchBloc>()
        .add(HeadlinesSearchModelTypeChanged(_selectedModelType));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<HeadlinesSearchBloc>().state;
    if (_isBottom && state is HeadlinesSearchSuccess && state.hasMore) {
      context.read<HeadlinesSearchBloc>().add(
            HeadlinesSearchFetchRequested(searchTerm: state.lastSearchTerm),
          );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.98);
  }

  void _performSearch() {
    context.read<HeadlinesSearchBloc>().add(
          HeadlinesSearchFetchRequested(searchTerm: _textController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarTheme = theme.appBarTheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 150, // Adjust width to accommodate dropdown
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
          child: DropdownButtonFormField<SearchModelType>(
            value: _selectedModelType,
            // Use a more subtle underline or remove it if it clashes
            decoration: const InputDecoration(
              border: InputBorder.none, // Removes underline
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, // Minimal horizontal padding
              ),
            ),
            // Style the dropdown text to match AppBar title
            style: appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
            dropdownColor: colorScheme.surfaceContainerHighest, // Match theme
            icon: Icon(
              Icons.arrow_drop_down,
              color: appBarTheme.iconTheme?.color ?? colorScheme.onSurface,
            ),
            items: SearchModelType.values.map((SearchModelType type) {
              return DropdownMenuItem<SearchModelType>(
                value: type,
                child: Text(
                  type.displayName, // Using the new getter
                  // Ensure text color contrasts with dropdownColor
                  style: appBarTheme.titleTextStyle?.copyWith(
                        color: colorScheme.onSurface, // Example color
                      ) ??
                      theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
              );
            }).toList(),
            onChanged: (SearchModelType? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedModelType = newValue;
                });
                context
                    .read<HeadlinesSearchBloc>()
                    .add(HeadlinesSearchModelTypeChanged(newValue));
                if (_textController.text.isNotEmpty) {
                  _performSearch(); // Re-trigger search with new model type
                }
              }
            },
          ),
        ),
        title: TextField(
          controller: _textController,
          style: appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: l10n.headlinesSearchHintText,
            hintStyle: (appBarTheme.titleTextStyle ??
                    theme.textTheme.titleLarge)
                ?.copyWith(color: colorScheme.onSurface.withAlpha(153)),
            border: InputBorder.none,
            filled: true,
            fillColor: colorScheme.surface.withAlpha(26),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingMedium,
              vertical: AppSpacing.paddingSmall,
            ),
            suffixIcon: _showClearButton
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: appBarTheme.iconTheme?.color ??
                          colorScheme.onSurface,
                    ),
                    onPressed: () {
                      _textController.clear();
                      // Optionally clear search results when text is cleared
                      // context.read<HeadlinesSearchBloc>().add(HeadlinesSearchModelTypeChanged(_selectedModelType));
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.headlinesSearchActionTooltip,
            onPressed: _performSearch,
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesSearchBloc, HeadlinesSearchState>(
        builder: (context, state) {
          return switch (state) {
            HeadlinesSearchInitial() => InitialStateWidget(
                icon: Icons.search_off_rounded,
                headline: l10n.headlinesSearchInitialHeadline,
                subheadline: l10n.headlinesSearchInitialSubheadline,
              ),
            // Use more generic loading text or existing keys
            HeadlinesSearchLoading() => InitialStateWidget(
                icon: Icons.manage_search,
                headline: l10n.headlinesFeedLoadingHeadline, // Re-use feed loading
                subheadline:
                    'Searching ${state.selectedModelType.displayName.toLowerCase()}...',
              ),
            HeadlinesSearchSuccess(
              results: final results,
              hasMore: final hasMore,
              errorMessage: final errorMessage,
              lastSearchTerm: final lastSearchTerm,
              selectedModelType: final resultsModelType,
            ) =>
              errorMessage != null
                  ? FailureStateWidget(
                      message: errorMessage,
                      onRetry: () => context.read<HeadlinesSearchBloc>().add(
                            HeadlinesSearchFetchRequested(
                                searchTerm: lastSearchTerm),
                          ),
                    )
                  : results.isEmpty
                      ? FailureStateWidget(
                          message:
                              '${l10n.headlinesSearchNoResultsHeadline} for "${lastSearchTerm}" in ${resultsModelType.displayName.toLowerCase()}.\n${l10n.headlinesSearchNoResultsSubheadline}',
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              hasMore ? results.length + 1 : results.length,
                          itemBuilder: (context, index) {
                            if (index >= results.length) {
                              return const Padding(
                                padding:
                                    EdgeInsets.all(AppSpacing.paddingLarge),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            final item = results[index];
                            switch (resultsModelType) {
                              case SearchModelType.headline:
                                return HeadlineItemWidget(
                                  headline: item as Headline,
                                  targetRouteName:
                                      Routes.searchArticleDetailsName,
                                );
                              case SearchModelType.category:
                                return CategoryItemWidget(
                                    category: item as Category);
                              case SearchModelType.source:
                                return SourceItemWidget(source: item as Source);
                              case SearchModelType.country:
                                return CountryItemWidget(
                                    country: item as Country);
                            }
                          },
                        ),
            HeadlinesSearchFailure(
              errorMessage: final errorMessage,
              lastSearchTerm: final lastSearchTerm,
              selectedModelType: final failedModelType
            ) =>
              FailureStateWidget(
                message:
                    'Failed to search $lastSearchTerm in ${failedModelType.displayName.toLowerCase()}:\n$errorMessage',
                onRetry: () => context.read<HeadlinesSearchBloc>().add(
                      HeadlinesSearchFetchRequested(searchTerm: lastSearchTerm),
                    ),
              ),
            // Add default case for exhaustiveness
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
