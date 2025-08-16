import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/admob_native_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/native_ad_view.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/ads/ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';

/// {@template ad_feed_item_widget}
/// A widget responsible for rendering a native ad within the feed,
/// adapting its appearance based on the [HeadlineImageStyle] setting.
///
/// This widget acts as a dispatcher, taking an [AdFeedItem] and delegating
/// the actual rendering to the appropriate provider-specific ad widget
/// (e.g., [AdMobNativeAdWidget]), which is then wrapped by a style-matching
/// ad card.
/// {@endtemplate}
class AdFeedItemWidget extends StatelessWidget {
  /// {@macro ad_feed_item_widget}
  const AdFeedItemWidget({
    required this.adFeedItem,
    required this.headlineImageStyle,
    super.key,
  });

  /// The ad feed item containing the loaded native ad to be displayed.
  final AdFeedItem adFeedItem;

  /// The preferred image style for headlines, used to match the ad's appearance.
  final HeadlineImageStyle headlineImageStyle;

  @override
  Widget build(BuildContext context) {
    // Determine the type of the underlying ad object to instantiate the
    // correct provider-specific NativeAdView.
    final NativeAdView? nativeAdView;
    if (adFeedItem.nativeAd.adObject is admob.NativeAd) {
      nativeAdView = AdMobNativeAdWidget(nativeAd: adFeedItem.nativeAd);
    } else {
      // Log an error for unsupported ad types.
      Logger('AdFeedItemWidget').warning(
        'Unsupported native ad type: ${adFeedItem.nativeAd.adObject.runtimeType}. '
        'Ad will not be displayed.',
      );
      nativeAdView = null;
    }

    if (nativeAdView == null) {
      return const SizedBox.shrink();
    }

    // Select the appropriate ad card widget based on the headline image style.
    switch (headlineImageStyle) {
      case HeadlineImageStyle.hidden:
        return NativeAdCardTextOnly(adView: nativeAdView);
      case HeadlineImageStyle.smallThumbnail:
        return NativeAdCardImageStart(adView: nativeAdView);
      case HeadlineImageStyle.largeThumbnail:
        return NativeAdCardImageTop(adView: nativeAdView);
    }
  }
}
