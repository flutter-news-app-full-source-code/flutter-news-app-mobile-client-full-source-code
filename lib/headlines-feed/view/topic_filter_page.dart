import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/topics_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template topic_filter_page}
/// A page dedicated to selecting news topics for filtering headlines.
/// {@endtemplate}
class TopicFilterPage extends StatefulWidget {
  /// {@macro topic_filter_page}
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
      // Initialize local selection from GoRouter extra parameter
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedFilterTopicLabel,
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          // Apply My Followed Topics Button
          BlocBuilder<AppBloc, AppState>(
            builder: (context, appState) {
              final followedTopics =
                  appState.userContentPreferences?.followedTopics ?? [];
              final isFollowedFilterActive = followedTopics.isNotEmpty &&
                  _pageSelectedTopics.length == followedTopics.length &&
                  _pageSelectedTopics.containsAll(followedTopics);

              return IconButton(
                icon: isFollowedFilterActive
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                color: isFollowedFilterActive
                    ? theme.colorScheme.primary
                    : null,
                tooltip: l10n.headlinesFeedFilterApplyFollowedLabel,
                onPressed: () {
                  setState(() {
                    _pageSelectedTopics = Set.from(followedTopics);
                  });
                  if (followedTopics.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(l10n.noFollowedItemsForFilterSnackbar),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                  }
                },
              );
            },
          ),
          // Apply Filters Button
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
          // Determine overall loading status for the main list
          final isLoadingMainList =
              state.status == TopicsFilterStatus.initial ||
              state.status == TopicsFilterStatus.loading;

          if (isLoadingMainList) {
            return LoadingStateWidget(
              icon: Icons.category_outlined,
              headline: l10n.topicFilterLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (state.status == TopicsFilterStatus.failure &&
              state.topics.isEmpty) {
            return Center(
              child: FailureStateWidget(
                exception:
                    state.error ??
                    const UnknownException(
                      'An unknown error occurred while fetching topics.',
                    ),
                onRetry: () => _topicsFilterBloc.add(TopicsFilterRequested()),
              ),
            );
          }

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
        },
      ),
    );
  }
}
