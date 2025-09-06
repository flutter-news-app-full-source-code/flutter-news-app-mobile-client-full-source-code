import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart'; // Import BannerAd
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart'; // Import InlineAd
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/models.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/admob_inline_ad_widget.dart'; // Use the renamed widget
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_banner_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_native_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/placeholder_ad_widget.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template ad_feed_item_widget}
/// A widget that acts as a dispatcher for rendering inline ads from different
/// providers.
///
/// This widget inspects the [AdFeedItem]'s underlying [InlineAd] to determine
/// its [AdPlatformType] and its specific type (Native or Banner). It then
/// delegates the rendering to the appropriate provider-specific widget
/// (e.g., [AdmobInlineAdWidget], [LocalNativeAdWidget], [LocalBannerAdWidget]).
///
/// This approach ensures that the ad rendering logic is decoupled from the
/// main feed UI, making the system extensible to support multiple ad networks
/// and ad types.
/// {@endtemplate}
class AdFeedItemWidget extends StatelessWidget {
  /// {@macro ad_feed_item_widget}
  const AdFeedItemWidget({required this.adFeedItem, super.key});

  /// The ad feed item containing the loaded inline ad to be displayed.
  final AdFeedItem adFeedItem;

  @override
  Widget build(BuildContext context) {
    // The main container for the ad, styled to look like other feed items.
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320, // Minimum recommended width for ads
          minHeight: 50, // Minimum height for a small banner ad
        ),
        // The _AdDispatcher is responsible for selecting the correct
        // provider-specific widget.
        // Use a ValueKey to ensure that when the adFeedItem changes (e.g., a new
        // ad is loaded for the same slot), the _AdDispatcher and its child
        // are rebuilt, triggering the new ad's lifecycle.
        child: _AdDispatcher(
          key: ValueKey(adFeedItem.id), // Use adFeedItem.id as the key
          inlineAd: adFeedItem.inlineAd, // Pass the inlineAd
        ),
      ),
    );
  }
}

/// A private helper widget that selects the correct ad rendering widget
/// based on the [InlineAd.provider] and its runtime type.
class _AdDispatcher extends StatelessWidget {
  const _AdDispatcher({required this.inlineAd, super.key});

  final InlineAd inlineAd;

  @override
  Widget build(BuildContext context) {
    // Use a switch statement on the provider to determine which widget to build.
    // This is the core of the platform-agnostic rendering logic.
    switch (inlineAd.provider) {
      case AdPlatformType.admob:
        // If the provider is AdMob, render the AdmobInlineAdWidget.
        // This widget handles both NativeAd and BannerAd from AdMob.
        return AdmobInlineAdWidget(inlineAd: inlineAd);
      case AdPlatformType.local:
        // If the provider is local, dispatch based on the actual LocalAd type.
        // The adObject within our InlineAd models (NativeAd, BannerAd)
        // will be the corresponding LocalAd type (LocalNativeAd, LocalBannerAd).
        if (inlineAd is NativeAd && inlineAd.adObject is LocalNativeAd) {
          return LocalNativeAdWidget(localNativeAd: inlineAd.adObject as LocalNativeAd);
        } else if (inlineAd is BannerAd && inlineAd.adObject is LocalBannerAd) {
          return LocalBannerAdWidget(localBannerAd: inlineAd.adObject as LocalBannerAd);
        }
        // Fallback for unsupported local ad types or errors
        return const PlaceholderAdWidget();
      }
  }
}
