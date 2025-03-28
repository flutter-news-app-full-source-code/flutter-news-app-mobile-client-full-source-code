import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/router/routes.dart';
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
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: Row(
          children: [
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
          ],
        ),
        title: const Text('HT'),
        centerTitle: true,
        actions: [
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
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
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
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      state.hasMore
                          ? state.headlines.length + 1
                          : state.headlines.length,
                  itemBuilder: (context, index) {
                    if (index >= state.headlines.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final headline = state.headlines[index];
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
    return BlocProvider.value(
      value: widget.bloc,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text(
              //   'Filter Headlines',
              //   style: Theme.of(context).textTheme.titleLarge,
              // ),
              const SizedBox(height: 16),
              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                value: selectedCategory,
                items: const [
                  // Placeholder items
                  DropdownMenuItem<String>(child: Text('All')),
                  DropdownMenuItem(
                    value: 'technology',
                    child: Text('Technology'),
                  ),
                  DropdownMenuItem(value: 'business', child: Text('Business')),
                  DropdownMenuItem(value: 'Politics', child: Text('Sports')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Source Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Source'),
                value: selectedSource,
                items: const [
                  // Placeholder items
                  DropdownMenuItem<String>(child: Text('All')),
                  DropdownMenuItem(value: 'cnn', child: Text('CNN')),
                  DropdownMenuItem(value: 'reuters', child: Text('Reuters')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSource = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Event Country Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Event Country'),
                value: selectedEventCountry,
                items: const [
                  // Placeholder items
                  DropdownMenuItem<String>(child: Text('All')),
                  DropdownMenuItem(value: 'US', child: Text('United States')),
                  DropdownMenuItem(value: 'UK', child: Text('United Kingdom')),
                  DropdownMenuItem(value: 'CA', child: Text('Canada')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedEventCountry = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  widget.bloc.add(
                    HeadlinesFeedFilterChanged(
                      category: selectedCategory,
                      source: selectedSource,
                      eventCountry: selectedEventCountry,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                    selectedSource = null;
                    selectedEventCountry = null;
                  });
                  widget.bloc.add(const HeadlinesFeedFilterChanged());
                  Navigator.pop(context);
                },
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
