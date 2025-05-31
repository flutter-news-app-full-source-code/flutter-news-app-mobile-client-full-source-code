import 'package:flutter/material.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/utils/utils.dart'; // Import the new utility
import 'package:ht_shared/ht_shared.dart' show Headline;
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
  });

  /// The headline data to display.
  final Headline headline;

  /// Callback when the main content of the headline (e.g., title area) is tapped.
  final VoidCallback? onHeadlineTap;

  /// An optional widget to display at the end of the tile.
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
                  child:
                      headline.imageUrl != null
                          ? Image.network(
                            headline.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                    size: AppSpacing.xl,
                                  ),
                                ),
                          )
                          : Container(
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
