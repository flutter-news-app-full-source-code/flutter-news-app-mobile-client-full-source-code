import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/headlines-feed/bloc/topics_filter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:ht_ui_kit/ht_ui_kit.dart';

class TopicFilterPage extends StatefulWidget {
  const TopicFilterPage({super.key});

  @override
  State<TopicFilterPage> createState() => _TopicFilterPageState();
}

class _TopicFilterPageState extends State<TopicFilterPage> {
  final _scrollController = ScrollController();
  late final TopicsFilterBloc _topicsFilterBloc;
  late Set<Topic> _pageSelectedTopics;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _topicsFilterBloc = context.read<TopicsFilterBloc>()
      ..add(TopicsFilterRequested());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialSelection = GoRouterState.of(context).extra as List<Topic>?;
      _pageSelectedTopics = Set.from(initialSelection ?? []);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _topicsFilterBloc.add(TopicsFilterLoadMoreRequested());
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
    final l10n = AppLocalizationsX(context).l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.headlinesFeedFilterTopicLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              context.pop(_pageSelectedTopics.toList());
            },
          ),
        ],
      ),
      body: BlocBuilder<TopicsFilterBloc, TopicsFilterState>(
        builder: (context, state) {
          switch (state.status) {
            case TopicsFilterStatus.initial:
            case TopicsFilterStatus.loading:
              return LoadingStateWidget(
                icon: Icons.category_outlined,
                headline: l10n.topicFilterLoadingHeadline,
                subheadline: l10n.pleaseWait,
              );
            case TopicsFilterStatus.failure:
              return Center(
                child: FailureStateWidget(
                  exception: state.error ??
                      const UnknownException(
                        'An unknown error occurred while fetching topics.',
                      ),
                  onRetry: () =>
                      _topicsFilterBloc.add(TopicsFilterRequested()),
                ),
              );
            case TopicsFilterStatus.success:
            case TopicsFilterStatus.loadingMore:
              if (state.topics.isEmpty) {
                return InitialStateWidget(
                  icon: Icons.category_outlined,
                  headline: l10n.topicFilterEmptyHeadline,
                  subheadline: l10n.topicFilterEmptySubheadline,
                );
              }
              return ListView.builder(
                controller: _scrollController,
                itemCount: state.hasMore
                    ? state.topics.length + 1
                    : state.topics.length,
                itemBuilder: (context, index) {
                  if (index >= state.topics.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final topic = state.topics[index];
                  final isSelected = _pageSelectedTopics.contains(topic);
                  return CheckboxListTile(
                    title: Text(topic.name),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _pageSelectedTopics.add(topic);
                        } else {
                          _pageSelectedTopics.remove(topic);
                        }
                      });
                    },
                  );
                },
              );
          }
        },
      ),
    );
  }
}
