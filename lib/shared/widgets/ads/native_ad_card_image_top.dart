import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;
import 'package:ui_kit/ui_kit.dart';

/// {@template native_ad_card_image_top}
/// A generic widget to display a native ad with a large image at the top.
///
/// This widget is designed to visually match [HeadlineTileImageTop]
/// and uses a generic [app_native_ad.NativeAd] model.
/// {@endtemplate}
class NativeAdCardImageTop extends StatelessWidget {
  /// {@macro native_ad_card_image_top}
  const NativeAdCardImageTop({required this.nativeAd, super.key});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.xs),
              topRight: Radius.circular(AppSpacing.xs),
            ),
            child: Container(
              width: double.infinity,
              height: 180, // Standard large image height
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.campaign_outlined,
                color: colorScheme.onSurfaceVariant,
                size: AppSpacing.xxl,
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
                      child: Text(
                        'Ad: ${nativeAd.id}', // Displaying ID for now
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
    );
  }
}
