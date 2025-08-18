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
/// {@endtemplate}
class AdmobNativeAdWidget extends StatelessWidget {
  /// {@macro admob_native_ad_widget}
  const AdmobNativeAdWidget({required this.nativeAd, super.key});

  /// The generic native ad model which contains the provider-specific ad object.
  final app_ad_models.NativeAd nativeAd;

  @override
  Widget build(BuildContext context) {
    final adObject = nativeAd.adObject;

    // Safely cast the generic ad object to the expected AdMob native ad type.
    if (adObject is! admob.NativeAd) {
      Logger('AdmobNativeAdWidget').severe(
        'The provided ad object is not of type admob.NativeAd. '
        'Received: ${adObject.runtimeType}. Ad will not be displayed.',
      );
      // Return an empty widget if the ad object is not of the correct type
      // to prevent runtime errors.
      return const SizedBox.shrink();
    }

    // The AdWidget from the google_mobile_ads package handles the rendering
    // of the pre-loaded native ad.
    // We wrap it in a SizedBox to provide explicit height constraints,
    // which is crucial for platform views (like native ads) within scrollable
    // lists to prevent "unbounded height" errors.
    final adHeight = switch (nativeAd.templateType) {
      app_ad_models.NativeAdTemplateType.small => 120, // Example height for small template
      app_ad_models.NativeAdTemplateType.medium => 340, // Example height for medium template
    };

    return SizedBox(
      height: adHeight.toDouble(),
      child: admob.AdWidget(ad: adObject),
    );
  }
}
