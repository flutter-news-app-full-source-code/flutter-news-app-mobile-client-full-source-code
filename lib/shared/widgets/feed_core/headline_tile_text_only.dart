import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/headline_source_row.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/headline_tap_handler.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/widgets/headline_actions_row.dart';
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
    this.currentContextEntityType,
    this.currentContextEntityId,
  });

  /// The headline data to display.
  final Headline headline;

  /// Callback when the main content of the headline (e.g., title) is tapped.
  final VoidCallback? onHeadlineTap;

  /// The type of the entity currently being viewed in detail (e.g., on a category page).
  final ContentType? currentContextEntityType;

  /// The ID of the entity currently being viewed in detail.
  final String? currentContextEntityId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizationsX(context).l10n;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeadlineSourceRow(headline: headline),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap:
                  onHeadlineTap ??
                  () => HeadlineTapHandler.handleHeadlineTap(context, headline),
              child: Text.rich(
                TextSpan(
                  children: [
                    if (headline.isBreaking)
                      TextSpan(
                        text: '${l10n.breakingNewsPrefix} - ',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    TextSpan(text: headline.title),
                  ],
                ),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
              builder: (context, state) {
                return HeadlineActionsRow(
                  headline: headline,
                  engagements: state.engagementsMap[headline.id] ?? [],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
