import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/ad_provider.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template demo_ad_provider}
/// A concrete implementation of [AdProvider] for the 'demo' ad platform.
///
/// This provider simulates ad loading for the demo environment without
/// making actual ad network calls. It returns placeholder ad objects
/// for native, banner, and interstitial ads.
/// {@endtemplate}
class DemoAdProvider implements AdProvider {
  /// {@macro demo_ad_provider}
  DemoAdProvider({Logger? logger})
    : _logger = logger ?? Logger('DemoAdProvider');

  final Logger _logger;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> initialize() async {
    _logger.info('Demo Ad Provider initialized (no actual SDK to init).');
    return Future.value();
  }

  @override
  Future<NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle, // ignore: avoid_unused_param
    FeedItemImageStyle? feedItemImageStyle,
  }) async {
    _logger.info('Simulating native ad load for demo environment.');
    // Simulate a delay for loading.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return NativeAd(
      id: _uuid.v4(),
      provider: AdPlatformType.demo,
      adObject: Object(),
      templateType: feedItemImageStyle == FeedItemImageStyle.largeThumbnail
          ? NativeAdTemplateType.medium
          : NativeAdTemplateType.small,
    );
  }

  @override
  Future<BannerAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle, // ignore: avoid_unused_param
    FeedItemImageStyle? feedItemImageStyle, // ignore: avoid_unused_param
  }) async {
    _logger.info('Simulating banner ad load for demo environment.');
    // Simulate a delay for loading.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return BannerAd(
      id: _uuid.v4(),
      provider: AdPlatformType.demo,
      adObject: Object(),
    );
  }

  @override
  Future<InterstitialAd?> loadInterstitialAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  }) async {
    _logger.info('Simulating interstitial ad load for demo environment.');
    // Simulate a delay for loading.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return InterstitialAd(
      id: _uuid.v4(),
      provider: AdPlatformType.demo,
      adObject: Object(),
    );
  }

  @override
  Future<void> disposeAd(Object adObject) async {
    _logger.info(
      'DemoAdProvider: No explicit disposal needed for demo ad object: '
      '${adObject.runtimeType}',
    );
    // Demo ad objects are simple Dart objects and do not hold native resources
    // that require explicit disposal.
  }
}
