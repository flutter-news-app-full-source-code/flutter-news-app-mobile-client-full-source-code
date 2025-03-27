import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/initial_state_widget.dart';

class HeadlinesSearchView extends StatefulWidget {
  const HeadlinesSearchView({super.key});

  @override
  State<HeadlinesSearchView> createState() => _HeadlinesSearchViewState();
}

class _HeadlinesSearchViewState extends State<HeadlinesSearchView> {
  final _scrollController = ScrollController();
  String? searchTerm;

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
    final state = context.read<HeadlinesSearchBloc>().state;
    if (_isBottom && state is HeadlinesSearchSuccess) {
      final searchTerm = state.lastSearchTerm;
      if (state.hasMore) {
        context.read<HeadlinesSearchBloc>().add(
          HeadlinesSearchFetchRequested(searchTerm: searchTerm!),
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
        title: TextField(
          decoration: const InputDecoration(hintText: 'Search Headlines...'),
          onChanged: (value) {
            searchTerm = value;
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.read<HeadlinesSearchBloc>().add(
                HeadlinesSearchFetchRequested(searchTerm: searchTerm ?? ''),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesSearchBloc, HeadlinesSearchState>(
        builder: (context, state) {
          return switch (state) {
            HeadlinesSearchLoading() => const InitialStateWidget(
              icon: Icons.search,
              headline: 'Search Headlines',
              subheadline: 'Enter keywords to find articles',
            ),
            HeadlinesSearchSuccess(
              :final headlines,
              :final hasMore,
              :final errorMessage,
            ) =>
              errorMessage != null
                  ? FailureStateWidget(
                    message: errorMessage,
                    onRetry: () {
                      context.read<HeadlinesSearchBloc>().add(
                        HeadlinesSearchFetchRequested(
                          searchTerm: searchTerm ?? '',
                        ),
                      );
                    },
                  )
                  : headlines.isEmpty
                  ? const InitialStateWidget(
                    icon: Icons.search_off,
                    headline: 'No results',
                    subheadline: 'Try a different search term',
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        hasMore ? headlines.length + 1 : headlines.length,
                    itemBuilder: (context, index) {
                      if (index >= headlines.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return HeadlineItemWidget(headline: headlines[index]);
                    },
                  ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
