import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';

class HeadlinesFeedPage extends StatelessWidget {
  const HeadlinesFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HeadlinesFeedBloc(
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
    context.read<HeadlinesFeedBloc>().add(HeadlinesFeedRefreshRequested());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<HeadlinesFeedBloc>().state;
      if (state is HeadlinesFeedLoaded) {
        context
            .read<HeadlinesFeedBloc>()
            .add(const HeadlinesFeedFetchRequested());
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Headlines Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              final bloc = context.read<HeadlinesFeedBloc>();
              showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext context) {
                  return _HeadlinesFilterBottomSheet(
                    bloc: bloc,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
        builder: (context, state) {
          switch (state) {
            case HeadlinesFeedLoading():
              return const LoadingStateWidget();
            case HeadlinesFeedLoaded():
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<HeadlinesFeedBloc>()
                      .add(HeadlinesFeedRefreshRequested());
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.hasMore
                      ? state.headlines.length + 1
                      : state.headlines.length,
                  itemBuilder: (context, index) {
                    if (index >= state.headlines.length) {
                      return const LoadingStateWidget();
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
                  context
                      .read<HeadlinesFeedBloc>()
                      .add(HeadlinesFeedRefreshRequested());
                },
              );
          }
        },
      ),
    );
  }
}

class _HeadlinesFilterBottomSheet extends StatefulWidget {
  const _HeadlinesFilterBottomSheet({
    required this.bloc,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Headlines',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Category Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: selectedCategory,
              items: const [
                // Placeholder items
                DropdownMenuItem(value: 'technology', child: Text('Technology')),
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
          ],
        ),
      ),
    );
  }
}
