import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/admob_native_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/placeholder_ad_widget.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template ad_loader_widget}
/// A self-contained widget responsible for loading and displaying a native ad.
///
/// This widget handles the entire lifecycle of a single ad slot in the feed.
/// It attempts to retrieve a cached ad first. If no ad is cached, it requests
/// a new one from the [AdService]. It manages its own loading and error states.
///
/// This approach decouples ad loading from the BLoC and ensures that native
/// ad resources are managed efficiently, preventing crashes and improving
/// scrolling performance in lists.
/// {@endtemplate}
class AdLoaderWidget extends StatefulWidget {
  /// {@macro ad_loader_widget}
  const AdLoaderWidget({
    required this.adPlaceholder,
    required this.adService,
    required this.adThemeStyle,
    super.key,
  });

  /// The stateless placeholder representing this ad slot.
  final AdPlaceholder adPlaceholder;

  /// The service responsible for loading ads from ad networks.
  final AdService adService;

  /// The current theme style for ads, used during ad loading.
  final AdThemeStyle adThemeStyle;

  @override
  State<AdLoaderWidget> createState() => _AdLoaderWidgetState();
}

class _AdLoaderWidgetState extends State<AdLoaderWidget> {
  NativeAd? _loadedAd;
  bool _isLoading = true;
  bool _hasError = false;
  final Logger _logger = Logger('AdLoaderWidget');
  final AdCacheService _adCacheService = AdCacheService();

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  /// Loads the native ad for this slot.
  ///
  /// This method first checks the [AdCacheService] for a pre-loaded ad.
  /// If found, it uses the cached ad. Otherwise, it requests a new ad
  /// from the [AdService] and stores it in the cache upon success.
  Future<void> _loadAd() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Attempt to retrieve the ad from the cache first.
    final cachedAd = _adCacheService.getAd(widget.adPlaceholder.id);

    if (cachedAd != null) {
      _logger.info('Using cached ad for placeholder ID: ${widget.adPlaceholder.id}');
      setState(() {
        _loadedAd = cachedAd;
        _isLoading = false;
      });
      return;
    }

    _logger.info('Loading new ad for placeholder ID: ${widget.adPlaceholder.id}');
    try {
      // Request a new native ad from the AdService.
      // The imageStyle is hardcoded to largeThumbnail for now, but could be
      // made configurable based on the feed's display preferences.
      final adFeedItem = await widget.adService.getAd(
        imageStyle: HeadlineImageStyle.largeThumbnail,
        adThemeStyle: widget.adThemeStyle,
      );

      if (adFeedItem != null) {
        _logger.info('New ad loaded for placeholder ID: ${widget.adPlaceholder.id}');
        // Store the newly loaded ad in the cache.
        _adCacheService.setAd(widget.adPlaceholder.id, adFeedItem.nativeAd);
        setState(() {
          _loadedAd = adFeedItem.nativeAd;
          _isLoading = false;
        });
      } else {
        _logger.warning('Failed to load ad for placeholder ID: ${widget.adPlaceholder.id}. No ad returned.');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      _logger.severe(
        'Error loading ad for placeholder ID: ${widget.adPlaceholder.id}: $e',
        e,
        s,
      );
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a shimmer or loading indicator while the ad is being loaded.
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMedium,
          vertical: AppSpacing.xs,
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9, // Common aspect ratio for ads
          child: Card(
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    } else if (_hasError || _loadedAd == null) {
      // Show a placeholder or error message if ad loading failed.
      return const PlaceholderAdWidget();
    } else {
      // If an ad is successfully loaded, display it using the appropriate widget.
      // The AdmobNativeAdWidget is responsible for rendering the native ad object.
      return AdmobNativeAdWidget(nativeAd: _loadedAd!);
    }
  }
}
