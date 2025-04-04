import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_categories_client/ht_categories_client.dart'; // Import Category
import 'package:ht_countries_client/ht_countries_client.dart'; // Import Country
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';
import 'package:ht_sources_client/ht_sources_client.dart'; // Import Source

class HeadlinesFeedPage extends StatelessWidget {
  const HeadlinesFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => HeadlinesFeedBloc(
            headlinesRepository: context.read<HtHeadlinesRepository>(),
          )..add(const HeadlinesFeedFetchRequested()),
      child: const _HeadlinesFeedView(),
    );
  }
}

class _HeadlinesFeedView extends StatefulWidget {
  const _HeadlinesFeedView();

  @override
  State<_HeadlinesFeedView> createState() => _HeadlinesFeedViewState();
}

class _HeadlinesFeedViewState extends State<_HeadlinesFeedView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<HeadlinesFeedBloc>().state;
    if (_isBottom && state is HeadlinesFeedLoaded) {
      if (state.hasMore) {
        context.read<HeadlinesFeedBloc>().add(
          const HeadlinesFeedFetchRequested(),
        );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.98);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HT', // TODO(fulleni): Localize this title
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l10n.notificationsTooltip, // Add tooltip for accessibility
            onPressed: () {
              context.goNamed(
                Routes.notificationsName,
              ); // Ensure correct route name
            },
          ),
          BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
            builder: (context, state) {
              var isFilterApplied = false;
              if (state is HeadlinesFeedLoaded) {
                // Check if any filter list is non-null and not empty
                isFilterApplied =
                    (state.filter.categories?.isNotEmpty ?? false) ||
                    (state.filter.sources?.isNotEmpty ?? false) ||
                    (state.filter.eventCountries?.isNotEmpty ?? false);
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      final bloc = context.read<HeadlinesFeedBloc>();
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return _HeadlinesFilterBottomSheet(bloc: bloc);
                        },
                      );
                    },
                  ),
                  if (isFilterApplied)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
        buildWhen:
            (previous, current) => current is! HeadlinesFeedLoadingSilently,
        builder: (context, state) {
          switch (state) {
            case HeadlinesFeedLoading():
              return LoadingStateWidget(
                icon: Icons.hourglass_empty,
                headline: l10n.headlinesFeedLoadingHeadline,
                subheadline: l10n.headlinesFeedLoadingSubheadline,
              );

            case HeadlinesFeedLoadingSilently():
              // This case is technically unreachable due to buildWhen,
              // but required for exhaustive switch.
              return const SizedBox.shrink();
            case HeadlinesFeedLoaded():
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedRefreshRequested(),
                  );
                },
                // Use ListView.separated for consistent spacing
                child: ListView.separated(
                  controller: _scrollController,

                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.xxl,
                  ),
                  itemCount:
                      state.hasMore
                          ? state.headlines.length + 1
                          : state.headlines.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    if (index >= state.headlines.length) {
                      // Improved loading indicator
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final headline = state.headlines[index];
                    // HeadlineItemWidget now handles its own internal padding
                    return HeadlineItemWidget(headline: headline);
                  },
                ),
              );
            case HeadlinesFeedError():
              return FailureStateWidget(
                message: state.message,
                onRetry: () {
                  context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedRefreshRequested(),
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class _HeadlinesFilterBottomSheet extends StatefulWidget {
  const _HeadlinesFilterBottomSheet({required this.bloc});

  final HeadlinesFeedBloc bloc;

  @override
  State<_HeadlinesFilterBottomSheet> createState() =>
      _HeadlinesFilterBottomSheetState();
}

class _HeadlinesFilterBottomSheetState
    extends State<_HeadlinesFilterBottomSheet> {
  // Use lists to store selected filters
  List<Category> selectedCategories = [];
  List<Source> selectedSources = [];
  List<Country> selectedEventCountries = [];

  @override
  void initState() {
    super.initState();
    final state = widget.bloc.state;
    if (state is HeadlinesFeedLoaded) {
      // Initialize lists from the current filter state, handle nulls
      selectedCategories = List.from(state.filter.categories ?? []);
      selectedSources = List.from(state.filter.sources ?? []);
      selectedEventCountries = List.from(state.filter.eventCountries ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider.value(
      value: widget.bloc,
      // Add symmetric padding for consistency
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.headlinesFeedFilterTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Category Filters ---
              Text(
                l10n.headlinesFeedFilterCategoryLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              // TODO(cline): Implement multi-select UI for categories
              // Fetch available categories from a repository
              // Use Wrap + FilterChip to display options
              // Update selectedCategories list in setState when chips are toggled
              // Example placeholder:
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Text('Category FilterChip UI Placeholder'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // --- Source Filters ---
              Text(
                l10n.headlinesFeedFilterSourceLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              // TODO(cline): Implement multi-select UI for sources
              // Fetch available sources from a repository
              // Use Wrap + FilterChip to display options
              // Update selectedSources list in setState when chips are toggled
              // Example placeholder:
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Text('Source FilterChip UI Placeholder'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // --- Event Country Filters ---
              Text(
                l10n.headlinesFeedFilterEventCountryLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              // TODO(cline): Implement multi-select UI for event countries
              // Fetch available countries from a repository
              // Use Wrap + FilterChip to display options
              // Update selectedEventCountries list in setState when chips are toggled
              // Example placeholder:
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Text('Country FilterChip UI Placeholder'),
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Action Buttons ---
              FilledButton(
                onPressed: () {
                  widget.bloc.add(
                    HeadlinesFeedFilterChanged(
                      // Pass the selected lists
                      categories:
                          selectedCategories.isNotEmpty
                              ? selectedCategories
                              : null,
                      sources:
                          selectedSources.isNotEmpty ? selectedSources : null,
                      eventCountries:
                          selectedEventCountries.isNotEmpty
                              ? selectedEventCountries
                              : null,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text(l10n.headlinesFeedFilterApplyButton),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  // Clear local state lists
                  setState(() {
                    selectedCategories.clear();
                    selectedSources.clear();
                    selectedEventCountries.clear();
                  });
                  // Dispatch event with null lists to clear filters in BLoC
                  widget.bloc.add(
                    const HeadlinesFeedFilterChanged(
                      categories: null,
                      sources: null,
                      eventCountries: null,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text(l10n.headlinesFeedFilterResetButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
