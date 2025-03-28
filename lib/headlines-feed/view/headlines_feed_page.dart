import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart'; // Keep one
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart'; // Keep one
// Removed duplicate imports
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Adjust leading width if needed, or let it size naturally
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min, // Keep icons close together
          children: [
            // const SizedBox(width: AppSpacing.sm), // Add some leading space
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              selectedIcon: const Icon(Icons.account_circle_rounded),
              onPressed: () {
                // Navigate to the Account page
                context.goNamed(Routes.accountName);
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              selectedIcon: const Icon(Icons.notifications_rounded),
              onPressed: () {},
            ),
            // Removed SizedBox between icons for tighter grouping
          ],
        ),
        title: Text(
          'HT', // Consider localizing this if needed
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold, // Example: Make title bolder
          ),
        ),
        centerTitle: true,
        actions: [
          // Add consistent spacing before actions
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.goNamed(Routes.searchName);
            },
          ),
          BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
            builder: (context, state) {
              var isFilterApplied = false;
              if (state is HeadlinesFeedLoaded) {
                isFilterApplied =
                    state.filter.category != null ||
                    state.filter.source != null ||
                    state.filter.eventCountry != null;
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
                      // Removed duplicate top: 8
                      top: AppSpacing.sm, // Use constant
                      right: AppSpacing.sm, // Use constant
                      child: Container(
                        width: AppSpacing.sm, // Use constant
                        height: AppSpacing.sm, // Use constant
                        decoration: BoxDecoration(
                          color: colorScheme.primary, // Use variable
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
              return const LoadingStateWidget(
                icon: Icons.hourglass_empty,
                headline: 'Loading...',
                subheadline: 'Fetching headlines',
              );
            // this silentcase will never be reached
            // it here just to fullfill the Exhaustiveness
            // Checking os the sealed state.
            case HeadlinesFeedLoadingSilently():
              return const Placeholder();
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
                  // Add vertical padding within the list
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.xxl,
                  ),
                  itemCount:
                      state.hasMore
                          ? state.headlines.length + 1
                          : state.headlines.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(
                        height: AppSpacing.lg,
                      ), // Consistent spacing
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
          } // End of switch
        }, // End of builder
      ), // End of Padding (body)
    ); // End of Scaffold
  } // End of build method
} // End of _HeadlinesFeedViewState class

// Removed the entire duplicated body: Padding(...) block below this line

// Removed import from here, moved to top

class _HeadlinesFilterBottomSheet extends StatefulWidget {
  const _HeadlinesFilterBottomSheet({required this.bloc});

  final HeadlinesFeedBloc bloc;

  @override
  State<_HeadlinesFilterBottomSheet> createState() =>
      _HeadlinesFilterBottomSheetState();
}

class _HeadlinesFilterBottomSheetState
    extends State<_HeadlinesFilterBottomSheet> {
  String? selectedCategory;
  String? selectedSource;
  String? selectedEventCountry;

  @override
  void initState() {
    super.initState();
    final state = widget.bloc.state;
    if (state is HeadlinesFeedLoaded) {
      selectedCategory = state.filter.category;
      selectedSource = state.filter.source;
      selectedEventCountry = state.filter.eventCountry;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
            children: [
              Text(
                'Filter Headlines', // TODO(fulleni): Localize
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl), // Increased spacing
              // Category Dropdown
              DropdownButtonFormField<String>(
                // TODO(fulleni): Localize labelText
                decoration: const InputDecoration(labelText: 'Category'),
                value: selectedCategory,
                // TODO(fulleni): Populate items dynamically from repository/config
                items: const [
                  DropdownMenuItem<String>(
                    child: Text('All'),
                  ), // Use null value for 'All'
                  DropdownMenuItem(
                    value: 'technology',
                    child: Text('Technology'), // TODO(fulleni): Localize
                  ),
                  DropdownMenuItem(
                    value: 'business',
                    child: Text('Business'), // TODO(fulleni): Localize
                  ),
                  DropdownMenuItem(
                    value: 'sports', // Corrected value
                    child: Text('Sports'), // TODO(fulleni): Localize
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg), // Use constant
              // Source Dropdown
              DropdownButtonFormField<String>(
                // TODO(fulleni): Localize labelText
                decoration: const InputDecoration(labelText: 'Source'),
                value: selectedSource,
                // TODO(fulleni): Populate items dynamically
                items: const [
                  DropdownMenuItem<String>(
                    child: Text('All'),
                  ), // Use null value
                  DropdownMenuItem(
                    value: 'cnn',
                    child: Text('CNN'), // TODO(fulleni): Localize
                  ),
                  DropdownMenuItem(
                    value: 'reuters',
                    child: Text('Reuters'), // TODO(fulleni): Localize
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSource = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg), // Use constant
              // Event Country Dropdown
              DropdownButtonFormField<String>(
                // TODO(fulleni): Localize labelText
                decoration: const InputDecoration(labelText: 'Event Country'),
                value: selectedEventCountry,
                // TODO(fulleni): Populate items dynamically
                items: const [
                  DropdownMenuItem<String>(
                    child: Text('All'),
                  ), // Use null value
                  DropdownMenuItem(
                    value: 'US',
                    child: Text('United States'), // TODO(fulleni): Localize
                  ),
                  DropdownMenuItem(
                    value: 'UK',
                    child: Text('United Kingdom'), // TODO(fulleni): Localize
                  ),
                  DropdownMenuItem(
                    value: 'CA',
                    child: Text('Canada'), // TODO(fulleni): Localize
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedEventCountry = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl), // Use constant
              // Use FilledButton for primary action
              FilledButton(
                onPressed: () {
                  widget.bloc.add(
                    HeadlinesFeedFilterChanged(
                      // Pass null if 'All' was selected
                      category:
                          selectedCategory == 'All' ? null : selectedCategory,
                      source: selectedSource == 'All' ? null : selectedSource,
                      eventCountry:
                          selectedEventCountry == 'All'
                              ? null
                              : selectedEventCountry,
                    ),
                  );
                  Navigator.pop(context);
                },
                // TODO(fulleni): Localize text
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height: AppSpacing.sm), // Use constant
              TextButton(
                // Style is correctly using theme error color
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                    selectedSource = null;
                    selectedEventCountry = null;
                  });
                  widget.bloc.add(const HeadlinesFeedFilterChanged());
                  Navigator.pop(context);
                },
                // TODO(fulleni): Localize text
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
