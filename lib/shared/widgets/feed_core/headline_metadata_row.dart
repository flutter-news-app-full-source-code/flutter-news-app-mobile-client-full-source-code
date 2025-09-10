import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_metadata_row}
/// A shared widget to display the metadata row for a headline, including
/// publish date, topic, and source.
/// {@endtemplate}
class HeadlineMetadataRow extends StatelessWidget {
  /// {@macro headline_metadata_row}
  const HeadlineMetadataRow({
    required this.headline,
    required this.colorScheme,
    required this.textTheme,
    super.key,
    this.currentContextEntityType,
    this.currentContextEntityId,
  });

  /// The headline data to display.
  final Headline headline;

  /// The color scheme from the current theme.
  final ColorScheme colorScheme;

  /// The text theme from the current theme.
  final TextTheme textTheme;

  /// The type of the entity currently being viewed in detail (e.g., on a
  /// category page).
  final ContentType? currentContextEntityType;

  /// The ID of the entity currently being viewed in detail.
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
    const iconSize = AppSpacing.sm;

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
              context.pushNamed(
                Routes.entityDetailsName,
                pathParameters: {
                  'type': ContentType.topic.name,
                  'id': headline.topic.id,
                },
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
              context.pushNamed(
                Routes.entityDetailsName,
                pathParameters: {
                  'type': ContentType.source.name,
                  'id': headline.source.id,
                },
              );
            },
            child: Text(headline.source.name, style: metadataTextStyle),
          ),
        ],
      ],
    );
  }
}
