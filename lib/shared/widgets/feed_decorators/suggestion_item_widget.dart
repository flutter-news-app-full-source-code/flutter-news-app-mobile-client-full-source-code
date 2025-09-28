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
      // TODO(fulleni): Add imageUrl to the Source model for a richer UI.
      imageUrl = '';
      name = source.name;
    } else {
      // Fallback for unexpected types, though type checking should prevent this
      imageUrl = '';
      name = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SizedBox(
        width: 160,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Square image/icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Icon(
                        // Use a more specific icon for sources as a fallback.
                        item is Source ? Icons.source : Icons.category,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => onFollowToggle(item),
                child: Text(
                  isFollowing ? l10n.unfollowButtonText : l10n.followButtonText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
