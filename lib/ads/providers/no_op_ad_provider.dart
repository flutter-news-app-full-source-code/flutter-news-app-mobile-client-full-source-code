import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/rewarded_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/ad_provider.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [AdProvider].
///
/// This provider is used when ads are disabled or when a specific platform
/// provider is unavailable. It satisfies the interface requirements without
/// performing any actual ad loading.
class NoOpAdProvider implements AdProvider {
  /// Creates an instance of [NoOpAdProvider].
  NoOpAdProvider({Logger? logger})
    : _logger = logger ?? Logger('NoOpAdProvider');

  final Logger _logger;

  @override
  Future<void> initialize() async {
    _logger.fine('Initializing NoOpAdProvider.');
  }

  @override
  Future<NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
    FeedItemImageStyle? feedItemImageStyle,
  }) async {
    _logger.fine('NoOpAdProvider: loadNativeAd called. Returning null.');
    return null;
  }

  @override
  Future<BannerAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
    FeedItemImageStyle? feedItemImageStyle,
  }) async {
    _logger.fine('NoOpAdProvider: loadBannerAd called. Returning null.');
    return null;
  }

  @override
  Future<InterstitialAd?> loadInterstitialAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  }) async {
    _logger.fine('NoOpAdProvider: loadInterstitialAd called. Returning null.');
    return null;
  }

  @override
  Future<RewardedAd?> loadRewardedAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  }) async {
    _logger.fine('NoOpAdProvider: loadRewardedAd called. Returning null.');
    return null;
  }

  @override
  Future<void> disposeAd(Object adObject) async {
    _logger.fine('NoOpAdProvider: disposeAd called.');
  }
}
