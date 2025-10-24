import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_decorators/suggestion_item_widget.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template content_collection_decorator_widget}
/// A widget to display a horizontally scrollable list of suggested content
/// (e.g., Topics or Sources).
///
/// This widget presents a title and a horizontal list of [SuggestionItemWidget]s.
/// {@endtemplate}
class ContentCollectionDecoratorWidget extends StatelessWidget {
  /// {@macro content_collection_decorator_widget}
  const ContentCollectionDecoratorWidget({
    required this.item,
    required this.onFollowToggle,
    required this.followedTopicIds,
    required this.followedSourceIds,
    super.key,
  });

  /// The [ContentCollectionItem] to display.
  final ContentCollectionItem item;

  /// Callback function when the follow/unfollow button on a suggestion item
  /// is pressed.
  final ValueSetter<FeedItem> onFollowToggle;

  /// List of IDs of topics the user is currently following.
  final List<String> followedTopicIds;

  /// List of IDs of sources the user is currently following.
  final List<String> followedSourceIds;

  @override
  Widget build(BuildContext context) {
    return _ContentCollectionView(
      item: item,
      onFollowToggle: onFollowToggle,
      followedTopicIds: followedTopicIds,
      followedSourceIds: followedSourceIds,
    );
  }
}

class _ContentCollectionView extends StatefulWidget {
  const _ContentCollectionView({
    required this.item,
    required this.onFollowToggle,
    required this.followedTopicIds,
    required this.followedSourceIds,
  });

  final ContentCollectionItem item;
  final ValueSetter<FeedItem> onFollowToggle;
  final List<String> followedTopicIds;
  final List<String> followedSourceIds;

  @override
  State<_ContentCollectionView> createState() => _ContentCollectionViewState();
}

class _ContentCollectionViewState extends State<_ContentCollectionView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    String getTitle() {
      switch (widget.item.decoratorType) {
        case FeedDecoratorType.suggestedTopics:
          return l10n.suggestedTopicsTitle;
        case FeedDecoratorType.suggestedSources:
          return l10n.suggestedSourcesTitle;
        // The following cases are for call-to-action types and should not
        // appear in a content collection, but we handle them gracefully.
        case FeedDecoratorType.linkAccount:
        case FeedDecoratorType.upgrade:
        case FeedDecoratorType.rateApp:
        case FeedDecoratorType.enableNotifications:
          return widget.item.title;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    getTitle(),
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final listView = ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.item.items.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = widget.item.items[index];
                    final isFollowing =
                        (suggestion is Topic &&
                            widget.followedTopicIds.contains(suggestion.id)) ||
                        (suggestion is Source &&
                            widget.followedSourceIds.contains(suggestion.id));
                    return SuggestionItemWidget(
                      item: suggestion,
                      onFollowToggle: widget.onFollowToggle,
                      isFollowing: isFollowing,
                    );
                  },
                );

                var showStartFade = false;
                var showEndFade = false;
                if (_scrollController.hasClients &&
                    _scrollController.position.maxScrollExtent > 0) {
                  final pixels = _scrollController.position.pixels;
                  final minScroll = _scrollController.position.minScrollExtent;
                  final maxScroll = _scrollController.position.maxScrollExtent;

                  if (pixels > minScroll) {
                    showStartFade = true;
                  }
                  if (pixels < maxScroll) {
                    showEndFade = true;
                  }
                }

                final colors = <Color>[
                  if (showStartFade) Colors.transparent,
                  Colors.black,
                  Colors.black,
                  if (showEndFade) Colors.transparent,
                ];

                final stops = <double>[
                  if (showStartFade) 0.0,
                  if (showStartFade) 0.05 else 0.0,
                  if (showEndFade) 0.95 else 1.0,
                  if (showEndFade) 1.0,
                ];

                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: colors,
                    stops: stops,
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: listView,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
