import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/l10n/l10n.dart';
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
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Removed leadingWidth and leading Row
        title: Text(
          'HT', // TODO(fulleni): Localize this title
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Removed Search IconButton
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
              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.headlinesFeedFilterCategoryLabel,
                ),
                value: selectedCategory,
                // TODO(fulleni): Populate items dynamically from repository/config
                items: [
                  DropdownMenuItem<String>(
                    child: Text(l10n.headlinesFeedFilterAllOption),
                  ),
                  DropdownMenuItem(
                    value: 'technology',
                    child: Text(l10n.headlinesFeedFilterCategoryTechnology),
                  ),
                  DropdownMenuItem(
                    value: 'business',
                    child: Text(l10n.headlinesFeedFilterCategoryBusiness),
                  ),
                  DropdownMenuItem(
                    value: 'sports',
                    child: Text(l10n.headlinesFeedFilterCategorySports),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Source Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.headlinesFeedFilterSourceLabel,
                ),
                value: selectedSource,
                // TODO(fulleni): Populate items dynamically
                items: [
                  DropdownMenuItem<String>(
                    child: Text(l10n.headlinesFeedFilterAllOption),
                  ),
                  DropdownMenuItem(
                    value: 'cnn',
                    child: Text(l10n.headlinesFeedFilterSourceCNN),
                  ),
                  DropdownMenuItem(
                    value: 'reuters',
                    child: Text(l10n.headlinesFeedFilterSourceReuters),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSource = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Event Country Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.headlinesFeedFilterEventCountryLabel,
                ),
                value: selectedEventCountry,
                // TODO(fulleni): Populate items dynamically
                items: [
                  DropdownMenuItem<String>(
                    child: Text(l10n.headlinesFeedFilterAllOption),
                  ),
                  DropdownMenuItem(
                    value: 'US',
                    child: Text(l10n.headlinesFeedFilterCountryUS),
                  ),
                  DropdownMenuItem(
                    value: 'UK',
                    child: Text(l10n.headlinesFeedFilterCountryUK),
                  ),
                  DropdownMenuItem(
                    value: 'CA',
                    child: Text(l10n.headlinesFeedFilterCountryCA),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedEventCountry = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              // Use FilledButton for primary action
              FilledButton(
                onPressed: () {
                  widget.bloc.add(
                    HeadlinesFeedFilterChanged(
                      // Pass null if 'All' was selected (value is null now)
                      category: selectedCategory,
                      source: selectedSource,
                      eventCountry: selectedEventCountry,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text(l10n.headlinesFeedFilterApplyButton),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                    selectedSource = null;
                    selectedEventCountry = null;
                  });
                  widget.bloc.add(const HeadlinesFeedFilterChanged());
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
