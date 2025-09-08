import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template local_banner_ad_widget}
/// A widget that renders a [LocalBannerAd].
/// {@endtemplate}
class LocalBannerAdWidget extends StatelessWidget {
  /// {@macro local_banner_ad_widget}
  const LocalBannerAdWidget({
    required this.localBannerAd,
    this.headlineImageStyle,
    this.bannerAdShape,
    super.key,
  });

  /// The [LocalBannerAd] to display.
  final LocalBannerAd localBannerAd;

  /// The user's preference for feed layout, used to determine the ad's visual size.
  /// This is only relevant for native ads.
  final HeadlineImageStyle? headlineImageStyle;

  /// The preferred shape for banner ads, used for in-article banners.
  final BannerAdShape? bannerAdShape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine the height based on the bannerAdShape if provided.
    // If bannerAdShape is square, use height for mediumRectangle (250).
    // Otherwise, use height for standard banner (90).
    final imageHeight = switch (bannerAdShape) {
      BannerAdShape.square => 250,
      BannerAdShape.rectangle => 90,
      _ => 90, // Default to standard banner height if shape is null or unknown
    };

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () {
          // TODO(fulleni): Implement navigation to localBannerAd.targetUrl
          // For now, just log the action.
          debugPrint('Local Banner Ad clicked: ${localBannerAd.targetUrl}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (localBannerAd.imageUrl.isNotEmpty)
                Image.network(
                  localBannerAd.imageUrl,
                  fit: BoxFit.cover,
                  height: imageHeight.toDouble(),
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Local Banner Ad',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
