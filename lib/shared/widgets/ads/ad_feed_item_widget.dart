import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template ad_feed_item_widget}
/// A widget responsible for rendering a native ad within the feed.
///
/// This widget takes an [AdFeedItem] and uses the `AdWidget` from the
/// `google_mobile_ads` package to display the underlying [NativeAd].
/// It also handles the disposal of the ad object to prevent memory leaks.
/// {@endtemplate}
class AdFeedItemWidget extends StatefulWidget {
  /// {@macro ad_feed_item_widget}
  const AdFeedItemWidget({required this.adFeedItem, super.key});

  /// The ad feed item containing the loaded native ad to be displayed.
  final AdFeedItem adFeedItem;

  @override
  State<AdFeedItemWidget> createState() => _AdFeedItemWidgetState();
}

class _AdFeedItemWidgetState extends State<AdFeedItemWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _nativeAd = widget.adFeedItem.nativeAd;
    // The ad is typically already loaded by the AdService before being passed here.
    // We can set the state to reflect this.
    if (_nativeAd != null) {
      _isAdLoaded = true;
    }
  }

  @override
  void dispose() {
    // Dispose the native ad when the widget is removed from the tree.
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nativeAd = _nativeAd;
    if (!_isAdLoaded || nativeAd == null) {
      // If the ad is not loaded for any reason, return an empty container.
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
      child: SizedBox(
        height: 120,
        child: AdWidget(ad: nativeAd),
      ),
    );
  }
}
