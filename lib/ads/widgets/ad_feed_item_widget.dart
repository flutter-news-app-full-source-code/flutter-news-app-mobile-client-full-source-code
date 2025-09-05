import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/models.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_banner_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_native_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/placeholder_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/widgets.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template ad_feed_item_widget}
/// A widget that acts as a dispatcher for rendering native ads from different
/// providers.
///
/// This widget inspects the [AdFeedItem]'s underlying [NativeAd] to determine
/// its [AdPlatformType]. It then delegates the rendering to the appropriate
/// provider-specific widget (e.g., [AdmobNativeAdWidget]).
///
/// This approach ensures that the ad rendering logic is decoupled from the
/// main feed UI, making the system extensible to support multiple ad networks.
/// {@endtemplate}
class AdFeedItemWidget extends StatelessWidget {
  /// {@macro ad_feed_item_widget}
  const AdFeedItemWidget({required this.adFeedItem, super.key});

  /// The ad feed item containing the loaded native ad to be displayed.
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
          minHeight: 90, // Minimum height for a small template ad
        ),
        // The _AdDispatcher is responsible for selecting the correct
        // provider-specific widget.
        // Use a ValueKey to ensure that when the adFeedItem changes (e.g., a new
        // ad is loaded for the same slot), the _AdDispatcher and its child
        // (AdmobNativeAdWidget) are rebuilt, triggering the new ad's lifecycle.
        child: _AdDispatcher(
          key: ValueKey(adFeedItem.id), // Use adFeedItem.id as the key
          nativeAd: adFeedItem.nativeAd,
        ),
      ),
    );
  }
}

/// A private helper widget that selects the correct ad rendering widget
/// based on the [NativeAd.provider].
class _AdDispatcher extends StatelessWidget {
  const _AdDispatcher({required this.nativeAd, super.key}); // Add super.key

  final NativeAd nativeAd;

  @override
  Widget build(BuildContext context) {
    // Use a switch statement on the provider to determine which widget to build.
    // This is the core of the platform-agnostic rendering logic.
    switch (nativeAd.provider) {
      case AdPlatformType.admob:
        // If the provider is AdMob, render the AdmobNativeAdWidget.
        // Pass the nativeAd object directly. The AdmobNativeAdWidget is now
        // stateful and will manage its own lifecycle.
        return AdmobNativeAdWidget(nativeAd: nativeAd);
      case AdPlatformType.local:
        // If the provider is local, dispatch based on the actual LocalAd type.
        final localAd = nativeAd.adObject;
        if (localAd is LocalNativeAd) {
          return LocalNativeAdWidget(localNativeAd: localAd);
        } else if (localAd is LocalBannerAd) {
          return LocalBannerAdWidget(localBannerAd: localAd);
        }
        // Fallback for unsupported local ad types or errors
        return const PlaceholderAdWidget();
      default:
        // Fallback for unsupported ad platforms or types.
        return const PlaceholderAdWidget();
    }
  }
}
