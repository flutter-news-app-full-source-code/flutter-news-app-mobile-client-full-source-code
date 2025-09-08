import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template admob_ad_provider}
/// A concrete implementation of [AdProvider] for Google AdMob.
///
/// This class handles the initialization of the Google Mobile Ads SDK
/// and the loading of native, banner, and interstitial ads specifically for AdMob.
/// It adapts the AdMob-specific ad objects into our generic [NativeAd],
/// [BannerAd], and [InterstitialAd] models.
/// {@endtemplate}
class AdMobAdProvider implements AdProvider {
  /// {@macro admob_ad_provider}
  AdMobAdProvider({Logger? logger})
    : _logger = logger ?? Logger('AdMobAdProvider');

  final Logger _logger;
  final Uuid _uuid = const Uuid();

  static const _adLoadTimeout = 15;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing Google Mobile Ads SDK...');
    try {
      await admob.MobileAds.instance.initialize();
      _logger.info('Google Mobile Ads SDK initialized successfully.');
    } catch (e) {
      _logger.severe('Failed to initialize Google Mobile Ads SDK: $e');
      // Depending on requirements, you might want to rethrow or handle this more gracefully.
      // For now, we log and continue, as ad loading might still work in some cases.
    }
  }

  @override
  Future<NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
    HeadlineImageStyle? headlineImageStyle,
  }) async {
    if (adId == null || adId.isEmpty) {
      _logger.warning('No native ad unit ID provided for AdMob.');
      return null;
    }

    _logger.info('Attempting to load native ad from unit ID: $adId');

    // Determine the template type based on the user's feed style preference.
    final templateType = headlineImageStyle == HeadlineImageStyle.largeThumbnail
        ? NativeAdTemplateType.medium
        : NativeAdTemplateType.small;

    final completer = Completer<admob.NativeAd?>();

    final ad = admob.NativeAd(
      adUnitId: adId,
      request: const admob.AdRequest(),
      nativeTemplateStyle: _createNativeTemplateStyle(
        templateType: switch (templateType) {
          NativeAdTemplateType.small => admob.TemplateType.small,
          NativeAdTemplateType.medium => admob.TemplateType.medium,
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

    return NativeAd(
      id: _uuid.v4(),
      provider: AdPlatformType.admob,
      adObject: googleNativeAd,
      templateType: templateType,
    );
  }

  @override
  Future<BannerAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
    HeadlineImageStyle? headlineImageStyle,
  }) async {
    if (adId == null || adId.isEmpty) {
      _logger.warning('No banner ad unit ID provided for AdMob.');
      return null;
    }

    _logger.info('Attempting to load banner ad from unit ID: $adId');

    // Determine the ad size based on the user's feed style preference.
    final adSize = headlineImageStyle == HeadlineImageStyle.largeThumbnail
        ? admob.AdSize.mediumRectangle
        : admob.AdSize.banner;

    final completer = Completer<admob.BannerAd?>();

    final ad = admob.BannerAd(
      adUnitId: adId,
      size: adSize,
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

    // Wrap the loaded AdMob BannerAd in our generic BannerAd model.
    return BannerAd(
      id: _uuid.v4(),
      provider: AdPlatformType.admob,
      adObject: googleBannerAd,
    );
  }

  @override
  Future<InterstitialAd?> loadInterstitialAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  }) async {
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
    // not rendered as a widget in a feed. We wrap it as a InterstitialAd
    // for consistency in the AdService return type, but its `adObject`
    // will be an `InterstitialAd` which can be shown.
    return InterstitialAd(
      id: _uuid.v4(),
      provider: AdPlatformType.admob,
      adObject: googleInterstitialAd,
    );
  }

  /// Creates a [NativeTemplateStyle] based on the app's current theme.
  ///
  /// This method maps the application's theme properties (colors, text styles)
  /// to the AdMob native ad styling options, ensuring a consistent look and feel.
  /// This is specifically for native ads.
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
