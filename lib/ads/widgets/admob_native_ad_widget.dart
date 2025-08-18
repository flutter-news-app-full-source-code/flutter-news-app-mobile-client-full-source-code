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
/// ad object, ensuring it is disposed when the widget is removed from the tree.
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
    // Ensure the adObject is of the correct type and assign it.
    if (widget.nativeAd.adObject is admob.NativeAd) {
      _ad = widget.nativeAd.adObject as admob.NativeAd;
    } else {
      _logger.severe(
        'The provided ad object is not of type admob.NativeAd. '
        'Received: ${widget.nativeAd.adObject.runtimeType}. Ad will not be displayed.',
      );
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

  @override
  Widget build(BuildContext context) {
    if (_ad == null) {
      return const SizedBox.shrink();
    }

    // Determine the height based on the native ad template type.
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
