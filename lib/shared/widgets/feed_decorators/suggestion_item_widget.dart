import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template suggestion_item_widget}
/// A widget to display a single suggested item (Topic or Source) within a
/// horizontal list.
///
/// This widget presents a rectangular card containing a square image/icon
/// and a "Follow" button.
/// {@endtemplate}
class SuggestionItemWidget extends StatelessWidget {
  /// {@macro suggestion_item_widget}
  const SuggestionItemWidget({
    required this.item,
    required this.onFollowToggle,
    required this.isFollowing,
    super.key,
  });

  /// The [FeedItem] (either [Topic] or [Source]) to display.
  final FeedItem item;

  /// Callback function when the follow/unfollow button is pressed.
  final ValueSetter<FeedItem> onFollowToggle;

  /// Indicates whether the user is currently following this item.
  final bool isFollowing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    String imageUrl;
    String name;
    if (item is Topic) {
      final topic = item as Topic;
      imageUrl = topic.iconUrl;
      name = topic.name;
    } else if (item is Source) {
      final source = item as Source;
      imageUrl = source.logoUrl;
      name = source.name;
    } else {
      // Fallback for unexpected types, though type checking should prevent this
      imageUrl = '';
      name = 'Unknown';
    }

    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    item is Source
                        ? Icons.source_outlined
                        : Icons.category_outlined,
                    size: AppSpacing.xxl,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                name,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                AppSpacing.sm,
              ).copyWith(top: AppSpacing.xs),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => onFollowToggle(item),
                child: FittedBox(
                  child: Text(
                    isFollowing
                        ? l10n.unfollowButtonText
                        : l10n.followButtonText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
