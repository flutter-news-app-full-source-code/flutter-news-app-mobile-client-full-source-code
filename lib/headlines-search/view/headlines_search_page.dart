//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter for navigation
import 'package:ht_main/app/bloc/app_bloc.dart'; // Import AppBloc for settings
// HeadlineItemWidget import removed
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/headlines-search/models/search_model_type.dart';
// Import new item widgets
import 'package:ht_main/headlines-search/widgets/category_item_widget.dart';
// import 'package:ht_main/headlines-search/widgets/country_item_widget.dart'; // Removed
import 'package:ht_main/headlines-search/widgets/source_item_widget.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/shared.dart'; // Imports new headline tiles
// Adjusted imports to only include what's necessary after country removal
import 'package:ht_shared/ht_shared.dart' show Category, Headline, Source, HeadlineImageStyle, SearchModelType;

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
  SearchModelType _selectedModelType =
      SearchModelType.headline; // Initial selection

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(() {
      setState(() {
        _showClearButton = _textController.text.isNotEmpty;
      });
    });
    // Ensure _selectedModelType is valid (it should be, as .country is removed from enum)
    if (!SearchModelType.values.contains(_selectedModelType)) {
        _selectedModelType = SearchModelType.headline; 
    }
    context.read<HeadlinesSearchBloc>().add(
      HeadlinesSearchModelTypeChanged(_selectedModelType),
    );
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

    // Use all values from SearchModelType as .country is already removed from the enum itself
    final availableSearchModelTypes = SearchModelType.values.toList();
    
    // Ensure _selectedModelType is still valid if it somehow was .country
    // (though this shouldn't happen if initState logic is correct and enum is updated)
    if (!availableSearchModelTypes.contains(_selectedModelType)) {
      _selectedModelType = SearchModelType.headline; 
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
           context.read<HeadlinesSearchBloc>().add(
                    HeadlinesSearchModelTypeChanged(_selectedModelType),
                  );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.paddingSmall,
        title: Row(
          children: [
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<SearchModelType>(
                value: _selectedModelType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  color:
                      appBarTheme.titleTextStyle?.color ??
                      colorScheme.onSurface,
                ),
                dropdownColor: colorScheme.surfaceContainerHighest,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: appBarTheme.iconTheme?.color ?? colorScheme.onSurface,
                ),
                items: availableSearchModelTypes.map((SearchModelType type) {
                  String displayLocalizedName;
                  // The switch is now exhaustive as SearchModelType.country is removed from the enum
                  switch (type) {
                    case SearchModelType.headline:
                      displayLocalizedName = l10n.searchModelTypeHeadline;
                      break;
                    case SearchModelType.category:
                      displayLocalizedName = l10n.searchModelTypeCategory;
                      break;
                    case SearchModelType.source:
                      displayLocalizedName = l10n.searchModelTypeSource;
                      break;
                  }
                  return DropdownMenuItem<SearchModelType>(
                    value: type,
                    child: Text(
                      displayLocalizedName,
                      style: theme.textTheme.titleMedium?.copyWith(
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
                    context.read<HeadlinesSearchBloc>().add(
                      HeadlinesSearchModelTypeChanged(newValue),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _textController,
                style: appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
                decoration: InputDecoration(
                  hintText: _getHintTextForModelType(_selectedModelType, l10n),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: (appBarTheme.titleTextStyle?.color ??
                            colorScheme.onSurface)
                        .withAlpha(153),
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: colorScheme.surface.withAlpha(26),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingMedium,
                    vertical: AppSpacing.paddingSmall + 3,
                  ),
                  suffixIcon:
                      _showClearButton
                          ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color:
                                  appBarTheme.iconTheme?.color ??
                                  colorScheme.onSurface,
                            ),
                            onPressed: _textController.clear,
                          )
                          : null,
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ],
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
              icon: Icons.search,
              headline: l10n.searchPageInitialHeadline,
              subheadline: l10n.searchPageInitialSubheadline,
            ),
            HeadlinesSearchLoading() => InitialStateWidget(
              icon: Icons.manage_search,
              headline: l10n.headlinesFeedLoadingHeadline,
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
                    onRetry:
                        () => context.read<HeadlinesSearchBloc>().add(
                          HeadlinesSearchFetchRequested(
                            searchTerm: lastSearchTerm,
                          ),
                        ),
                  )
                  : results.isEmpty
                  ? FailureStateWidget(
                    message:
                        '${l10n.headlinesSearchNoResultsHeadline} for "$lastSearchTerm" in ${resultsModelType.displayName.toLowerCase()}.\n${l10n.headlinesSearchNoResultsSubheadline}',
                  )
                  : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.paddingMedium),
                    itemCount: hasMore ? results.length + 1 : results.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index >= results.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = results[index];
                      // The switch is now exhaustive for the remaining SearchModelType values
                      switch (resultsModelType) {
                        case SearchModelType.headline:
                          final headline = item as Headline;
                          final imageStyle =
                              context
                                  .watch<AppBloc>()
                                  .state
                                  .settings
                                  .feedPreferences
                                  .headlineImageStyle;
                          Widget tile;
                          switch (imageStyle) {
                            case HeadlineImageStyle.hidden:
                              tile = HeadlineTileTextOnly(
                                headline: headline,
                                onHeadlineTap:
                                    () => context.goNamed(
                                      Routes.searchArticleDetailsName,
                                      pathParameters: {'id': headline.id},
                                      extra: headline,
                                    ),
                              );
                            case HeadlineImageStyle.smallThumbnail:
                              tile = HeadlineTileImageStart(
                                headline: headline,
                                onHeadlineTap:
                                    () => context.goNamed(
                                      Routes.searchArticleDetailsName,
                                      pathParameters: {'id': headline.id},
                                      extra: headline,
                                    ),
                              );
                            case HeadlineImageStyle.largeThumbnail:
                              tile = HeadlineTileImageTop(
                                headline: headline,
                                onHeadlineTap:
                                    () => context.goNamed(
                                      Routes.searchArticleDetailsName,
                                      pathParameters: {'id': headline.id},
                                      extra: headline,
                                    ),
                              );
                          }
                          return tile;
                        case SearchModelType.category:
                          return CategoryItemWidget(category: item as Category);
                        case SearchModelType.source:
                          return SourceItemWidget(source: item as Source);
                      }
                    },
                  ),
            HeadlinesSearchFailure(
              errorMessage: final errorMessage,
              lastSearchTerm: final lastSearchTerm,
              selectedModelType: final failedModelType,
            ) =>
              FailureStateWidget(
                message:
                    'Failed to search $lastSearchTerm in ${failedModelType.displayName.toLowerCase()}:\n$errorMessage',
                onRetry:
                    () => context.read<HeadlinesSearchBloc>().add(
                      HeadlinesSearchFetchRequested(searchTerm: lastSearchTerm),
                    ),
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  String _getHintTextForModelType(
    SearchModelType modelType,
    AppLocalizations l10n,
  ) {
    // The switch is now exhaustive for the remaining SearchModelType values
    switch (modelType) {
      case SearchModelType.headline:
        return l10n.searchHintTextHeadline;
      case SearchModelType.category:
        return l10n.searchHintTextCategory;
      case SearchModelType.source:
        return l10n.searchHintTextSource;
    }
  }
}
