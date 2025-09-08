import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template ad_service}
/// A service responsible for managing and providing ads to the application.
///
/// This service acts as an intermediary between the application's UI/logic
/// and the underlying ad network providers (e.g., AdMob, Local). It handles
/// requesting different types of ads (inline native/banner, full-screen interstitial)
/// and wrapping them in appropriate generic models for use throughout the app.
/// {@endtemplate}
class AdService {
  /// {@macro ad_service}
  ///
  /// Requires a map of [AdProvider]s to be injected, keyed by [AdPlatformType].
  /// These providers will be used to load ads from specific ad networks.
  AdService({
    required Map<AdPlatformType, AdProvider> adProviders,
    Logger? logger,
  }) : _adProviders = adProviders,
       _logger = logger ?? Logger('AdService');

  final Map<AdPlatformType, AdProvider> _adProviders;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  /// Initializes all underlying ad providers.
  ///
  /// This should be called once at application startup to ensure all
  /// integrated ad SDKs are properly initialized.
  Future<void> initialize() async {
    _logger.info('AdService: Initializing AdService...');
    for (final provider in _adProviders.values) {
      await provider.initialize();
    }
    _logger.info('AdService: AdService initialized.');
  }

  /// Retrieves a loaded inline ad (native or banner) for display in a feed.
  ///
  /// This method delegates the ad loading to the appropriate [AdProvider]
  /// based on the [adConfig]'s `primaryAdPlatform` and the requested [adType].
  ///
  /// Returns an [InlineAd] if an inline ad is available, otherwise `null`.
  ///
  /// - [adConfig]: The remote configuration for ad display rules.
  /// - [adType]: The specific type of inline ad to load ([AdType.native] or [AdType.banner]).
  /// - [adThemeStyle]: UI-agnostic theme properties for ad styling.
  /// - [headlineImageStyle]: The user's preference for feed layout,
  ///   which can be used to request an appropriately sized ad.
  Future<InlineAd?> getFeedAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    HeadlineImageStyle? headlineImageStyle,
  }) async {
    _logger.info('AdService: getFeedAd called for adType: $adType');
    return _loadInlineAd(
      adConfig: adConfig,
      adType: adType,
      adThemeStyle: adThemeStyle,
      feedAd: true,
      headlineImageStyle: headlineImageStyle,
    );
  }

  /// Retrieves a loaded full-screen interstitial ad.
  ///
  /// This method delegates the ad loading to the appropriate [AdProvider]
  /// based on the [adConfig]'s `primaryAdPlatform`. It is specifically
  /// designed for interstitial ads that are displayed as full-screen overlays,
  /// typically triggered on route changes.
  ///
  /// Returns an [InterstitialAd] if an interstitial ad is available, otherwise `null`.
  ///
  /// - [adConfig]: The remote configuration for ad display rules.
  /// - [adThemeStyle]: UI-agnostic theme properties for ad styling.
  Future<InterstitialAd?> getInterstitialAd({
    required AdConfig adConfig,
    required AdThemeStyle adThemeStyle,
  }) async {
    _logger.info('AdService: getInterstitialAd called.');
    if (!adConfig.enabled) {
      _logger.info('AdService: Ads are globally disabled in RemoteConfig.');
      return null;
    }

    // Check if interstitial ads are enabled in the remote config.
    if (!adConfig.interstitialAdConfiguration.enabled) {
      _logger.info('AdService: Interstitial ads are disabled in RemoteConfig.');
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning('AdService: No AdProvider found for platform: $primaryAdPlatform');
      return null;
    }

    final platformAdIdentifiers =
        adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'AdService: No AdPlatformIdentifiers found for platform: $primaryAdPlatform',
      );
      return null;
    }

    // Use the correct interstitial ad ID from AdPlatformIdentifiers
    final adId = platformAdIdentifiers.feedToArticleInterstitialAdId;

    if (adId == null || adId.isEmpty) {
      _logger.warning(
        'AdService: No interstitial ad ID configured for platform $primaryAdPlatform',
      );
      return null;
    }

    _logger.info(
      'AdService: Requesting Interstitial ad from $primaryAdPlatform AdProvider with ID: $adId',
    );
    try {
      final loadedAd = await adProvider.loadInterstitialAd(
        adPlatformIdentifiers: platformAdIdentifiers,
        adId: adId,
        adThemeStyle: adThemeStyle,
      );

      if (loadedAd != null) {
        _logger.info('AdService: Interstitial ad successfully loaded.');
        return loadedAd;
      } else {
        _logger.info('AdService: No Interstitial ad loaded by AdProvider.');
        return null;
      }
    } catch (e, s) {
      _logger.severe('AdService: Error getting Interstitial ad from AdProvider: $e', e, s);
      return null;
    }
  }

  /// Retrieves a loaded inline ad (native or banner) for an in-article placement.
  ///
  /// This method delegates ad loading to the appropriate [AdProvider] based on
  /// the [adConfig]'s `primaryAdPlatform` and the `defaultInArticleAdType`
  /// from the `articleAdConfiguration`.
  ///
  /// Returns an [InlineAd] if an ad is available, otherwise `null`.
  ///
  /// - [adConfig]: The remote configuration for ad display rules.
  /// - [adThemeStyle]: UI-agnostic theme properties for ad styling.
  Future<InlineAd?> getInArticleAd({
    required AdConfig adConfig,
    required AdThemeStyle adThemeStyle,
  }) async {
    _logger.info('AdService: getInArticleAd called.');
    return _loadInlineAd(
      adConfig: adConfig,
      adType: AdType.banner, // In-article ads are now always banners
      adThemeStyle: adThemeStyle,
      feedAd: false,
      bannerAdShape: adConfig.articleAdConfiguration.bannerAdShape,
    );
  }

  /// Private helper method to consolidate logic for loading inline ads (native/banner).
  ///
  /// This method handles the common steps of checking ad enablement, selecting
  /// the ad provider, retrieving platform-specific ad identifiers, and calling
  /// the appropriate `loadNativeAd` or `loadBannerAd` method on the provider.
  ///
  /// - [adConfig]: The remote configuration for ad display rules.
  /// - [adType]: The specific type of inline ad to load ([AdType.native] or [AdType.banner]).
  /// - [adThemeStyle]: UI-agnostic theme properties for ad styling.
  /// - [feedAd]: A boolean indicating if this is for a feed ad (true) or in-article ad (false).
  /// - [headlineImageStyle]: The user's preference for feed layout,
  ///   which can be used to request an appropriately sized ad.
  /// - [bannerAdShape]: The preferred shape for banner ads, used for in-article banners.
  ///
  /// Returns an [InlineAd] if an ad is successfully loaded, otherwise `null`.
  Future<InlineAd?> _loadInlineAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    required bool feedAd,
    HeadlineImageStyle? headlineImageStyle,
    BannerAdShape? bannerAdShape,
  }) async {
    _logger.info(
      'AdService: _loadInlineAd called for adType: $adType, feedAd: $feedAd',
    );
    // Check if ads are globally enabled and specifically for the context (feed or article).
    if (!adConfig.enabled) {
      _logger.info('AdService: Ads are globally disabled in RemoteConfig.');
      return null;
    }
    if (feedAd && !adConfig.feedAdConfiguration.enabled) {
      _logger.info('AdService: Feed ads are disabled in RemoteConfig.');
      return null;
    }
    if (!feedAd && !adConfig.articleAdConfiguration.enabled) {
      _logger.info('AdService: In-article ads are disabled in RemoteConfig.');
      return null;
    }

    // Ensure the requested adType is valid for inline ads.
    if (adType != AdType.native && adType != AdType.banner) {
      _logger.warning(
        'AdService: _loadInlineAd called with unsupported AdType: $adType. '
        'Expected AdType.native or AdType.banner.',
      );
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning('AdService: No AdProvider found for platform: $primaryAdPlatform');
      return null;
    }

    final platformAdIdentifiers =
        adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'AdService: No AdPlatformIdentifiers found for platform: $primaryAdPlatform',
      );
      return null;
    }

    final adId = feedAd
        ? (adType == AdType.native
              ? platformAdIdentifiers.feedNativeAdId
              : platformAdIdentifiers.feedBannerAdId)
        : (adType == AdType.native
              ? platformAdIdentifiers.inArticleNativeAdId
              : platformAdIdentifiers.inArticleBannerAdId);

    if (adId == null || adId.isEmpty) {
      _logger.warning(
        'AdService: No ad ID configured for platform $primaryAdPlatform and ad type $adType '
        'for ${feedAd ? 'feed' : 'in-article'} placement.',
      );
      return null;
    }

    _logger.info(
      'AdService: Requesting $adType ad from $primaryAdPlatform AdProvider with ID: $adId '
      'for ${feedAd ? 'feed' : 'in-article'} placement.',
    );
    try {
      InlineAd? loadedAd;
      // For in-article banner ads, bannerAdShape dictates the visual style.
      // For feed ads, headlineImageStyle is still relevant.
      final effectiveHeadlineImageStyle = feedAd ? headlineImageStyle : null;

      switch (adType) {
        case AdType.native:
          loadedAd = await adProvider.loadNativeAd(
            adPlatformIdentifiers: platformAdIdentifiers,
            adId: adId,
            adThemeStyle: adThemeStyle,
            headlineImageStyle: effectiveHeadlineImageStyle,
          );
        case AdType.banner:
          loadedAd = await adProvider.loadBannerAd(
            adPlatformIdentifiers: platformAdIdentifiers,
            adId: adId,
            adThemeStyle: adThemeStyle,
            headlineImageStyle: effectiveHeadlineImageStyle,
          );
        case AdType.interstitial:
        case AdType.video:
          _logger.warning(
            'AdService: Attempted to load $adType ad using _loadInlineAd. This is not supported.',
          );
          return null;
      }

      if (loadedAd != null) {
        _logger.info('AdService: $adType ad successfully loaded.');
        return loadedAd;
      } else {
        _logger.info('AdService: No $adType ad loaded by AdProvider.');
        return null;
      }
    } catch (e, s) {
      _logger.severe('AdService: Error getting $adType ad from AdProvider: $e', e, s);
      return null;
    }
  }
}
