import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template ad_feed_item_widget}
/// A widget responsible for rendering a native ad within the feed using
/// the `AdWidget` from the `google_mobile_ads` package.
///
/// This widget takes an [AdFeedItem] and renders the underlying native ad
/// object, which is expected to be a pre-styled template ad.
/// {@endtemplate}
class AdFeedItemWidget extends StatelessWidget {
  /// {@macro ad_feed_item_widget}
  const AdFeedItemWidget({
    required this.adFeedItem,
    super.key,
  });

  /// The ad feed item containing the loaded native ad to be displayed.
  final AdFeedItem adFeedItem;

  @override
  Widget build(BuildContext context) {
    final nativeAd = adFeedItem.nativeAd.adObject;

    // Check if the ad object is of the expected type.
    if (nativeAd is! admob.NativeAd) {
      Logger('AdFeedItemWidget').warning(
        'Unsupported native ad type: ${nativeAd.runtimeType}. '
        'Ad will not be displayed.',
      );
      return const SizedBox.shrink();
    }

    // The AdWidget will render the pre-defined template (small or medium)
    // that was selected when the ad was loaded.
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320, // Minimum recommended width
          minHeight: 90, // Minimum height for small template
        ),
        child: admob.AdWidget(ad: nativeAd),
      ),
    );
  }
}
