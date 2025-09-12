import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:logging/logging.dart';

/// {@template inline_ad_cache_service}
/// A singleton service for caching loaded inline ad objects (native and banner).
///
/// This service helps to prevent unnecessary re-loading of inline ads
/// when they scroll out of view and then back into view in a scrollable list.
/// It stores [InlineAd] objects by a unique ID (typically the [AdPlaceholder.id])
/// and allows for retrieval and clearing of cached ads.
///
/// **Scope of Caching:**
/// This service specifically caches *inline* ads, which include both feed ads
/// and in-article ads. These ads are designed to be displayed directly within
/// content lists and benefit from caching to improve scrolling performance
/// and reduce network requests.
///
/// **Exclusion of Interstitial Ads:**
/// Interstitial ads are *not* cached by this service. Their lifecycle is
/// managed differently: they are typically loaded on demand, shown once
/// during navigation transitions, and then disposed immediately after use.
/// Caching them would not provide performance benefits and could lead to
/// resource leaks or unexpected behavior.
///
/// Inline ad objects (like `google_mobile_ads.NativeAd` and `google_mobile_ads.BannerAd`)
/// are stateful and resource-intensive. Caching them allows for smoother scrolling
/// and reduces network requests, while still ensuring proper disposal when
/// the cache is cleared (e.g., on a full feed refresh).
/// {@endtemplate}
class InlineAdCacheService {
  /// Factory constructor to provide the singleton instance.
  factory InlineAdCacheService({required AdService adService}) {
    _instance._adService = adService;
    return _instance;
  }

  /// Private constructor for the singleton pattern.
  InlineAdCacheService._internal() : _logger = Logger('InlineAdCacheService');

  /// The single instance of [InlineAdCacheService].
  static final InlineAdCacheService _instance =
      InlineAdCacheService._internal();

  final Logger _logger;

/// The [AdService] instance used for disposing inline ad objects.
/// This is set via the factory constructor.
late AdService _adService;

/// A map to store loaded inline ad objects, keyed by their unique ID.
///
/// The value is nullable to allow for explicit removal of an ad from the cache.
final Map<String, InlineAd?> _cache = {};

/// Retrieves an [InlineAd] from the cache using its [id].
///
/// Returns the cached [InlineAd] if found, otherwise `null`.
InlineAd? getAd(String id) {
    final ad = _cache[id];
    if (ad != null) {
      _logger.info('Retrieved inline ad with ID "$id" from cache.');
    } else {
      _logger.info('Inline ad with ID "$id" not found in cache.');
    }
    return ad;
  }

  /// Adds or updates an [InlineAd] in the cache.
  ///
  /// If [ad] is `null`, it effectively removes the entry for [id].
  void setAd(String id, InlineAd? ad) {
    if (_cache.containsKey(id) && _cache[id] != null) {
      // If an old ad exists for this ID, dispose of its resources.
      _logger.info('Disposing old inline ad for ID "$id" before caching new one.');
      _adService.disposeAd(_cache[id]);
    }

    if (ad != null) {
      _cache[id] = ad;
      _logger.info('Cached inline ad with ID "$id".');
    } else {
      _cache.remove(id);
      _logger.info('Removed inline ad with ID "$id" from cache.');
    }
  }

  /// Removes an [InlineAd] from the cache and disposes its resources.
  ///
  /// This method should be used when an ad is permanently removed from the UI
  /// and its resources need to be released.
  void removeAndDisposeAd(String id) {
    final ad = _cache[id];
    if (ad != null) {
      _logger.info('Removing and disposing inline ad with ID "$id".');
      _adService.disposeAd(ad);
      _cache.remove(id);
    } else {
      _logger.info('Inline ad with ID "$id" not found in cache for disposal.');
    }
  }

  /// Clears all cached inline ad objects and disposes their resources.
  ///
  /// This method should be called when the feed is fully refreshed or
  /// when the application is closing to ensure all ad resources
  /// are released.
  void clearAllAds() {
    _logger.info(
      'Clearing all cached inline ads and disposing their resources.',
    );
    for (final id in _cache.keys.toList()) {
      // Use the new removeAndDisposeAd method for consistent disposal.
      removeAndDisposeAd(id);
    }
    _cache.clear(); // Ensure cache is empty after disposal attempts.
    _logger.info('All cached inline ads cleared.');
  }

  /// For debugging: prints the current state of the cache.
  @visibleForTesting
  void printCacheState() {
    _logger.info('Current Inline Ad Cache State:');
    if (_cache.isEmpty) {
      _logger.info('  Cache is empty.');
    } else {
      _cache.forEach((id, ad) {
        _logger.info(
          '  ID: $id, Provider: ${ad?.provider}, Type: ${ad.runtimeType}',
        );
      });
    }
  }
}
