import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_headlines_client/ht_headlines_client.dart' show Headline;
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/constants.dart'; // Import AppSpacing
import 'package:intl/intl.dart'; // For date formatting

/// A widget that displays a single headline with enhanced styling.
class HeadlineItemWidget extends StatelessWidget {
  /// Creates a [HeadlineItemWidget].
  const HeadlineItemWidget({required this.headline, super.key});

  /// The headline to display.
  final Headline headline;

  // Helper for date formatting
  static final _dateFormatter = DateFormat.yMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final cardTheme = Theme.of(context).cardTheme;
    // Attempt to get radius, default if shape is not RoundedRectangleBorder
    final borderRadius =
        cardTheme.shape is RoundedRectangleBorder
            ? (cardTheme.shape! as RoundedRectangleBorder).borderRadius
            : BorderRadius.circular(
              cardTheme.clipBehavior != Clip.none ? AppSpacing.xs : 0.0,
            );

    // Use InkWell for tap effect on the Card
    return Card(
      // The Card itself provides margin via the parent ListView's separator.
      // Horizontal padding is handled by the parent ListView's padding.
      clipBehavior:
          cardTheme.clipBehavior ?? Clip.antiAlias, // Use theme's clip behavior
      child: InkWell(
        onTap: () {
          context.goNamed(
            Routes.articleDetailsName,
            pathParameters: {'id': headline.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md), // Internal padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image on the left
              if (headline.imageUrl != null)
                ClipRRect(
                  // Use the determined border radius
                  borderRadius: borderRadius.resolve(
                    Directionality.of(context),
                  ),
                  child: Image.network(
                    headline.imageUrl!,
                    width: 80, // Consistent size
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: borderRadius.resolve(
                              Directionality.of(context),
                            ),
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                  ),
                )
              else // Placeholder if no image URL
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: borderRadius.resolve(
                      Directionality.of(context),
                    ),
                  ),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              // Text content on the right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline.title,
                      style: textTheme.titleLarge, // Use titleLarge per theme
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Removed description
                    const SizedBox(
                      height: AppSpacing.sm,
                    ), // Spacing between title and metadata
                    Wrap(
                      spacing: AppSpacing.md, // Horizontal space between items
                      runSpacing: AppSpacing.xs, // Vertical space if wraps
                      children: [
                        if (headline.source != null)
                          _MetadataItem(
                            icon: Icons.source_outlined,
                            text: headline.source!,
                          ),
                        if (headline.publishedAt != null)
                          _MetadataItem(
                            icon: Icons.access_time_outlined,
                            text: _dateFormatter.format(headline.publishedAt!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small helper widget for displaying metadata with an icon.
class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min, // Take only needed space
      children: [
        Icon(
          icon,
          size: 14, // Smaller icon size for metadata
          color: colorScheme.onSurfaceVariant, // Subtle color
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant, // Subtle color
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
