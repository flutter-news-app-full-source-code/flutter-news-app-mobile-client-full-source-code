import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;

/// {@template admob_native_ad_widget}
/// A widget responsible for rendering a Google AdMob native ad.
///
/// This widget takes our generic [app_native_ad.NativeAd] model, extracts
/// the underlying [admob.NativeAd] object, and uses the AdMob SDK's
/// [admob.AdWidget] to display it. It also handles the lifecycle
/// management of the native ad object.
/// {@endtemplate}
class AdMobNativeAdWidget extends StatefulWidget {
  /// {@macro admob_native_ad_widget}
  const AdMobNativeAdWidget({
    required this.nativeAd,
    super.key,
  });

  /// The generic native ad data containing the AdMob-specific ad object.
  final app_native_ad.NativeAd nativeAd;

  @override
  State<AdMobNativeAdWidget> createState() => _AdMobNativeAdWidgetState();
}

class _AdMobNativeAdWidgetState extends State<AdMobNativeAdWidget> {
  admob.NativeAd? _admobNativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAd();
  }

  @override
  void didUpdateWidget(covariant AdMobNativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the underlying ad object changes, dispose the old one and initialize the new one.
    if (widget.nativeAd.adObject != oldWidget.nativeAd.adObject) {
      _disposeOldAd();
      _initializeAd();
    }
  }

  void _initializeAd() {
    // Ensure the adObject is of the expected AdMob NativeAd type.
    if (widget.nativeAd.adObject is admob.NativeAd) {
      _admobNativeAd = widget.nativeAd.adObject as admob.NativeAd;
      _isAdLoaded = true;
    } else {
      _admobNativeAd = null;
      _isAdLoaded = false;
      // Log an error if the adObject is not the expected type.
      debugPrint(
        'AdMobNativeAdWidget: Expected admob.NativeAd, but received '
        '${widget.nativeAd.adObject.runtimeType}. Ad will not be displayed.',
      );
    }
  }

  void _disposeOldAd() {
    _admobNativeAd?.dispose();
    _admobNativeAd = null;
    _isAdLoaded = false;
  }

  @override
  void dispose() {
    _disposeOldAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _admobNativeAd == null) {
      // If the ad is not loaded or is of the wrong type, return an empty container.
      return const SizedBox.shrink();
    }

    // Use the AdMob SDK's AdWidget to render the native ad.
    return admob.AdWidget(ad: _admobNativeAd!);
  }
}
