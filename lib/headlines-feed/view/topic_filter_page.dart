import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      ..add(TopicsFilterRequested()); // Initial fetch of all topics

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
          BlocBuilder<TopicsFilterBloc, TopicsFilterState>(
            builder: (context, state) {
              // Determine if the "Apply My Followed" icon should be filled
              // This logic checks if all currently selected topics are
              // also present in the fetched followed topics list.
              final followedTopicsSet = state.followedTopics.toSet();
              final isFollowedFilterActive =
                  followedTopicsSet.isNotEmpty &&
                  _pageSelectedTopics.length == followedTopicsSet.length &&
                  _pageSelectedTopics.containsAll(followedTopicsSet);

              return IconButton(
                icon: isFollowedFilterActive
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                color: isFollowedFilterActive
                    ? theme.colorScheme.primary
                    : null,
                tooltip: l10n.headlinesFeedFilterApplyFollowedLabel,
                onPressed:
                    state.followedTopicsStatus == TopicsFilterStatus.loading
                    ? null // Disable while loading
                    : () {
                        // Dispatch event to BLoC to fetch and apply followed topics
                        _topicsFilterBloc.add(
                          TopicsFilterApplyFollowedRequested(),
                        );
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
      body: BlocListener<TopicsFilterBloc, TopicsFilterState>(
        // Listen for changes in followedTopicsStatus or followedTopics
        listenWhen: (previous, current) =>
            previous.followedTopicsStatus != current.followedTopicsStatus ||
            previous.followedTopics != current.followedTopics,
        listener: (context, state) {
          if (state.followedTopicsStatus == TopicsFilterStatus.success) {
            // Update local state with followed topics from BLoC
            setState(() {
              _pageSelectedTopics = Set.from(state.followedTopics);
            });
            if (state.followedTopics.isEmpty) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.noFollowedItemsForFilterSnackbar),
                    duration: const Duration(seconds: 3),
                  ),
                );
            }
          } else if (state.followedTopicsStatus == TopicsFilterStatus.failure) {
            // Show error message if fetching followed topics failed
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error?.message ?? l10n.unknownError),
                  duration: const Duration(seconds: 3),
                ),
              );
          }
        },
        child: BlocBuilder<TopicsFilterBloc, TopicsFilterState>(
          builder: (context, state) {
            // Determine overall loading status for the main list
            final isLoadingMainList =
                state.status == TopicsFilterStatus.initial ||
                state.status == TopicsFilterStatus.loading;

            // Determine if followed topics are currently loading
            final isLoadingFollowedTopics =
                state.followedTopicsStatus == TopicsFilterStatus.loading;

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

            return Stack(
              children: [
                ListView.builder(
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
                ),
                // Show loading overlay if followed topics are being fetched
                if (isLoadingFollowedTopics)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54, // Semi-transparent overlay
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.headlinesFeedLoadingHeadline,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
