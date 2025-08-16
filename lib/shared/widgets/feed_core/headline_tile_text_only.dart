import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_tile_text_only}
/// A widget to display a headline item with text only.
///
/// Used in feeds, search results, etc., when the image style is set to hidden.
/// {@endtemplate}
class HeadlineTileTextOnly extends StatelessWidget {
  /// {@macro headline_tile_text_only}
  const HeadlineTileTextOnly({
    required this.headline,
    super.key,
    this.onHeadlineTap,
    this.trailing,
    this.currentContextEntityType,
    this.currentContextEntityId,
  });

  /// The headline data to display.
  final Headline headline;

  /// Callback when the main content of the headline (e.g., title) is tapped.
  final VoidCallback? onHeadlineTap;

  /// An optional widget to display at the end of the tile.
  final Widget? trailing;

  /// The type of the entity currently being viewed in detail (e.g., on a category page).
  final ContentType? currentContextEntityType;

  /// The ID of the entity currently being viewed in detail.
  final String? currentContextEntityId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onHeadlineTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3, // Allow more lines for text-only
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _HeadlineMetadataRow(
                      headline: headline,
                      colorScheme: theme.colorScheme,
                      textTheme: textTheme,
                      currentContextEntityType:
                          currentContextEntityType, // Pass down
                      currentContextEntityId:
                          currentContextEntityId, // Pass down
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Private helper widget to build the metadata row.
class _HeadlineMetadataRow extends StatelessWidget {
  const _HeadlineMetadataRow({
    required this.headline,
    required this.colorScheme,
    required this.textTheme,
    this.currentContextEntityType,
    this.currentContextEntityId,
  });

  final Headline headline;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final ContentType? currentContextEntityType;
  final String? currentContextEntityId;

  @override
  Widget build(BuildContext context) {
    final formattedDate = timeago.format(headline.createdAt);

    // Use bodySmall for a reasonable base size, with muted accent color
    final metadataTextStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.primary.withOpacity(0.7),
    );
    // Icon color to match the subtle text
    final iconColor = colorScheme.primary.withOpacity(0.7);
    const iconSize = AppSpacing.sm; // Standard small icon size

    return Wrap(
      spacing: AppSpacing.sm, // Increased spacing for readability
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (formattedDate.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: iconSize,
                color: iconColor,
              ),
              const SizedBox(width: AppSpacing.xs / 2),
              Text(formattedDate, style: metadataTextStyle),
            ],
          ),
        // Conditionally render Topic as Text
        if (headline.topic.name.isNotEmpty &&
            !(currentContextEntityType == ContentType.topic &&
                headline.topic.id == currentContextEntityId)) ...[
          if (formattedDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('•', style: metadataTextStyle),
            ),
          GestureDetector(
            onTap: () {
              context.push(
                Routes.topicDetails,
                extra: EntityDetailsPageArguments(
                  entity: headline.topic,
                  contentType: ContentType.topic,
                ),
              );
            },
            child: Text(headline.topic.name, style: metadataTextStyle),
          ),
        ],
        // Conditionally render Source as Text
        if (!(currentContextEntityType == ContentType.source &&
            headline.source.id == currentContextEntityId)) ...[
          if (formattedDate.isNotEmpty ||
              (headline.topic.name.isNotEmpty &&
                  !(currentContextEntityType == ContentType.topic &&
                      headline.topic.id == currentContextEntityId)))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('•', style: metadataTextStyle),
            ),
          GestureDetector(
            onTap: () {
              context.push(
                Routes.sourceDetails,
                extra: EntityDetailsPageArguments(
                  entity: headline.source,
                  contentType: ContentType.source,
                ),
              );
            },
            child: Text(headline.source.name, style: metadataTextStyle),
          ),
        ],
      ],
    );
  }
}
