import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template local_ad_provider}
/// A concrete implementation of [AdProvider] for fetching local ads.
///
/// This provider uses a [DataRepository<LocalAd>] to retrieve [LocalAd] objects
/// from a backend or local data source. It adapts these [LocalAd] objects
/// into our generic [app_native_ad.NativeAd] model for consistent handling
/// within the application.
/// {@endtemplate}
class LocalAdProvider implements AdProvider {
  /// {@macro local_ad_provider}
  LocalAdProvider({
    required DataRepository<LocalAd> localAdRepository,
    Logger? logger,
  })  : _localAdRepository = localAdRepository,
        _logger = logger ?? Logger('LocalAdProvider');

  final DataRepository<LocalAd> _localAdRepository;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> initialize() async {
    _logger.info('Local Ad Provider initialized (no specific SDK to init).');
  }

  @override
  Future<app_native_ad.NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  }) async {
    if (adType != AdType.native) {
      _logger.warning(
        'LocalAdProvider.loadNativeAd called with incorrect AdType: $adType. '
        'Expected AdType.native.',
      );
      return null;
    }

    if (adId.isEmpty) {
      _logger.warning('No local native ad ID provided.');
      return null;
    }

    _logger.info('Attempting to load local native ad with ID: $adId');

    try {
      final localNativeAd = await _localAdRepository.read(id: adId);

      if (localNativeAd is LocalNativeAd) {
        _logger.info('Local native ad loaded successfully: ${localNativeAd.id}');
        return app_native_ad.NativeAd(
          id: _uuid.v4(),
          provider: AdPlatformType.local, // Changed from app_native_ad.AdProviderType.local
          adObject: localNativeAd,
          templateType: app_native_ad.NativeAdTemplateType.medium, // Default for local native
        );
      } else {
        _logger.warning(
          'Fetched ad with ID $adId is not a LocalNativeAd. '
          'Received type: ${localNativeAd.runtimeType}',
        );
        return null;
      }
    } on HttpException catch (e) {
      _logger.severe('Error fetching local native ad with ID $adId: $e');
      return null;
    } catch (e, s) {
      _logger.severe(
        'Unexpected error loading local native ad with ID $adId: $e',
        e,
        s,
      );
      return null;
    }
  }

  @override
  Future<app_native_ad.NativeAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  }) async {
    if (adType != AdType.banner) {
      _logger.warning(
        'LocalAdProvider.loadBannerAd called with incorrect AdType: $adType. '
        'Expected AdType.banner.',
      );
      return null;
    }

    if (adId.isEmpty) {
      _logger.warning('No local banner ad ID provided.');
      return null;
    }

    _logger.info('Attempting to load local banner ad with ID: $adId');

    try {
      final localBannerAd = await _localAdRepository.read(id: adId);

      if (localBannerAd is LocalBannerAd) {
        _logger.info('Local banner ad loaded successfully: ${localBannerAd.id}');
        return app_native_ad.NativeAd(
          id: _uuid.v4(),
          provider: AdPlatformType.local, // Changed from app_native_ad.AdProviderType.local
          adObject: localBannerAd,
          templateType: app_native_ad.NativeAdTemplateType.small, // Default for local banner
        );
      } else {
        _logger.warning(
          'Fetched ad with ID $adId is not a LocalBannerAd. '
          'Received type: ${localBannerAd.runtimeType}',
        );
        return null;
      }
    } on HttpException catch (e) {
      _logger.severe('Error fetching local banner ad with ID $adId: $e');
      return null;
    } catch (e, s) {
      _logger.severe(
        'Unexpected error loading local banner ad with ID $adId: $e',
        e,
        s,
      );
      return null;
    }
  }
}
