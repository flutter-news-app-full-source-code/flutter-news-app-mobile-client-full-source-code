import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/admob_native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:ui_kit/ui_kit.dart';

/// {@template ad_feed_item_widget}
/// A widget responsible for rendering a native ad within the feed.
///
/// This widget acts as a dispatcher, taking an [AdFeedItem] and delegating
/// the actual rendering to the appropriate provider-specific ad widget
/// (e.g., [AdMobNativeAdWidget]).
/// {@endtemplate}
class AdFeedItemWidget extends StatelessWidget {
  /// {@macro ad_feed_item_widget}
  const AdFeedItemWidget({required this.adFeedItem, super.key});

  /// The ad feed item containing the loaded native ad to be displayed.
  final AdFeedItem adFeedItem;

  @override
  Widget build(BuildContext context) {
    // Determine the type of the underlying ad object to dispatch to the
    // correct rendering widget.
    // For now, we only support AdMob, but this can be extended.
    if (adFeedItem.nativeAd.adObject is admob.NativeAd) {
      return Card(
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.lg,
        ),
        child: SizedBox(
          height: 120, // Fixed height for the ad card
          child: AdMobNativeAdWidget(nativeAd: adFeedItem.nativeAd),
        ),
      );
    } else {
      // Fallback for unsupported ad types or if adObject is null/unexpected.
      // In a production app, you might log this or show a generic error ad.
      debugPrint(
        'AdFeedItemWidget: Unsupported native ad type: '
        '${adFeedItem.nativeAd.adObject.runtimeType}.',
      );
      return const SizedBox.shrink();
    }
  }
}
