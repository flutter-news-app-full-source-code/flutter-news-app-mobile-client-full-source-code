import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/headline_metadata_row.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/headline_tap_handler.dart';
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
            onTap:
                onHeadlineTap ??
                () => HeadlineTapHandler.handleHeadlineTap(context, headline),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.xs),
                topRight: Radius.circular(AppSpacing.xs),
              ),
              child: Image.network(
                headline.imageUrl,
                width: double.infinity,
                height: 180,
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
                        onTap:
                            onHeadlineTap ??
                            () => HeadlineTapHandler.handleHeadlineTap(
                              context,
                              headline,
                            ),
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
                HeadlineMetadataRow(
                  headline: headline,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  currentContextEntityType: currentContextEntityType,
                  currentContextEntityId: currentContextEntityId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
