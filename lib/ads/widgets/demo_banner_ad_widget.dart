import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template demo_banner_ad_widget}
/// A widget that displays a placeholder for a banner ad in demo mode.
///
/// This widget mimics the visual dimensions of a real banner ad but
/// contains only static text to indicate it's a demo.
/// {@endtemplate}
class DemoBannerAdWidget extends StatelessWidget {
  /// {@macro demo_banner_ad_widget}
  const DemoBannerAdWidget({
    this.headlineImageStyle,
    this.bannerAdShape,
    super.key,
  });

  /// The user's preference for feed layout, used to determine the ad's visual size.
  final HeadlineImageStyle? headlineImageStyle;

  /// The preferred shape for banner ads, used for in-article banners.
  final BannerAdShape? bannerAdShape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine the height based on the bannerAdShape if provided.
    // If bannerAdShape is square, use height for mediumRectangle (250).
    // Otherwise, use height for standard banner (50).
    final adHeight = switch (bannerAdShape) {
      BannerAdShape.square => 250,
      BannerAdShape.rectangle => 50,
      _ => 50, // Default to standard banner height if shape is null or unknown
    };

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: SizedBox(
        height: adHeight.toDouble(),
        width: double.infinity,
        child: Center(
          child: Text(
            AppLocalizations.of(context).demoBannerAdText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
