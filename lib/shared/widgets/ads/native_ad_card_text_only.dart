import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;
import 'package:ui_kit/ui_kit.dart';

/// {@template native_ad_card_text_only}
/// A generic widget to display a native ad with text only.
///
/// This widget is designed to visually match [HeadlineTileTextOnly]
/// and uses a generic [app_native_ad.NativeAd] model.
/// {@endtemplate}
class NativeAdCardTextOnly extends StatelessWidget {
  /// {@macro native_ad_card_text_only}
  const NativeAdCardTextOnly({required this.nativeAd, super.key});

  /// The generic native ad data to display.
  final app_native_ad.NativeAd nativeAd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ad: ${nativeAd.id}', // Displaying ID for now
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3, // Allow more lines for text-only
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This is a generic ad placeholder.',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.7),
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
