import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:logging/logging.dart';
import 'package:core/core.dart'; // Import core for AdPlatformType

/// {@template ad_cache_service}
/// A singleton service for caching loaded native ad objects.
///
/// This service helps to prevent unnecessary re-loading of native ads
/// when they scroll out of view and then back into view in a scrollable list.
/// It stores [NativeAd] objects by a unique ID (typically the [AdPlaceholder.id])
/// and allows for retrieval and clearing of cached ads.
///
/// Native ad objects (like `google_mobile_ads.NativeAd`) are stateful and
/// resource-intensive. Caching them allows for smoother scrolling and
/// reduces network requests, while still ensuring proper disposal when
/// the cache is cleared (e.g., on a full feed refresh).
/// {@endtemplate}
class AdCacheService {
  /// Factory constructor to provide the singleton instance.
  factory AdCacheService() => _instance;

  /// Private constructor for the singleton pattern.
  AdCacheService._internal() : _logger = Logger('AdCacheService');

  /// The single instance of [AdCacheService].
  static final AdCacheService _instance = AdCacheService._internal();

  final Logger _logger;

  /// A map to store loaded native ad objects, keyed by their unique ID.
  ///
  /// The value is nullable to allow for explicit removal of an ad from the cache.
  final Map<String, NativeAd?> _cache = {};

  /// Retrieves a [NativeAd] from the cache using its [id].
  ///
  /// Returns the cached [NativeAd] if found, otherwise `null`.
  NativeAd? getAd(String id) {
    final ad = _cache[id];
    if (ad != null) {
      _logger.info('Retrieved ad with ID "$id" from cache.');
    } else {
      _logger.info('Ad with ID "$id" not found in cache.');
    }
    return ad;
  }

  /// Adds or updates a [NativeAd] in the cache.
  ///
  /// If [ad] is `null`, it effectively removes the entry for [id].
  void setAd(String id, NativeAd? ad) {
    if (ad != null) {
      _cache[id] = ad;
      _logger.info('Cached ad with ID "$id".');
    } else {
      _cache.remove(id);
      _logger.info('Removed ad with ID "$id" from cache.');
    }
  }

  /// Clears all cached native ad objects and disposes their native resources.
  ///
  /// This method should be called when the feed is fully refreshed or
  /// when the application is closing to ensure all native ad resources
  /// are released.
  void clearAllAds() {
    _logger.info('Clearing all cached ads and disposing native resources.');
    for (final ad in _cache.values) {
      // Only dispose if the ad is an AdMob native ad.
      // Placeholder ads do not have native resources to dispose.
      if (ad?.provider == AdPlatformType.admob) {
        // Cast to the specific AdMob NativeAd type to call dispose.
        // This is safe because we check the provider type.
        (ad!.adObject as dynamic).dispose();
      }
    }
    _cache.clear();
    _logger.info('All cached ads cleared.');
  }

  /// For debugging: prints the current state of the cache.
  @visibleForTesting
  void printCacheState() {
    _logger.info('Current Ad Cache State:');
    if (_cache.isEmpty) {
      _logger.info('  Cache is empty.');
    } else {
      _cache.forEach((id, ad) {
        _logger.info(
          '  ID: $id, Provider: ${ad?.provider}, Template: ${ad?.templateType}',
        );
      });
    }
  }
}
