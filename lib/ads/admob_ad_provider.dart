import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template admob_ad_provider}
/// A concrete implementation of [AdProvider] for Google AdMob.
///
/// This class handles the initialization of the Google Mobile Ads SDK
/// and the loading of native ads specifically for AdMob. It adapts the
/// AdMob-specific [admob.NativeAd] object into our generic [app_native_ad.NativeAd]
/// model.
/// {@endtemplate}
class AdMobAdProvider implements AdProvider {
  /// {@macro admob_ad_provider}
  AdMobAdProvider({Logger? logger})
    : _logger = logger ?? Logger('AdMobAdProvider');

  final Logger _logger;
  final Uuid _uuid = const Uuid();

  static const _adLoadTimeout = 15; // Unified timeout for all ad types

  @override
  Future<void> initialize() async {
    _logger.info('Initializing Google Mobile Ads SDK...');
    try {
      await admob.MobileAds.instance.initialize();
      _logger.info('Google Mobile Ads SDK initialized successfully.');
    } catch (e) {
      _logger.severe('Failed to initialize Google Mobile Ads SDK: $e');
      // TODO(fulleni): Depending on requirements, you might want to rethrow or handle this more gracefully.
      // For now, we log and continue, as ad loading might still work in some cases.
    }
  }

  @override
  Future<app_native_ad.NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  }) async {
    if (adType != AdType.native) {
      _logger.warning(
        'AdMobAdProvider.loadNativeAd called with incorrect AdType: $adType. '
        'Expected AdType.native.',
      );
      return null;
    }

    if (adId == null || adId.isEmpty) {
      _logger.warning('No native ad unit ID provided for AdMob.');
      return null;
    }

    _logger.info('Attempting to load native ad from unit ID: $adId');

    final templateType = app_native_ad.NativeAdTemplateType.medium; // Default to medium for native

    final completer = Completer<admob.NativeAd?>();

    final ad = admob.NativeAd(
      adUnitId: adId,
      request: const admob.AdRequest(),
      nativeTemplateStyle: _createNativeTemplateStyle(
        templateType: switch (templateType) {
          app_native_ad.NativeAdTemplateType.small => admob.TemplateType.small,
          app_native_ad.NativeAdTemplateType.medium => admob.TemplateType.medium,
        },
        adThemeStyle: adThemeStyle,
      ),
      listener: admob.NativeAdListener(
        onAdLoaded: (ad) {
          _logger.info('Native Ad loaded successfully.');
          completer.complete(ad as admob.NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          _logger.severe('Native Ad failed to load: $error');
          completer.complete(null);
        },
        onAdClicked: (ad) {
          _logger.info('Native Ad clicked.');
        },
        onAdImpression: (ad) {
          _logger.info('Native Ad impression recorded.');
        },
        onAdClosed: (ad) {
          _logger.info('Native Ad closed.');
        },
        onAdOpened: (ad) {
          _logger.info('Native Ad opened.');
        },
        onAdWillDismissScreen: (ad) {
          _logger.info('Native Ad will dismiss screen.');
        },
      ),
    );

    try {
      await ad.load();
    } catch (e) {
      _logger.severe('Error during native ad load: $e');
      completer.complete(null);
    }

    final googleNativeAd = await completer.future.timeout(
      const Duration(seconds: _adLoadTimeout),
      onTimeout: () {
        _logger.warning('Native ad loading timed out.');
        ad.dispose();
        return null;
      },
    );

    if (googleNativeAd == null) {
      return null;
    }

    return app_native_ad.NativeAd(
      id: _uuid.v4(),
      provider: AdPlatformType.admob,
      adObject: googleNativeAd,
      templateType: templateType,
    );
  }

  @override
  Future<app_native_ad.NativeAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  }) async {
    if (adType != AdType.banner) {
      _logger.warning(
        'AdMobAdProvider.loadBannerAd called with incorrect AdType: $adType. '
        'Expected AdType.banner.',
      );
      return null;
    }

    if (adId == null || adId.isEmpty) {
      _logger.warning('No banner ad unit ID provided for AdMob.');
      return null;
    }

    _logger.info('Attempting to load banner ad from unit ID: $adId');

    final completer = Completer<admob.BannerAd?>();

    final ad = admob.BannerAd(
      adUnitId: adId,
      size: admob.AdSize.banner, // Default banner size
      request: const admob.AdRequest(),
      listener: admob.BannerAdListener(
        onAdLoaded: (ad) {
          _logger.info('Banner Ad loaded successfully.');
          completer.complete(ad as admob.BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          _logger.severe('Banner Ad failed to load: $error');
          ad.dispose();
          completer.complete(null);
        },
        onAdOpened: (ad) {
          _logger.info('Banner Ad opened.');
        },
        onAdClosed: (ad) {
          _logger.info('Banner Ad closed.');
        },
        onAdImpression: (ad) {
          _logger.info('Banner Ad impression recorded.');
        },
      ),
    );

    try {
      await ad.load();
    } catch (e) {
      _logger.severe('Error during banner ad load: $e');
      completer.complete(null);
    }

    final googleBannerAd = await completer.future.timeout(
      const Duration(seconds: _adLoadTimeout),
      onTimeout: () {
        _logger.warning('Banner ad loading timed out.');
        ad.dispose();
        return null;
      },
    );

    if (googleBannerAd == null) {
      return null;
    }

    return app_native_ad.NativeAd(
      id: _uuid.v4(),
      provider: AdPlatformType.admob,
      adObject: googleBannerAd,
      templateType: app_native_ad.NativeAdTemplateType.small, // Banner ads don't have native templates
    );
  }

  @override
  Future<app_native_ad.NativeAd?> loadInterstitialAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  }) async {
    if (adType != AdType.interstitial) {
      _logger.warning(
        'AdMobAdProvider.loadInterstitialAd called with incorrect AdType: '
        '$adType. Expected AdType.interstitial.',
      );
      return null;
    }

    if (adId == null || adId.isEmpty) {
      _logger.warning('No interstitial ad unit ID provided for AdMob.');
      return null;
    }

    _logger.info('Attempting to load interstitial ad from unit ID: $adId');

    final completer = Completer<admob.InterstitialAd?>();

    await admob.InterstitialAd.load(
      adUnitId: adId,
      request: const admob.AdRequest(),
      adLoadCallback: admob.InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _logger.info('Interstitial Ad loaded successfully.');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _logger.severe('Interstitial Ad failed to load: $error');
          completer.complete(null);
        },
      ),
    );

    final googleInterstitialAd = await completer.future.timeout(
      const Duration(seconds: _adLoadTimeout),
      onTimeout: () {
        _logger.warning('Interstitial ad loading timed out.');
        return null;
      },
    );

    if (googleInterstitialAd == null) {
      return null;
    }

    // Interstitial ads are typically shown immediately or on demand,
    // not rendered as a widget in a feed. We wrap it as a NativeAd
    // for consistency in the AdService return type, but its `adObject`
    // will be an `InterstitialAd` which can be shown.
    return app_native_ad.NativeAd(
      id: _uuid.v4(),
      provider: AdPlatformType.admob,
      adObject: googleInterstitialAd,
      templateType: app_native_ad.NativeAdTemplateType.medium, // Arbitrary for interstitial
    );
  }

  /// Creates a [NativeTemplateStyle] based on the app's current theme.
  ///
  /// This method maps the application's theme properties (colors, text styles)
  /// to the AdMob native ad styling options, ensuring a consistent look and feel.
  admob.NativeTemplateStyle _createNativeTemplateStyle({
    required admob.TemplateType templateType,
    required AdThemeStyle adThemeStyle,
  }) {
    return admob.NativeTemplateStyle(
      templateType: templateType,
      mainBackgroundColor: adThemeStyle.mainBackgroundColor,
      cornerRadius: adThemeStyle.cornerRadius,
      callToActionTextStyle: admob.NativeTemplateTextStyle(
        textColor: adThemeStyle.callToActionTextColor,
        backgroundColor: adThemeStyle.callToActionBackgroundColor,
        style: admob.NativeTemplateFontStyle.normal,
        size: adThemeStyle.callToActionTextSize,
      ),
      primaryTextStyle: admob.NativeTemplateTextStyle(
        textColor: adThemeStyle.primaryTextColor,
        backgroundColor: adThemeStyle.primaryBackgroundColor,
        style: admob.NativeTemplateFontStyle.bold,
        size: adThemeStyle.primaryTextSize,
      ),
      secondaryTextStyle: admob.NativeTemplateTextStyle(
        textColor: adThemeStyle.secondaryTextColor,
        backgroundColor: adThemeStyle.secondaryBackgroundColor,
        style: admob.NativeTemplateFontStyle.normal,
        size: adThemeStyle.secondaryTextSize,
      ),
      tertiaryTextStyle: admob.NativeTemplateTextStyle(
        textColor: adThemeStyle.tertiaryTextColor,
        backgroundColor: adThemeStyle.tertiaryBackgroundColor,
        style: admob.NativeTemplateFontStyle.normal,
        size: adThemeStyle.tertiaryTextSize,
      ),
    );
  }
}
