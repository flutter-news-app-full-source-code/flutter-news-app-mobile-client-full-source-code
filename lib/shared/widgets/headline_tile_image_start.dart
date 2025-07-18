import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Added
import 'package:ht_main/entity_details/models/entity_type.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart'; // Added for Page Arguments
import 'package:ht_main/l10n/app_localizations.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart'; // Added
import 'package:ht_shared/ht_shared.dart' show Headline;
import 'package:ht_ui_kit/ht_ui_kit.dart';
// timeago import removed from here, handled by utility

/// {@template headline_tile_image_start}
/// A shared widget to display a headline item with a small image at the start.
/// {@endtemplate}
class HeadlineTileImageStart extends StatelessWidget {
  /// {@macro headline_tile_image_start}
  const HeadlineTileImageStart({
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

  /// An optional widget to display at the end of the tile.
  final Widget? trailing;

  /// The type of the entity currently being viewed in detail (e.g., on a category page).
  final EntityType? currentContextEntityType;

  /// The ID of the entity currently being viewed in detail.
  final String? currentContextEntityId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onHeadlineTap, // Main tap for image + title area
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72, // Standard small image size
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: headline.imageUrl != null
                      ? Image.network(
                          headline.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return ColoredBox(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: AppSpacing.xl,
                                ),
                              ),
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: AppSpacing.xl,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md), // Always add spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _HeadlineMetadataRow(
                      headline: headline,
                      l10n: l10n,
                      colorScheme: colorScheme,
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
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
    this.currentContextEntityType,
    this.currentContextEntityId,
  });

  final Headline headline;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final EntityType? currentContextEntityType;
  final String? currentContextEntityId;

  @override
  Widget build(BuildContext context) {
    final formattedDate = formatRelativeTime(context, headline.publishedAt);

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
        // Conditionally render Category as Text
        if (headline.category?.name != null &&
            !(currentContextEntityType == EntityType.category &&
                headline.category!.id == currentContextEntityId)) ...[
          if (formattedDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('•', style: metadataTextStyle),
            ),
          GestureDetector(
            onTap: () {
              if (headline.category != null) {
                context.push(
                  Routes.categoryDetails,
                  extra: EntityDetailsPageArguments(entity: headline.category),
                );
              }
            },
            child: Text(headline.category!.name, style: metadataTextStyle),
          ),
        ],
        // Conditionally render Source as Text
        if (!(currentContextEntityType == EntityType.source &&
            headline.source.id == currentContextEntityId)) ...[
          if (formattedDate.isNotEmpty ||
              (headline.category?.name != null &&
                  !(currentContextEntityType == EntityType.category &&
                      headline.category!.id == currentContextEntityId)))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('•', style: metadataTextStyle),
            ),
          GestureDetector(
            onTap: () {
              context.push(
                Routes.sourceDetails,
                extra: EntityDetailsPageArguments(entity: headline.source),
              );
            },
            child: Text(headline.source.name, style: metadataTextStyle),
          ),
        ],
      ],
    );
  }
}
