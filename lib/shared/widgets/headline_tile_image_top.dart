import 'package:flutter/material.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/utils/utils.dart'; // Import the new utility
import 'package:ht_shared/ht_shared.dart' show Headline;
// timeago import removed from here, handled by utility

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
  });

  /// The headline data to display.
  final Headline headline;

  /// Callback when the main content of the headline (e.g., title area) is tapped.
  final VoidCallback? onHeadlineTap;

  /// An optional widget to display at the end of the tile (e.g., in line with title).
  final Widget? trailing;

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
              child:
                  headline.imageUrl != null
                      ? Image.network(
                        headline.imageUrl!,
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
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 180,
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colorScheme.onSurfaceVariant,
                                size: AppSpacing.xxl,
                              ),
                            ),
                      )
                      : Container(
                        width: double.infinity,
                        height: 180,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: AppSpacing.xxl,
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
                  l10n: l10n,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
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
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
  });

  final Headline headline;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final formattedDate = formatRelativeTime(context, headline.publishedAt);

    final metadataStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final chipLabelStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final chipBackgroundColor = colorScheme.surfaceContainerHighest.withOpacity(
      0.5,
    );
    const iconSize = 12.0; // Kept for date icon

    return Wrap(
      spacing: AppSpacing.sm, // Reduced spacing for more compactness
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (formattedDate.isNotEmpty)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Tapped Date: $formattedDate')),
                );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: iconSize,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(formattedDate, style: metadataStyle),
              ],
            ),
          ),
        if (headline.category?.name != null) ...[
          if (formattedDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs / 2,
              ),
              child: Text('•', style: metadataStyle),
            ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tapped Category: ${headline.category!.name}',
                    ),
                  ),
                );
            },
            child: Chip(
              label: Text(headline.category!.name),
              labelStyle: chipLabelStyle,
              backgroundColor: chipBackgroundColor,
              padding: EdgeInsets.zero, // Changed
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
              ), // Added
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
        if (headline.source?.name != null) ...[
          if (formattedDate.isNotEmpty || headline.category?.name != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs / 2,
              ),
              child: Text('•', style: metadataStyle),
            ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Tapped Source: ${headline.source!.name}'),
                  ),
                );
            },
            child: Chip(
              label: Text(headline.source!.name),
              labelStyle: chipLabelStyle,
              backgroundColor: chipBackgroundColor,
              padding: EdgeInsets.zero, // Changed
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
              ), // Added
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }
}
