import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template ad_engine}
/// The concrete implementation of [AdService] that acts as the orchestration
/// layer for the ad system.
///
/// This engine manages the lifecycle of ads, enforces configuration rules
/// (e.g., global enablement, user tier visibility), handles retry logic,
/// and delegates the actual ad loading to the appropriate [AdProvider].
///
/// {@endtemplate}
class AdEngine implements AdService {
  /// {@macro ad_engine}
  AdEngine({
    required AdConfig? initialConfig,
    required Map<AdPlatformType, AdProvider> adProviders,
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : _config = initialConfig,
       _adProviders = adProviders,
       _analyticsService = analyticsService,
       _logger = logger ?? Logger('AdEngine');

  final AdConfig? _config;
  final Map<AdPlatformType, AdProvider> _adProviders;
  final AnalyticsService _analyticsService;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  // Configurable retry parameters for ad loading.
  static const int _maxAdLoadRetries = 2;
  static const Duration _adLoadRetryDelay = Duration(seconds: 1);

  @override
  Future<void> initialize() async {
    _logger.info('AdEngine: Initializing...');
    if (_config == null || !_config!.enabled) {
      _logger.info('AdEngine: Ads disabled. Skipping provider init.');
      return;
    }

    for (final provider in _adProviders.values) {
      await provider.initialize();
    }
    _logger.info('AdEngine: Initialized.');
  }

  @override
  Future<void> disposeAd(dynamic adModel) async {
    // Determine the AdPlatformType from the adModel if it's an InlineAd or InterstitialAd.
    AdPlatformType? providerType;
    Object? adObject;

    if (adModel is InlineAd) {
      providerType = adModel.provider;
      adObject = adModel.adObject;
    } else if (adModel is InterstitialAd) {
      providerType = adModel.provider;
      adObject = adModel.adObject;
    }

    if (providerType != null && adObject != null) {
      final adProvider = _adProviders[providerType];
      if (adProvider != null) {
        await adProvider.disposeAd(adObject);
      } else {
        _logger.warning(
          'AdEngine: No AdProvider found for type $providerType to dispose ad.',
        );
      }
    } else {
      _logger.warning(
        'AdEngine: Cannot determine AdPlatformType or ad object for ad model of type '
        '${adModel.runtimeType}. Cannot dispose ad.',
      );
    }
  }

  @override
  Future<InlineAd?> getFeedAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
    FeedItemImageStyle? feedItemImageStyle,
  }) async {
    _logger.info('AdEngine: getFeedAd called for adType: $adType');
    return _loadInlineAd(
      adConfig: adConfig,
      adType: adType,
      adThemeStyle: adThemeStyle,
      userTier: userTier,
      feedItemImageStyle: feedItemImageStyle,
    );
  }

  @override
  Future<InterstitialAd?> getInterstitialAd({
    required AdConfig adConfig,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
  }) async {
    _logger.info('AdEngine: getInterstitialAd called.');
    if (!adConfig.enabled) {
      _logger.info('AdEngine: Ads are globally disabled in RemoteConfig.');
      return null;
    }

    final interstitialConfig = adConfig.navigationAdConfiguration;
    final isInterstitialEnabledForRole =
        interstitialConfig.enabled &&
        interstitialConfig.visibleTo.containsKey(userTier);

    if (!isInterstitialEnabledForRole) {
      _logger.info(
        'AdEngine: Interstitial ads are disabled for user tier $userTier '
        'or globally in RemoteConfig.',
      );
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning(
        'AdEngine: No AdProvider found for platform: $primaryAdPlatform',
      );
      return null;
    }

    final platformAdIdentifiers =
        adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'AdEngine: No AdPlatformIdentifiers found for platform: $primaryAdPlatform',
      );
      return null;
    }

    final adId = platformAdIdentifiers.interstitialAdId;

    if (adId == null || adId.isEmpty) {
      _logger.warning(
        'AdEngine: No interstitial ad ID configured for platform $primaryAdPlatform',
      );
      return null;
    }

    _logger.info(
      'AdEngine: Requesting Interstitial ad from $primaryAdPlatform AdProvider with ID: $adId',
    );
    try {
      final loadedAd = await adProvider.loadInterstitialAd(
        adPlatformIdentifiers: platformAdIdentifiers,
        adId: adId,
        adThemeStyle: adThemeStyle,
      );

      if (loadedAd != null) {
        _logger.info('AdEngine: Interstitial ad successfully loaded.');
        return loadedAd;
      } else {
        _logger.info('AdEngine: No Interstitial ad loaded by AdProvider.');
        return null;
      }
    } catch (e, s) {
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.adLoadFailed,
          payload: AdLoadFailedPayload(
            adProvider: primaryAdPlatform,
            adType: AdType.interstitial,
            errorCode: 0,
          ),
        ),
      );
      _logger.severe(
        'AdEngine: Error getting Interstitial ad from AdProvider: $e',
        e,
        s,
      );
      return null;
    }
  }

  Future<InlineAd?> _loadInlineAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
    FeedItemImageStyle? feedItemImageStyle,
  }) async {
    _logger.info('AdEngine: _loadInlineAd called for adType: $adType');
    if (!adConfig.enabled) {
      _logger.info('AdEngine: Ads are globally disabled in RemoteConfig.');
      return null;
    }

    final feedAdConfig = adConfig.feedAdConfiguration;
    final isFeedAdEnabledForRole =
        feedAdConfig.enabled && feedAdConfig.visibleTo.containsKey(userTier);

    if (!isFeedAdEnabledForRole) {
      _logger.info(
        'AdEngine: Feed ads are disabled for user tier $userTier '
        'or globally in RemoteConfig.',
      );
      return null;
    }

    if (adType != AdType.native && adType != AdType.banner) {
      _logger.warning(
        'AdEngine: _loadInlineAd called with unsupported AdType: $adType.',
      );
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning(
        'AdEngine: No AdProvider found for platform: $primaryAdPlatform',
      );
      return null;
    }

    final platformAdIdentifiers =
        adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'AdEngine: No AdPlatformIdentifiers found for platform: $primaryAdPlatform',
      );
      return null;
    }

    final adId = adType == AdType.native
        ? platformAdIdentifiers.nativeAdId
        : platformAdIdentifiers.bannerAdId;

    if (adId == null || adId.isEmpty) {
      _logger.warning(
        'AdEngine: No ad ID configured for platform $primaryAdPlatform and ad type $adType.',
      );
      return null;
    }

    for (var attempt = 0; attempt <= _maxAdLoadRetries; attempt++) {
      if (attempt > 0) {
        _logger.info(
          'AdEngine: Retrying $adType ad load (attempt $attempt) for ID: $adId after $_adLoadRetryDelay delay.',
        );
        await Future<void>.delayed(_adLoadRetryDelay);
      }

      try {
        _logger.info(
          'AdEngine: Requesting $adType ad from $primaryAdPlatform AdProvider with ID: $adId.',
        );
        InlineAd? loadedAd;

        switch (adType) {
          case AdType.native:
            loadedAd = await adProvider.loadNativeAd(
              adPlatformIdentifiers: platformAdIdentifiers,
              adId: adId,
              adThemeStyle: adThemeStyle,
              feedItemImageStyle: feedItemImageStyle,
            );
          case AdType.banner:
            loadedAd = await adProvider.loadBannerAd(
              adPlatformIdentifiers: platformAdIdentifiers,
              adId: adId,
              adThemeStyle: adThemeStyle,
              feedItemImageStyle: feedItemImageStyle,
            );
          case AdType.interstitial:
          case AdType.video:
            return null;
        }

        if (loadedAd != null) {
          _logger.info('AdEngine: $adType ad successfully loaded.');
          return loadedAd;
        } else {
          _logger.info('AdEngine: No $adType ad loaded by AdProvider.');
        }
      } catch (e, s) {
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvent.adLoadFailed,
            payload: AdLoadFailedPayload(
              adProvider: primaryAdPlatform,
              adType: adType,
              errorCode: 0,
            ),
          ),
        );
        _logger.severe(
          'AdEngine: Error getting $adType ad from AdProvider on attempt $attempt: $e',
          e,
          s,
        );
      }
    }

    _logger.warning(
      'AdEngine: All retry attempts failed for $adType ad with ID: $adId.',
    );
    return null;
  }

  @override
  Future<List<FeedItem>> injectFeedAdPlaceholders({
    required List<FeedItem> feedItems,
    required User? user,
    required RemoteConfig remoteConfig,
    required FeedItemImageStyle imageStyle,
    required AdThemeStyle adThemeStyle,
    int processedContentItemCount = 0,
  }) async {
    if (!remoteConfig.features.ads.feedAdConfiguration.enabled) {
      return feedItems;
    }

    final userTier = user?.tier ?? AccessTier.guest;
    final feedAdFrequencyConfig =
        remoteConfig.features.ads.feedAdConfiguration.visibleTo[userTier];

    final adFrequency = feedAdFrequencyConfig?.adFrequency ?? 0;
    final adPlacementInterval = feedAdFrequencyConfig?.adPlacementInterval ?? 0;

    if (adFrequency <= 0) {
      return feedItems;
    }

    final result = <FeedItem>[];
    var currentContentItemCount = processedContentItemCount;
    final primaryAdPlatform = remoteConfig.features.ads.primaryAdPlatform;
    final platformAdIdentifiers =
        remoteConfig.features.ads.platformAdIdentifiers[primaryAdPlatform];

    if (platformAdIdentifiers == null) {
      _logger.warning(
        'No AdPlatformIdentifiers found for primary platform: $primaryAdPlatform. '
        'Cannot inject ad placeholders.',
      );
      return feedItems;
    }

    final feedAdType = remoteConfig.features.ads.feedAdConfiguration.adType;

    for (final item in feedItems) {
      result.add(item);
      if (item is! AdPlaceholder) {
        currentContentItemCount++;
      }

      if (currentContentItemCount >= adPlacementInterval &&
          (currentContentItemCount - adPlacementInterval) % adFrequency == 0) {
        String? adIdentifier;
        switch (feedAdType) {
          case AdType.native:
            adIdentifier = platformAdIdentifiers.nativeAdId;
          case AdType.banner:
            adIdentifier = platformAdIdentifiers.bannerAdId;
          case AdType.interstitial:
          case AdType.video:
            adIdentifier = null;
        }

        if (adIdentifier != null) {
          result.add(
            AdPlaceholder(
              id: _uuid.v4(),
              adPlatformType: primaryAdPlatform,
              adType: feedAdType,
              adId: adIdentifier,
            ),
          );
        }
      }
    }
    return result;
  }
}
