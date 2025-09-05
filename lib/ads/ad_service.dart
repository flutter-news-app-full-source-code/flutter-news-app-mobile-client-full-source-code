import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template ad_service}
/// A service responsible for managing and providing ads to the application.
///
/// This service acts as an intermediary between the application's UI/logic
/// and the underlying ad network providers (e.g., AdMob). It handles
/// requesting ads and wrapping them in a generic [AdFeedItem] for use
/// in the feed.
/// {@endtemplate}
class AdService {
  /// {@macro ad_service}
  ///
  /// Requires an [AdProvider] to be injected, which will be used to
  /// load ads from a specific ad network.
  AdService({
    required Map<AdPlatformType, AdProvider> adProviders,
    Logger? logger,
  })  : _adProviders = adProviders,
        _logger = logger ?? Logger('AdService');

  final Map<AdPlatformType, AdProvider> _adProviders;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  /// Initializes the underlying ad provider.
  ///
  /// This should be called once at application startup.
  Future<void> initialize() async {
    _logger.info('Initializing AdService...');
    for (final provider in _adProviders.values) {
      await provider.initialize();
    }
    _logger.info('AdService initialized.');
  }

  /// Retrieves a loaded native ad wrapped as an [AdFeedItem].
  ///
  /// This method delegates the ad loading to the injected [AdProvider],
  /// passing along the desired [imageStyle] to select the correct template.
  /// If an ad is successfully loaded, it's wrapped in an [AdFeedItem]
  /// with a unique ID.
  ///
  /// Returns an [AdFeedItem] if an ad is available, otherwise `null`.
  Future<AdFeedItem?> getAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  }) async {
    if (!adConfig.enabled) {
      _logger.info('Ads are globally disabled in RemoteConfig.');
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning('No AdProvider found for platform: $primaryAdPlatform');
      return null;
    }

    final platformAdIdentifiers = adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'No AdPlatformIdentifiers found for platform: $primaryAdPlatform',
      );
      return null;
    }

    final String? adId = switch (adType) {
      AdType.native => platformAdIdentifiers.feedNativeAdId,
      AdType.banner => platformAdIdentifiers.feedBannerAdId,
      AdType.interstitial => platformAdIdentifiers.feedToArticleInterstitialAdId,
      AdType.video => null, // Video ad type not yet supported
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
      app_native_ad.NativeAd? loadedAd;
      switch (adType) {
        case AdType.native:
          loadedAd = await adProvider.loadNativeAd(
            adPlatformIdentifiers: platformAdIdentifiers,
            adId: adId,
            adType: adType,
            adThemeStyle: adThemeStyle,
          );
        case AdType.banner:
          loadedAd = await adProvider.loadBannerAd(
            adPlatformIdentifiers: platformAdIdentifiers,
            adId: adId,
            adType: adType,
            adThemeStyle: adThemeStyle,
          );
        case AdType.interstitial:
          loadedAd = await adProvider.loadInterstitialAd(
            adPlatformIdentifiers: platformAdIdentifiers,
            adId: adId,
            adType: adType,
            adThemeStyle: adThemeStyle,
          );
        case AdType.video:
          _logger.warning('Video ad type not yet supported.');
          return null;
      }

      if (loadedAd != null) {
        _logger.info('$adType ad successfully loaded and wrapped.');
        return AdFeedItem(id: _uuid.v4(), nativeAd: loadedAd);
      } else {
        _logger.info('No $adType ad loaded by AdProvider.');
        return null;
      }
    } catch (e) {
      _logger.severe('Error getting $adType ad from AdProvider: $e');
      return null;
    }
  }
}
