import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/initial_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';

class HeadlinesFeedPage extends StatefulWidget {
  const HeadlinesFeedPage({super.key});

  @override
  State<HeadlinesFeedPage> createState() => _HeadlinesFeedPageState();
}

class _HeadlinesFeedPageState extends State<HeadlinesFeedPage> {
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
    if (_isBottom) {
      context.read<HeadlinesFeedBloc>().add(HeadlinesFeedFetchRequested());
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
      appBar: AppBar(title: const Text('Headlines Feed')),
      body: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
        builder: (context, state) {
          switch (state) {
            case HeadlinesFeedInitial():
              return const InitialStateWidget();
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
