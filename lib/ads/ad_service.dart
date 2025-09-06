import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
// Import BannerAd
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart'; // Import InlineAd
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
// Import NativeAd
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
  })  : _adProviders = adProviders,
        _logger = logger ?? Logger('AdService');

  final Map<AdPlatformType, AdProvider> _adProviders;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  /// Initializes all underlying ad providers.
  ///
  /// This should be called once at application startup to ensure all
  /// integrated ad SDKs are properly initialized.
  Future<void> initialize() async {
    _logger.info('Initializing AdService...');
    for (final provider in _adProviders.values) {
      await provider.initialize();
    }
    _logger.info('AdService initialized.');
  }

  /// Retrieves a loaded inline ad (native or banner) wrapped as an [AdFeedItem].
  ///
  /// This method delegates the ad loading to the appropriate [AdProvider]
  /// based on the [adConfig]'s `primaryAdPlatform` and the requested [adType].
  /// If an ad is successfully loaded, it's wrapped in an [AdFeedItem]
  /// with a unique ID for display in content feeds.
  ///
  /// Returns an [AdFeedItem] if an inline ad is available, otherwise `null`.
  ///
  /// - [adConfig]: The remote configuration for ad display rules.
  /// - [adType]: The specific type of inline ad to load ([AdType.native] or [AdType.banner]).
  /// - [adThemeStyle]: UI-agnostic theme properties for ad styling.
  Future<AdFeedItem?> getInlineAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  }) async {
    if (!adConfig.enabled) {
      _logger.info('Ads are globally disabled in RemoteConfig.');
      return null;
    }

    // Ensure the requested adType is valid for inline ads.
    if (adType != AdType.native && adType != AdType.banner) {
      _logger.warning(
        'getInlineAd called with unsupported AdType: $adType. '
        'Expected AdType.native or AdType.banner.',
      );
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning('No AdProvider found for platform: $primaryAdPlatform');
      return null;
    }

    final platformAdIdentifiers =
        adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'No AdPlatformIdentifiers found for platform: $primaryAdPlatform',
      );
      return null;
    }

    final adId = switch (adType) {
      AdType.native => platformAdIdentifiers.feedNativeAdId,
      AdType.banner => platformAdIdentifiers.feedBannerAdId,
      _ => null, // Handled by the initial adType check
    };

    if (adId == null || adId.isEmpty) {
      _logger.warning(
        'No ad ID configured for platform $primaryAdPlatform and ad type $adType',
      );
      return null;
    }

    _logger.info(
      'Requesting $adType ad from $primaryAdPlatform AdProvider with ID: $adId',
    );
    try {
      InlineAd? loadedAd; // Use the new InlineAd abstract type
      switch (adType) {
        case AdType.native:
          loadedAd = await adProvider.loadNativeAd(
            adPlatformIdentifiers: platformAdIdentifiers,
            adId: adId,
            adThemeStyle: adThemeStyle,
          );
        case AdType.banner:
          loadedAd = await adProvider.loadBannerAd(
            adPlatformIdentifiers: platformAdIdentifiers,
            adId: adId,
            adThemeStyle: adThemeStyle,
          );
        case AdType.interstitial:
        case AdType.video:
          // These types are not handled by getInlineAd.
          _logger.warning(
            'Attempted to load $adType ad using getInlineAd. This is not supported.',
          );
          return null;
      }

      if (loadedAd != null) {
        _logger.info('$adType ad successfully loaded and wrapped.');
        return AdFeedItem(id: _uuid.v4(), inlineAd: loadedAd); // Use inlineAd
      } else {
        _logger.info('No $adType ad loaded by AdProvider.');
        return null;
      }
    } catch (e) {
      _logger.severe('Error getting $adType ad from AdProvider: $e');
      return null;
    }
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
    if (!adConfig.enabled) {
      _logger.info('Ads are globally disabled in RemoteConfig.');
      return null;
    }

    // Check if interstitial ads are enabled in the remote config.
    if (!adConfig.interstitialAdConfiguration.enabled) {
      _logger.info('Interstitial ads are disabled in RemoteConfig.');
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning('No AdProvider found for platform: $primaryAdPlatform');
      return null;
    }

    final platformAdIdentifiers =
        adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'No AdPlatformIdentifiers found for platform: $primaryAdPlatform',
      );
      return null;
    }

    // Use the correct interstitial ad ID from AdPlatformIdentifiers
    final adId = platformAdIdentifiers.feedToArticleInterstitialAdId;

    if (adId == null || adId.isEmpty) {
      _logger.warning(
        'No interstitial ad ID configured for platform $primaryAdPlatform',
      );
      return null;
    }

    _logger.info(
      'Requesting Interstitial ad from $primaryAdPlatform AdProvider with ID: $adId',
    );
    try {
      final loadedAd = await adProvider.loadInterstitialAd(
        adPlatformIdentifiers: platformAdIdentifiers,
        adId: adId,
        adThemeStyle: adThemeStyle,
      );

      if (loadedAd != null) {
        _logger.info('Interstitial ad successfully loaded.');
        return loadedAd;
      } else {
        _logger.info('No Interstitial ad loaded by AdProvider.');
        return null;
      }
    } catch (e) {
      _logger.severe('Error getting Interstitial ad from AdProvider: $e');
      return null;
    }
  }
}
