import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';

/// {@template admob_inline_ad_widget}
/// A stateless widget that renders a pre-loaded inline Google AdMob ad.
///
/// This widget is responsible for taking a generic [InlineAd]
/// and rendering it using the `AdWidget` from the `google_mobile_ads` package.
/// It dynamically determines if the underlying `adObject` is an `admob.NativeAd`
/// or an `admob.BannerAd` and adjusts its rendering and size accordingly.
///
/// **IMPORTANT:** This widget is intentionally stateless. It does **not** manage
/// the lifecycle of the ad object (e.g., loading or disposing). Its sole
/// responsibility is to render a valid, pre-loaded ad. The lifecycle, including
/// caching and disposal, is managed by the [InlineAdCacheService] and the
/// ad loader widgets ([FeedAdLoaderWidget], [InArticleAdLoaderWidget]). This
/// prevents the ad from being destroyed when it scrolls out of view, which is
/// the root cause of the "Ad.load to be called" error.
/// {@endtemplate}
class AdmobInlineAdWidget extends StatelessWidget {
  /// {@macro admob_inline_ad_widget}
  const AdmobInlineAdWidget({
    required this.inlineAd,
    this.feedItemImageStyle,
    super.key,
  });

  /// The generic inline ad model which contains the provider-specific AdMob ad
  /// object. This ad is expected to be fully loaded and valid.
  final InlineAd inlineAd;

  /// The user's preference for feed layout, used to determine the ad's visual
  /// size. This is only relevant for native ads.
  final FeedItemImageStyle? feedItemImageStyle;

  @override
  Widget build(BuildContext context) {
    final logger = Logger('AdmobInlineAdWidget');
    admob.Ad? ad;

    // Safely cast the generic adObject to a specific AdMob ad type.
    if (inlineAd.adObject is admob.NativeAd) {
      ad = inlineAd.adObject as admob.NativeAd;
    } else if (inlineAd.adObject is admob.BannerAd) {
      ad = inlineAd.adObject as admob.BannerAd;
    } else {
      ad = null;
      logger.severe(
        'The provided ad object for AdMob inline ad is not of type '
        'admob.NativeAd or admob.BannerAd. Received: '
        '${inlineAd.adObject.runtimeType}. Ad will not be displayed.',
      );
    }

    if (ad == null) {
      // Return an empty widget if the ad object is not of the correct type
      // or if it was explicitly set to null due to an error.
      return const SizedBox.shrink();
    }

    // Determine the height based on the actual ad type and headlineImageStyle.
    double adHeight;
    if (inlineAd is NativeAd) {
      final nativeAd = inlineAd as NativeAd;
      adHeight = switch (nativeAd.templateType) {
        NativeAdTemplateType.small => 120,
        NativeAdTemplateType.medium => 250,
      };
    } else if (inlineAd is BannerAd) {
      adHeight = feedItemImageStyle == FeedItemImageStyle.largeThumbnail
          ? 250 // Assumes large thumbnail feed style wants a medium rectangle banner
          : 50;
    } else {
      // Fallback height for unknown inline ad types.
      logger.warning(
        'Unknown InlineAd type: ${inlineAd.runtimeType}. '
        'Defaulting to height 100.',
      );
      adHeight = 100;
    }

    // The AdWidget from the google_mobile_ads package handles the rendering
    // of the pre-loaded AdMob ad.
    // We wrap it in a SizedBox to provide explicit height constraints,
    // which is crucial for platform views (like native ads) within
    // scrollable lists to prevent "unbounded height" errors.
    return SizedBox(
      height: adHeight,
      // Use a ValueKey derived from the adObject's hashCode to force Flutter
      // to create a new AdWidget instance if the underlying ad object changes.
      // This prevents the "AdWidget is already in the Widget tree" error.
      child: admob.AdWidget(
        key: ValueKey(ad.hashCode),
        ad: ad as admob.AdWithView,
      ),
    );
  }
}
