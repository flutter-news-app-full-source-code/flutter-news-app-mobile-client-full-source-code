import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
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
  AdService({required AdProvider adProvider, Logger? logger})
      : _adProvider = adProvider,
        _logger = logger ?? Logger('AdService');

  final AdProvider _adProvider;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  /// Initializes the underlying ad provider.
  ///
  /// This should be called once at application startup.
  Future<void> initialize() async {
    _logger.info('Initializing AdService...');
    await _adProvider.initialize();
    _logger.info('AdService initialized.');
  }

  /// Retrieves a loaded native ad wrapped as an [AdFeedItem].
  ///
  /// This method delegates the ad loading to the injected [AdProvider].
  /// If an ad is successfully loaded, it's wrapped in an [AdFeedItem]
  /// with a unique ID.
  ///
  /// Returns an [AdFeedItem] if an ad is available, otherwise `null`.
  Future<AdFeedItem?> getAd() async {
    _logger.info('Requesting native ad from AdProvider...');
    try {
      final nativeAd = await _adProvider.loadNativeAd();
      if (nativeAd != null) {
        _logger.info('Native ad successfully loaded and wrapped.');
        return AdFeedItem(id: _uuid.v4(), nativeAd: nativeAd);
      } else {
        _logger.info('No native ad loaded by AdProvider.');
        return null;
      }
    } catch (e) {
      _logger.severe('Error getting ad from AdProvider: $e');
      return null;
    }
  }
}
