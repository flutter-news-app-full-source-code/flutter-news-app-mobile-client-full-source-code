import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/models.dart'
    as app_ad_models;
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';

/// {@template admob_native_ad_widget}
/// A widget that specifically renders a Google AdMob native ad.
///
/// This widget is responsible for taking the generic [app_ad_models.NativeAd]
/// and rendering it using the `AdWidget` from the `google_mobile_ads` package.
/// It expects the `adObject` within the [app_ad_models.NativeAd] to be a fully
/// loaded [admob.NativeAd] instance.
///
/// This is a [StatefulWidget] to properly manage the lifecycle of the native
/// ad object, ensuring it is disposed when the widget is removed from the tree
/// or when the underlying ad object changes.

/// {@endtemplate}
class AdmobNativeAdWidget extends StatefulWidget {
  /// {@macro admob_native_ad_widget}
  const AdmobNativeAdWidget({required this.nativeAd, super.key});

  /// The generic native ad model which contains the provider-specific ad object.
  final app_ad_models.NativeAd nativeAd;

  @override
  State<AdmobNativeAdWidget> createState() => _AdmobNativeAdWidgetState();
}

class _AdmobNativeAdWidgetState extends State<AdmobNativeAdWidget> {
  admob.NativeAd? _ad;
  final Logger _logger = Logger('AdmobNativeAdWidget');

  @override
  void initState() {
    super.initState();
    _setAd();
  }

  @override
  void didUpdateWidget(covariant AdmobNativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the nativeAd object itself has changed (e.g., a new ad was loaded
    // for the same placeholder ID), dispose the old ad and set the new one.
    if (widget.nativeAd.id != oldWidget.nativeAd.id) {
      _ad?.dispose();
      _setAd();
    }
  }

  @override
  void dispose() {
    // Dispose the native ad when the widget is removed from the tree.
    // This is crucial for releasing native resources and preventing crashes.
    _ad?.dispose();
    _logger.info('AdmobNativeAdWidget disposed and native ad released.');
    super.dispose();
  }

  /// Sets the internal [_ad] object from the widget's [nativeAd].
  ///
  /// This method ensures that the adObject is of the correct type and
  /// logs an error if it's not.
  void _setAd() {
    if (widget.nativeAd.adObject is admob.NativeAd) {
      _ad = widget.nativeAd.adObject as admob.NativeAd;
    } else {
      _ad = null; // Ensure _ad is null if the type is incorrect

      _logger.severe(
        'The provided ad object is not of type admob.NativeAd. '
        'Received: ${widget.nativeAd.adObject.runtimeType}. Ad will not be displayed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null) {
      // Return an empty widget if the ad object is not of the correct type
      // or if it was explicitly set to null due to an error.
      return const SizedBox.shrink();
    }

    // The AdWidget from the google_mobile_ads package handles the rendering
    // of the pre-loaded native ad.
    // We wrap it in a SizedBox to provide explicit height constraints,
    // which is crucial for platform views (like native ads) within scrollable
    // lists to prevent "unbounded height" errors.
    
    final adHeight = switch (widget.nativeAd.templateType) {
      app_ad_models.NativeAdTemplateType.small => 120,
      app_ad_models.NativeAdTemplateType.medium => 340,
    };

    return SizedBox(
      height: adHeight.toDouble(),
      child: admob.AdWidget(ad: _ad!),
    );
  }
}
