import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [AdService].
///
/// This service is used when ads are disabled in the remote configuration.
/// It satisfies the interface requirements without performing any actual
/// ad loading or network calls.
class NoOpAdService implements AdService {
  /// Creates an instance of [NoOpAdService].
  NoOpAdService({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing NoOpAdService (Ads disabled).');
  }

  @override
  Future<void> disposeAd(dynamic adModel) async {
    // No-op
  }

  @override
  Future<InlineAd?> getFeedAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
    FeedItemImageStyle? feedItemImageStyle,
  }) async => null;

  @override
  Future<InterstitialAd?> getInterstitialAd({
    required AdConfig adConfig,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
  }) async => null;

  @override
  Future<List<FeedItem>> injectFeedAdPlaceholders({
    required List<FeedItem> feedItems,
    required User? user,
    required RemoteConfig remoteConfig,
    required FeedItemImageStyle imageStyle,
    required AdThemeStyle adThemeStyle,
    int processedContentItemCount = 0,
  }) async => feedItems;
}
