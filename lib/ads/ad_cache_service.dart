import 'package:core/core.dart'; // Import core for AdPlatformType
import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart'; // Import BannerAd
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart'; // Import InlineAd
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'; // Import NativeAd
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob; // Import AdMob for disposal
import 'package:logging/logging.dart';

/// {@template ad_cache_service}
/// A singleton service for caching loaded inline ad objects (native and banner).
///
/// This service helps to prevent unnecessary re-loading of inline ads
/// when they scroll out of view and then back into view in a scrollable list.
/// It stores [InlineAd] objects by a unique ID (typically the [AdPlaceholder.id])
/// and allows for retrieval and clearing of cached ads.
///
/// Inline ad objects (like `google_mobile_ads.NativeAd` and `google_mobile_ads.BannerAd`)
/// are stateful and resource-intensive. Caching them allows for smoother scrolling
/// and reduces network requests, while still ensuring proper disposal when
/// the cache is cleared (e.g., on a full feed refresh).
///
/// Interstitial ads are not cached by this service as their lifecycle is
/// managed differently (typically shown once on navigation and then disposed).
/// {@endtemplate}
class AdCacheService {
  /// Factory constructor to provide the singleton instance.
  factory AdCacheService() => _instance;

  /// Private constructor for the singleton pattern.
  AdCacheService._internal() : _logger = Logger('AdCacheService');

  /// The single instance of [AdCacheService].
  static final AdCacheService _instance = AdCacheService._internal();

  final Logger _logger;

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
    if (ad != null) {
      _cache[id] = ad;
      _logger.info('Cached inline ad with ID "$id".');
    } else {
      _cache.remove(id);
      _logger.info('Removed inline ad with ID "$id" from cache.');
    }
  }

  /// Clears all cached inline ad objects and disposes their native resources.
  ///
  /// This method should be called when the feed is fully refreshed or
  /// when the application is closing to ensure all native ad resources
  /// are released.
  void clearAllAds() {
    _logger.info('Clearing all cached inline ads and disposing native resources.');
    for (final ad in _cache.values) {
      if (ad?.provider == AdPlatformType.admob) {
        // Dispose AdMob native and banner ad objects.
        // This is safe because we check the provider type.
        if (ad is NativeAd && ad.adObject is admob.NativeAd) {
          (ad.adObject as admob.NativeAd).dispose();
        } else if (ad is BannerAd && ad.adObject is admob.BannerAd) {
          (ad.adObject as admob.BannerAd).dispose();
        }
      }
    }
    _cache.clear();
    _logger.info('All cached inline ads cleared.');
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
          '  ID: $id, Provider: ${ad?.provider}, Type: ${ad.runtimeType}',
        );
      });
    }
  }
}
