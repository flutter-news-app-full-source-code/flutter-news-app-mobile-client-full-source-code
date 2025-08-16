import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_tile_image_top}
/// A shared widget to display a headline item with a large image at the top.
/// {@endtemplate}
class HeadlineTileImageTop extends StatelessWidget {
  /// {@macro headline_tile_image_top}
  const HeadlineTileImageTop({
    required this.headline,
    super.key,
    this.onHeadlineTap,
    this.trailing,
    this.currentContextEntityType,
    this.currentContextEntityId,
  });

  /// The headline data to display.
  final Headline headline;

  /// Callback when the main content of the headline (e.g., title area) is tapped.
  final VoidCallback? onHeadlineTap;

  /// An optional widget to display at the end of the tile (e.g., in line with title).
  final Widget? trailing;

  /// The type of the entity currently being viewed in detail (e.g., on a category page).
  final ContentType? currentContextEntityType;

  /// The ID of the entity currently being viewed in detail.
  final String? currentContextEntityId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onHeadlineTap, // Image area is part of the main tap area
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.xs),
                topRight: Radius.circular(AppSpacing.xs),
              ),
              child: Image.network(
                headline.imageUrl,
                width: double.infinity,
                height: 180, // Standard large image height
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 180,
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: AppSpacing.xxl,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onHeadlineTap, // Title is part of main tap area
                        child: Text(
                          headline.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _HeadlineMetadataRow(
                  headline: headline,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  currentContextEntityType:
                      currentContextEntityType, // Pass down
                  currentContextEntityId: currentContextEntityId, // Pass down
                ),
              ],
            ),
          ),
        ],
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
