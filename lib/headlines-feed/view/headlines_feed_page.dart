import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/view/headline_filter_bottom_sheet.dart';
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
              showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext context) {
                  final bloc = context.read<HeadlinesFeedBloc>();
                  return BlocProvider.value(
                    value: bloc,
                    child: HeadlineFilterBottomSheet(
                      bloc: bloc,
                      onApplyFilters: (category, source, eventCountry) {
                        bloc.add(
                          HeadlinesFeedFilterChanged(
                            category: category,
                            source: source,
                            eventCountry: eventCountry,
                          ),
                        );
                      },
                    ),
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
