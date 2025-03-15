import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/initial_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';

class HeadlinesSearchView extends StatelessWidget {
  const HeadlinesSearchView({super.key});

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
            HeadlinesSearchLoaded(:final headlines) =>
              _HeadlinesSearchLoadedView(headlines: headlines),
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
}

class _HeadlinesSearchLoadedView extends StatelessWidget {
  const _HeadlinesSearchLoadedView({required this.headlines});

  final List<Headline> headlines;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: headlines.length,
      itemBuilder: (context, index) {
        return HeadlineItemWidget(headline: headlines[index]);
      },
    );
  }
}
