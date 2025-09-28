import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_decorators/suggestion_item_widget.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template content_collection_decorator_widget}
/// A widget to display a horizontally scrollable list of suggested content
/// (e.g., Topics or Sources).
///
/// This widget presents a title, a horizontal list of [SuggestionItemWidget]s,
/// and a dismiss option via a [PopupMenuButton].
/// {@endtemplate}
class ContentCollectionDecoratorWidget extends StatelessWidget {
  /// {@macro content_collection_decorator_widget}
  const ContentCollectionDecoratorWidget({
    required this.item,
    required this.onFollowToggle,
    required this.onDismiss,
    required this.followedTopicIds,
    required this.followedSourceIds,
    super.key,
  });

  /// The [ContentCollectionItem] to display.
  final ContentCollectionItem item;

  /// Callback function when the follow/unfollow button on a suggestion item
  /// is pressed.
  final ValueSetter<FeedItem> onFollowToggle;

  /// Callback function when the dismiss option is selected.
  final ValueSetter<FeedDecoratorType> onDismiss;

  /// List of IDs of topics the user is currently following.
  final List<String> followedTopicIds;

  /// List of IDs of sources the user is currently following.
  final List<String> followedSourceIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    String getTitle() {
      switch (item.decoratorType) {
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
          return item.title;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'dismiss') {
                      onDismiss(item.decoratorType);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'dismiss',
                      child: Text(l10n.neverShowAgain),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: item.items.length,
                itemBuilder: (context, index) {
                  final suggestion = item.items[index];
                  final isFollowing =
                      (suggestion is Topic &&
                          followedTopicIds.contains(suggestion.id)) ||
                      (suggestion is Source &&
                          followedSourceIds.contains(suggestion.id));
                  return SuggestionItemWidget(
                    item: suggestion,
                    onFollowToggle: onFollowToggle,
                    isFollowing: isFollowing,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
