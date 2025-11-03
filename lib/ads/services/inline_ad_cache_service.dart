import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:logging/logging.dart';

/// {@template inline_ad_cache_service}
/// A singleton service for caching loaded inline ad objects (native and banner).
///
/// This service implements a **context-scoped caching architecture**. It stores
/// [InlineAd] objects in separate "buckets" for each ad context (e.g., a feed
/// filter ID, an article ID). This prevents unnecessary ad reloads when
/// switching between different UI contexts and ensures ads are managed correctly.
///
/// ### Caching and Data Flow Scenarios:
///
/// 1.  **Scenario 1 (Cache Hit):** When a user returns to a previously viewed
///     context (like a feed or an article), this service provides the
///     already-loaded ads for that specific context's key, preventing
///     unnecessary network requests and providing an instant ad experience.
///
/// 2.  **Scenario 2 (Cache Miss):** When a user views a new context for the
///     first time (or a context whose ads were cleared), this service will not
///     have ads for that `contextKey`, triggering a new ad load by the UI.
///
/// 3.  **Scenario 3 (Targeted Invalidation):** The `clearAdsForContext` method
///     allows for precise cache clearing (e.g., during a pull-to-refresh on a
///     specific feed) without affecting the ad caches of other contexts.
///
/// **Scope of Caching:**
/// This service specifically caches *inline* ads (native and banner). Interstitial
/// ads are managed separately and are not cached here.
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

  /// The internal in-memory cache.
  ///
  /// The key of the outer map is the contextKey, and the inner map is keyed by
  /// the placeholderId.
  final Map<String, Map<String, InlineAd?>> _cache = {};

  /// Retrieves an [InlineAd] from the cache.
  ///
  /// Returns the cached [InlineAd] if found, otherwise `null`.
  InlineAd? getAd({required String contextKey, required String placeholderId}) {
    final ad = _cache[contextKey]?[placeholderId];
    if (ad != null) {
      _logger.info(
        'Retrieved inline ad for context "$contextKey" and placeholder '
        '"$placeholderId" from cache.',
      );
    } else {
      _logger.info(
        'Inline ad for context "$contextKey" and placeholder "$placeholderId" '
        'not found in cache.',
      );
    }
    return ad;
  }

  /// Adds or updates an [InlineAd] in the cache.
  ///
  /// If [ad] is `null`, it effectively removes the entry for the given keys.
  void setAd({
    required String contextKey,
    required String placeholderId,
    required InlineAd? ad,
  }) {
    // Ensure the inner map for the contextKey exists.
    _cache.putIfAbsent(contextKey, () => {});

    final existingAd = _cache[contextKey]![placeholderId];
    if (existingAd != null) {
      // If an old ad exists for this slot, dispose of its resources.
      _logger.info(
        'Disposing old inline ad for context "$contextKey" and placeholder '
        '"$placeholderId" before caching new one.',
      );
      _adService.disposeAd(existingAd);
    }

    if (ad != null) {
      _cache[contextKey]![placeholderId] = ad;
      _logger.info(
        'Cached inline ad for context "$contextKey" and placeholder '
        '"$placeholderId".',
      );
    } else {
      _cache[contextKey]!.remove(placeholderId);
      _logger.info(
        'Removed inline ad for context "$contextKey" and placeholder '
        '"$placeholderId" from cache.',
      );
    }
  }

  /// Removes an [InlineAd] from the cache and disposes its resources.
  ///
  /// This method should be used when an ad is permanently removed from the UI
  /// and its resources need to be released.
  void removeAndDisposeAd({
    required String contextKey,
    required String placeholderId,
  }) {
    final ad = _cache[contextKey]?[placeholderId];
    if (ad != null) {
      _logger.info(
        'Removing and disposing inline ad for context "$contextKey" and '
        'placeholder "$placeholderId".',
      );
      // Delegate disposal to AdService
      _adService.disposeAd(ad);
      _cache[contextKey]!.remove(placeholderId);
    } else {
      _logger.info(
        'Inline ad for context "$contextKey" and placeholder "$placeholderId" '
        'not found in cache for disposal.',
      );
    }
  }

  /// Clears all cached ads for a *single* ad context and disposes their
  /// resources.
  ///
  /// This is the preferred method for invalidating ads for a specific context,
  /// for example, during a pull-to-refresh action on a feed, as it does not
  /// affect the caches of other contexts.
  void clearAdsForContext({required String contextKey}) {
    _logger.info('Clearing all cached ads for context "$contextKey"...');
    final contextAdCache = _cache[contextKey];
    if (contextAdCache != null) {
      for (final ad in contextAdCache.values.whereType<InlineAd>()) {
        _adService.disposeAd(ad);
      }
    }
    _cache.remove(contextKey);
    _logger.info('All cached ads for context "$contextKey" cleared.');
  }

  /// Clears all cached inline ad objects and disposes their resources.
  ///
  /// This method should be called when the application state is completely
  /// reset (e.g., on logout) to ensure all ad resources are released.
  void clearAllAds() {
    _logger.info(
      'Clearing all cached inline ads and disposing their resources.',
    );
    for (final contextKey in _cache.keys.toList()) {
      clearAdsForContext(contextKey: contextKey);
    }
    _cache.clear();
    _logger.info('All cached inline ads cleared.');
  }

  /// For debugging: prints the current state of the cache.
  @visibleForTesting
  void printCacheState() {
    _logger.info('Current Inline Ad Cache State:');
    if (_cache.isEmpty) {
      _logger.info('  Cache is empty.');
    } else {
      _cache.forEach((contextKey, innerMap) {
        _logger.info('  Context Key: "$contextKey"');
        innerMap.forEach((placeholderId, ad) {
          _logger.info(
            '    -> Placeholder: $placeholderId, Ad: ${ad?.provider}, '
            'Type: ${ad.runtimeType}',
          );
        });
      });
    }
  }
}
