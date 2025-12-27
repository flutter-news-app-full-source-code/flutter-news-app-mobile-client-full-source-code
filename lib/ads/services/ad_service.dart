import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template ad_service}
/// A service responsible for managing and providing ads to the application.
///
/// This service acts as an intermediary between the application's UI/logic
/// and the underlying ad network providers (e.g., AdMob, etc). It handles
/// requesting different types of ads (inline native/banner, full-screen interstitial)
/// and wrapping them in appropriate generic models for use throughout the app.
///
/// It is also responsible for injecting stateless `AdPlaceholder` markers into
/// lists of feed items based on remote configuration rules.
/// {@endtemplate}
class AdService {
  /// {@macro ad_service}
  ///
  /// Requires a map of [AdProvider]s to be injected, keyed by [AdPlatformType].
  /// These providers will be used to load ads from specific ad networks.
  AdService({
    required Map<AdPlatformType, AdProvider> adProviders,
    required AppEnvironment environment,
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : _adProviders = adProviders,
       _environment = environment,
       _analyticsService = analyticsService,
       _logger = logger ?? Logger('AdService');

  final Map<AdPlatformType, AdProvider> _adProviders;
  final AppEnvironment _environment;
  final AnalyticsService _analyticsService;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  // Configurable retry parameters for ad loading.
  static const int _maxAdLoadRetries = 2;
  static const Duration _adLoadRetryDelay = Duration(seconds: 1);

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

  /// Disposes of an ad object by delegating to the appropriate [AdProvider].
  ///
  /// This method is called by the [InlineAdCacheService] to ensure that
  /// inline ad resources are released when an ad is removed from the cache
  /// or replaced. It also handles disposal of interstitial ads.
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
          'AdService: No AdProvider found for type $providerType to dispose ad.',
        );
      }
    } else {
      _logger.warning(
        'AdService: Cannot determine AdPlatformType or ad object for ad model of type '
        '${adModel.runtimeType}. Cannot dispose ad.',
      );
    }
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
  /// - [userRole]: The current role of the user, used to determine ad visibility.
  Future<InlineAd?> getFeedAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    required AppUserRole userRole,
    FeedItemImageStyle? feedItemImageStyle,
  }) async {
    _logger.info('AdService: getFeedAd called for adType: $adType');
    return _loadInlineAd(
      adConfig: adConfig,
      adType: adType,
      adThemeStyle: adThemeStyle,
      userRole: userRole,
      feedItemImageStyle: feedItemImageStyle,
    );
  }

  /// Retrieves a loaded full-screen interstitial ad.
  ///
  /// This method delegates the ad loading to the appropriate [AdProvider]
  /// based on the [adConfig]'s `primaryAdPlatform`. It is specifically
  /// designed for interstitial ads that are displayed as full-screen overlays,
  /// typically on route changes.
  ///
  /// Returns an [InterstitialAd] if an interstitial ad is available, otherwise `null`.
  ///
  /// - [adConfig]: The remote configuration for ad display rules.
  /// - [adThemeStyle]: UI-agnostic theme properties for ad styling.
  /// - [userRole]: The current role of the user, used to determine ad visibility.
  Future<InterstitialAd?> getInterstitialAd({
    required AdConfig adConfig,
    required AdThemeStyle adThemeStyle,
    required AppUserRole userRole,
  }) async {
    _logger.info('AdService: getInterstitialAd called.');
    if (!adConfig.enabled) {
      _logger.info('AdService: Ads are globally disabled in RemoteConfig.');
      return null;
    }

    final interstitialConfig = adConfig.navigationAdConfiguration;
    // Check if the interstitial ads are globally enabled AND if the current
    // user role has a defined configuration in the visibleTo map.
    final isInterstitialEnabledForRole =
        interstitialConfig.enabled &&
        interstitialConfig.visibleTo.containsKey(userRole);

    if (!isInterstitialEnabledForRole) {
      _logger.info(
        'AdService: Interstitial ads are disabled for user role $userRole '
        'or globally in RemoteConfig.',
      );
      return null;
    }

    final primaryAdPlatform = adConfig.primaryAdPlatform;

    // If RemoteConfig specifies AdPlatformType.demo but the app is not in demo environment,
    // log a warning and skip ad load.
    if (primaryAdPlatform == AdPlatformType.demo &&
        _environment != AppEnvironment.demo) {
      _logger.warning(
        'AdService: RemoteConfig specifies AdPlatformType.demo as primary '
        'ad platform, but app is not in demo environment. Skipping interstitial ad load.',
      );
      return null;
    }

    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning(
        'AdService: No AdProvider found for platform: $primaryAdPlatform',
      );
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
    final adId = platformAdIdentifiers.interstitialAdId;

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
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.adLoadFailed,
          payload: AdLoadFailedPayload(
            adProvider: primaryAdPlatform,
            adType: AdType.interstitial,
            // TODO(fulleni): add a meaningful status code.
            errorCode: 0,
          ),
        ),
      );
      _logger.severe(
        'AdService: Error getting Interstitial ad from AdProvider: $e',
        e,
        s,
      );
      return null;
    }
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
  /// - [feedItemImageStyle]: The user's preference for feed layout,
  ///   which can be used to request an appropriately sized ad.
  /// - [userRole]: The current role of the user, used to determine ad visibility.
  ///
  /// Returns an [InlineAd] if an ad is successfully loaded, otherwise `null`.
  Future<InlineAd?> _loadInlineAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    required AppUserRole userRole,
    FeedItemImageStyle? feedItemImageStyle,
  }) async {
    _logger.info('AdService: _loadInlineAd called for adType: $adType');
    // Check if ads are globally enabled.
    if (!adConfig.enabled) {
      _logger.info('AdService: Ads are globally disabled in RemoteConfig.');
      return null;
    }

    final feedAdConfig = adConfig.feedAdConfiguration;
    final isFeedAdEnabledForRole =
        feedAdConfig.enabled && feedAdConfig.visibleTo.containsKey(userRole);

    if (!isFeedAdEnabledForRole) {
      _logger.info(
        'AdService: Feed ads are disabled for user role $userRole '
        'or globally in RemoteConfig.',
      );
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

    // If RemoteConfig specifies AdPlatformType.demo but the app is not in demo environment,
    // log a warning and skip ad load.
    if (primaryAdPlatform == AdPlatformType.demo &&
        _environment != AppEnvironment.demo) {
      _logger.warning(
        'AdService: RemoteConfig specifies AdPlatformType.demo as primary '
        'ad platform, but app is not in demo environment. Skipping inline ad load.',
      );
      return null;
    }

    final adProvider = _adProviders[primaryAdPlatform];

    if (adProvider == null) {
      _logger.warning(
        'AdService: No AdProvider found for platform: $primaryAdPlatform',
      );
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

    final adId = adType == AdType.native
        ? platformAdIdentifiers.nativeAdId
        : platformAdIdentifiers.bannerAdId;

    if (adId == null || adId.isEmpty) {
      _logger.warning(
        'AdService: No ad ID configured for platform $primaryAdPlatform and ad type $adType.',
      );
      return null;
    }

    for (var attempt = 0; attempt <= _maxAdLoadRetries; attempt++) {
      if (attempt > 0) {
        _logger.info(
          'AdService: Retrying $adType ad load (attempt $attempt) for ID: $adId after $_adLoadRetryDelay delay.',
        );
        await Future<void>.delayed(_adLoadRetryDelay);
      }

      try {
        _logger.info(
          'AdService: Requesting $adType ad from $primaryAdPlatform AdProvider with ID: $adId.',
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
          // If no ad is returned, it might be a "no fill" scenario.
          // Continue to the next retry attempt.
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
          'AdService: Error getting $adType ad from AdProvider on attempt $attempt: $e',
          e,
          s,
        );
        // If an exception occurs, log it and continue to the next retry attempt.
      }
    }

    _logger.warning(
      'AdService: All retry attempts failed for $adType ad with ID: $adId.',
    );
    return null;
  }

  /// Injects stateless [AdPlaceholder] markers into a list of [FeedItem]s
  /// based on configured ad frequency rules.
  ///
  /// This method ensures that ad placeholders for *inline* ads (native and banner)
  /// are placed according to the `adPlacementInterval` (initial buffer before
  /// the first ad) and `adFrequency` (subsequent ad spacing). It correctly
  /// accounts for content items and decorators, ignoring previously injected
  /// ad placeholders when calculating placement.
  ///
  /// [feedItems]: The list of feed items (headlines, other decorators)
  ///   to inject ad placeholders into.
  /// [user]: The current authenticated user, used to determine ad configuration.
  /// [remoteConfig]: The remote configuration for ad display rules.
  /// [imageStyle]: The desired image style for the ad, used to determine
  ///   the placeholder's template type.
  /// [adThemeStyle]: The current theme style for ads, passed through to the
  ///   AdLoaderWidget for consistent styling.
  /// [processedContentItemCount]: The count of *content items* (non-ad,
  ///   non-decorator) that have already been processed in previous feed
  ///   loads/pages. This is crucial for maintaining correct ad placement
  ///   across pagination.
  ///
  /// Returns a new list of [FeedItem] objects, interspersed with ad placeholders.
  Future<List<FeedItem>> injectFeedAdPlaceholders({
    required List<FeedItem> feedItems,
    required User? user,
    required RemoteConfig remoteConfig,
    required FeedItemImageStyle imageStyle,
    required AdThemeStyle adThemeStyle,
    int processedContentItemCount = 0,
  }) async {
    // If feed ads are not enabled in the remote config, return the original list.
    if (!remoteConfig.features.ads.feedAdConfiguration.enabled) {
      return feedItems;
    }

    final userRole = user?.appRole ?? AppUserRole.guestUser;

    // Determine ad frequency rules based on user role.
    final feedAdFrequencyConfig =
        remoteConfig.features.ads.feedAdConfiguration.visibleTo[userRole];

    // Default to 0 for adFrequency and adPlacementInterval if no config is found
    // for the user role, effectively disabling ads for that role.
    final adFrequency = feedAdFrequencyConfig?.adFrequency ?? 0;
    final adPlacementInterval = feedAdFrequencyConfig?.adPlacementInterval ?? 0;

    // If ad frequency is zero or less, no ads should be injected.
    if (adFrequency <= 0) {
      return feedItems;
    }

    final result = <FeedItem>[];
    // This counter tracks the absolute number of *content items* (headlines,
    // topics, sources, countries, and decorators) processed so far, including
    // those from previous pages. This is key for accurate ad placement.
    var currentContentItemCount = processedContentItemCount;

    // Get the primary ad platform and its identifiers
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

    // Get the ad type for feed ads (native or banner)
    final feedAdType = remoteConfig.features.ads.feedAdConfiguration.adType;

    for (final item in feedItems) {
      result.add(item);

      // Only increment the content item counter if the current item is
      // a primary content type or a decorator (not an ad placeholder).
      // This ensures ad placement is based purely on content/decorator density.
      if (item is! AdPlaceholder) {
        currentContentItemCount++;
      }

      // Check if an ad should be injected at the current position.
      // An ad is injected if:
      // 1. We have passed the initial placement interval.
      // 2. The number of content items *after* the initial interval is a
      //    multiple of the ad frequency.
      if (currentContentItemCount >= adPlacementInterval &&
          (currentContentItemCount - adPlacementInterval) % adFrequency == 0) {
        String? adIdentifier;

        // Determine the specific ad ID based on the feed ad type.
        switch (feedAdType) {
          case AdType.native:
            adIdentifier = platformAdIdentifiers.nativeAdId;
          case AdType.banner:
            adIdentifier = platformAdIdentifiers.bannerAdId;
          case AdType.interstitial:
          case AdType.video:
            // Interstitial and video ads are not injected into the feed.
            _logger.warning(
              'Attempted to inject $feedAdType ad into feed. This is not supported.',
            );
            adIdentifier = null;
        }

        if (adIdentifier != null) {
          // The actual ad loading will be handled by a dedicated `AdLoaderWidget`
          // in the UI layer when this placeholder scrolls into view. This
          // decouples ad loading from the BLoC's state and allows for efficient
          // caching and disposal of native ad resources.
          result.add(
            AdPlaceholder(
              id: _uuid.v4(),
              adPlatformType: primaryAdPlatform,
              adType: feedAdType,
              adId: adIdentifier,
            ),
          );
        } else {
          _logger.warning(
            'No valid ad ID found for platform $primaryAdPlatform and type '
            '$feedAdType. Ad placeholder not injected.',
          );
        }
      }
    }
    return result;
  }
}
