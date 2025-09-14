import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';

/// {@template admob_inline_ad_widget}
/// A widget that specifically renders an inline Google AdMob ad,
/// supporting both native and banner ad formats.
///
/// This widget is responsible for taking a generic [InlineAd]
/// and rendering it using the `AdWidget` from the `google_mobile_ads` package.
/// It dynamically determines if the underlying `adObject` is an `admob.NativeAd`
/// or an `admob.BannerAd` and adjusts its rendering and size accordingly.
///
/// This is a [StatefulWidget] to properly manage the lifecycle of the AdMob
/// ad object, ensuring it is disposed when the widget is removed from the tree
/// or when the underlying ad object changes.
/// {@endtemplate}
class AdmobInlineAdWidget extends StatefulWidget {
  /// {@macro admob_inline_ad_widget}
  const AdmobInlineAdWidget({
    required this.inlineAd,
    this.headlineImageStyle,
    this.bannerAdShape,
    super.key,
  });

  /// The generic inline ad model which contains the provider-specific AdMob ad object.
  final InlineAd inlineAd;

  /// The user's preference for feed layout, used to determine the ad's visual size.
  /// This is only relevant for native ads.
  final HeadlineImageStyle? headlineImageStyle;

  /// The preferred shape for banner ads, used for in-article banners.
  final BannerAdShape? bannerAdShape;

  @override
  State<AdmobInlineAdWidget> createState() => _AdmobInlineAdWidgetState();
}

class _AdmobInlineAdWidgetState extends State<AdmobInlineAdWidget> {
  admob.Ad? _ad;
  final Logger _logger = Logger('AdmobInlineAdWidget');

  @override
  void initState() {
    super.initState();
    _setAd();
  }

  @override
  void didUpdateWidget(covariant AdmobInlineAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the inlineAd object itself has changed (e.g., a new ad was loaded
    // for the same placeholder ID), dispose the old ad and set the new one.
    if (widget.inlineAd.id != oldWidget.inlineAd.id) {
      _disposeCurrentAd(); // Dispose the old ad object
      _setAd();
    }
  }

  @override
  void dispose() {
    // Dispose the AdMob ad object when the widget is removed from the tree.
    // This is crucial to prevent "AdWidget is already in the Widget tree" errors
    // and memory leaks, as each AdWidget instance should manage its own ad object.
    _disposeCurrentAd();
    _logger.info('AdmobInlineAdWidget disposed. Ad object explicitly disposed.');
    super.dispose();
  }

  /// Sets the internal [_ad] object from the widget's [inlineAd].
  ///
  /// This method ensures that the adObject is of the correct AdMob type
  /// (NativeAd or BannerAd) and logs an error if it's not.
  void _setAd() {
    if (widget.inlineAd.adObject is admob.NativeAd) {
      _ad = widget.inlineAd.adObject as admob.NativeAd;
    } else if (widget.inlineAd.adObject is admob.BannerAd) {
      _ad = widget.inlineAd.adObject as admob.BannerAd;
    } else {
      _ad = null;
      _logger.severe(
        'The provided ad object for AdMob inline ad is not of type '
        'admob.NativeAd or admob.BannerAd. Received: '
        '${widget.inlineAd.adObject.runtimeType}. Ad will not be displayed.',
      );
    }
  }

  /// Disposes the currently held [_ad] object if it's an [admob.Ad].
  void _disposeCurrentAd() {
    if (_ad is admob.Ad) {
      _logger.info('Disposing AdMob ad object: ${_ad!.adUnitId}');
      _ad!.dispose();
      _ad = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null) {
      // Return an empty widget if the ad object is not of the correct type
      // or if it was explicitly set to null due to an error.
      return const SizedBox.shrink();
    }

    // Determine the height based on the actual ad type and headlineImageStyle.
    double adHeight;
    if (widget.inlineAd is NativeAd) {
      final nativeAd = widget.inlineAd as NativeAd;
      adHeight = switch (nativeAd.templateType) {
        NativeAdTemplateType.small => 120,
        NativeAdTemplateType.medium => 250,
      };
    } else if (widget.inlineAd is BannerAd) {
      // For banner ads, prioritize bannerAdShape if provided (for in-article ads).
      // Otherwise, fall back to headlineImageStyle (for feed ads).
      if (widget.bannerAdShape != null) {
        adHeight = switch (widget.bannerAdShape) {
          BannerAdShape.square => 250,
          BannerAdShape.rectangle => 50,
          _ => 50,
        };
      } else {
        adHeight =
            widget.headlineImageStyle == HeadlineImageStyle.largeThumbnail
            ? 250 // Assumes large thumbnail feed style wants a medium rectangle banner
            : 50;
      }
    } else {
      // Fallback height for unknown inline ad types.
      adHeight = 100;
    }

    // The AdWidget from the google_mobile_ads package handles the rendering
    // of the pre-loaded AdMob ad.
    // We wrap it in a SizedBox to provide explicit height constraints,
    // which is crucial for platform views (like native ads) within scrollable
    // lists to prevent "unbounded height" errors.
    return SizedBox(
      height: adHeight,
      child: admob.AdWidget(ad: _ad! as admob.AdWithView), // Cast to AdWithView
    );
  }
}
