import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;
import 'package:ui_kit/ui_kit.dart';

/// {@template native_ad_card_image_start}
/// A generic widget to display a native ad with a small image at the start.
///
/// This widget is designed to visually match [HeadlineTileImageStart]
/// and uses a generic [app_native_ad.NativeAd] model.
/// {@endtemplate}
class NativeAdCardImageStart extends StatelessWidget {
  /// {@macro native_ad_card_image_start}
  const NativeAdCardImageStart({required this.nativeAd, super.key});

  /// The generic native ad data to display.
  final app_native_ad.NativeAd nativeAd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Placeholder content for the generic ad.
    // The actual rendering of the SDK-specific ad will happen in a child widget.
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
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
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.campaign_outlined,
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
                    'Ad: ${nativeAd.id}', // Displaying ID for now
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This is a generic ad placeholder.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
