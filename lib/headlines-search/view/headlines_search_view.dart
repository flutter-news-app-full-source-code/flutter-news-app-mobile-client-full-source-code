import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/initial_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';

class HeadlinesSearchView extends StatefulWidget {
  const HeadlinesSearchView({super.key});

  @override
  State<HeadlinesSearchView> createState() => _HeadlinesSearchViewState();
}

class _HeadlinesSearchViewState extends State<HeadlinesSearchView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search Headlines...',
          ),
          onChanged: (value) {
            context.read<HeadlinesSearchBloc>().add(
                  HeadlinesSearchTermChanged(searchTerm: value),
                );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.read<HeadlinesSearchBloc>().add(
                    HeadlinesSearchRequested(),
                  );
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesSearchBloc, HeadlinesSearchState>(
        builder: (context, state) {
          return switch (state) {
            HeadlinesSearchInitial() => const InitialStateWidget(
                icon: Icons.search,
                headline: 'Search Headlines',
                subheadline: 'Enter keywords to find articles',
              ),
            HeadlinesSearchLoading() => const LoadingStateWidget(
                icon: Icons.hourglass_empty,
                headline: 'Loading...',
                subheadline: 'Fetching headlines',
              ),
            HeadlinesSearchLoaded(
              :final headlines,
              :final hasReachedMax
            ) =>
              _HeadlinesSearchLoadedView(
                headlines: headlines,
                hasReachedMax: hasReachedMax,
              ),
            HeadlinesSearchError(:final message) => FailureStateWidget(
                message: message,
                onRetry: () {
                  context
                      .read<HeadlinesSearchBloc>()
                      .add(HeadlinesSearchRequested());
                },
              ),
          };
        },
      ),
    );
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
      context.read<HeadlinesSearchBloc>().add(HeadlinesSearchLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

class _HeadlinesSearchLoadedView extends StatelessWidget {
  const _HeadlinesSearchLoadedView({
    required this.headlines,
    required this.hasReachedMax,
  });

  final List<Headline> headlines;
  final bool hasReachedMax;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: hasReachedMax ? headlines.length : headlines.length + 1,
      itemBuilder: (context, index) {
        if (index >= headlines.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return HeadlineItemWidget(headline: headlines[index]);
      },
    );
  }
}
