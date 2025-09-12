import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template local_ad_provider}
/// A concrete implementation of [AdProvider] for fetching local ads.
///
/// This provider uses a [DataRepository<LocalAd>] to retrieve [LocalAd] objects
/// from a backend or local data source. It adapts these [LocalAd] objects
/// into our generic [NativeAd], [BannerAd], and [InterstitialAd] models for
/// consistent handling within the application.
/// {@endtemplate}
class LocalAdProvider implements AdProvider {
  /// {@macro local_ad_provider}
  LocalAdProvider({
    required DataRepository<LocalAd> localAdRepository,
    Logger? logger,
  }) : _localAdRepository = localAdRepository,
       _logger = logger ?? Logger('LocalAdProvider');

  final DataRepository<LocalAd> _localAdRepository;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  /// Initializes the local ad provider.
  ///
  /// This implementation does not require any specific SDK initialization.
  @override
  Future<void> initialize() async {
    _logger.info(
      'LocalAdProvider: Local Ad Provider initialized (no specific SDK to init).',
    );
  }

  @override
  Future<NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
    HeadlineImageStyle? headlineImageStyle, // Added for interface consistency
  }) async {
    _logger.info('LocalAdProvider: loadNativeAd called for adId: $adId');
    if (adId == null || adId.isEmpty) {
      _logger.warning('LocalAdProvider: No local native ad ID provided.');
      return null;
    }

    _logger.info(
      'LocalAdProvider: Attempting to load local native ad with ID: $adId',
    );

    try {
      final localNativeAd = await _localAdRepository.read(id: adId);

      if (localNativeAd is LocalNativeAd) {
        _logger.info(
          'LocalAdProvider: Local native ad loaded successfully: ${localNativeAd.id}',
        );
        return NativeAd(
          id: _uuid.v4(),
          provider: AdPlatformType.local,
          adObject: localNativeAd,
          templateType: headlineImageStyle == HeadlineImageStyle.largeThumbnail
              ? NativeAdTemplateType.medium
              : NativeAdTemplateType.small,
        );
      } else {
        _logger.warning(
          'LocalAdProvider: Fetched ad with ID $adId is not a LocalNativeAd. '
          'Received type: ${localNativeAd.runtimeType}',
        );
        return null;
      }
    } on HttpException catch (e) {
      _logger.severe(
        'LocalAdProvider: Error fetching local native ad with ID $adId: $e',
      );
      return null;
    } catch (e, s) {
      _logger.severe(
        'LocalAdProvider: Unexpected error loading local native ad with ID $adId: $e',
        e,
        s,
      );
      return null;
    }
  }

  @override
  Future<BannerAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
    HeadlineImageStyle? headlineImageStyle, // Added for interface consistency
  }) async {
    _logger.info('LocalAdProvider: loadBannerAd called for adId: $adId');
    if (adId == null || adId.isEmpty) {
      _logger.warning('LocalAdProvider: No local banner ad ID provided.');
      return null;
    }

    _logger.info(
      'LocalAdProvider: Attempting to load local banner ad with ID: $adId',
    );

    try {
      final localBannerAd = await _localAdRepository.read(id: adId);

      if (localBannerAd is LocalBannerAd) {
        _logger.info(
          'LocalAdProvider: Local banner ad loaded successfully: ${localBannerAd.id}',
        );
        return BannerAd(
          id: _uuid.v4(),
          provider: AdPlatformType.local,
          adObject: localBannerAd,
        );
      } else {
        _logger.warning(
          'LocalAdProvider: Fetched ad with ID $adId is not a LocalBannerAd. '
          'Received type: ${localBannerAd.runtimeType}',
        );
        return null;
      }
    } on HttpException catch (e) {
      _logger.severe(
        'LocalAdProvider: Error fetching local banner ad with ID $adId: $e',
      );
      return null;
    } catch (e, s) {
      _logger.severe(
        'LocalAdProvider: Unexpected error loading local banner ad with ID $adId: $e',
        e,
        s,
      );
      return null;
    }
  }

  @override
  Future<InterstitialAd?> loadInterstitialAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  }) async {
    _logger.info('LocalAdProvider: loadInterstitialAd called for adId: $adId');
    if (adId == null || adId.isEmpty) {
      _logger.warning('LocalAdProvider: No local interstitial ad ID provided.');
      return null;
    }

    _logger.info(
      'LocalAdProvider: Attempting to load local interstitial ad with ID: $adId',
    );

    try {
      final localInterstitialAd = await _localAdRepository.read(id: adId);

      if (localInterstitialAd is LocalInterstitialAd) {
        _logger.info(
          'LocalAdProvider: Local interstitial ad loaded successfully: ${localInterstitialAd.id}',
        );
        return InterstitialAd(
          id: _uuid.v4(),
          provider: AdPlatformType.local,
          adObject: localInterstitialAd,
        );
      } else {
        _logger.warning(
          'LocalAdProvider: Fetched ad with ID $adId is not a LocalInterstitialAd. '
          'Received type: ${localInterstitialAd.runtimeType}',
        );
        return null;
      }
    } on HttpException catch (e) {
      _logger.severe(
        'LocalAdProvider: Error fetching local interstitial ad with ID $adId: $e',
      );
      return null;
    } catch (e, s) {
      _logger.severe(
        'LocalAdProvider: Unexpected error loading local interstitial ad with ID $adId: $e',
        e,
        s,
      );
      return null;
    }
  }

  @override
  Future<void> disposeAd(Object adObject) async {
    _logger.info(
      'LocalAdProvider: No explicit disposal needed for local ad object: '
      '${adObject.runtimeType}',
    );
    // Local ad objects are simple Dart objects and do not hold native resources
    // that require explicit disposal.
  }
}
