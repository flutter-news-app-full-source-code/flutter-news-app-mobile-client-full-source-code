import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_feed_item.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/ad_feed_item_widget.dart';
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

  // Completer to manage the lifecycle of the ad loading future.
  // This helps in cancelling pending operations if the widget is disposed
  // or updated, preventing `setState` calls on an unmounted widget
  // and avoiding `StateError` from completing a completer multiple times.
  Completer<void>? _loadAdCompleter;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void didUpdateWidget(covariant AdLoaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the adPlaceholder ID changes, it means this widget is being reused
    // for a different ad slot. We need to cancel any ongoing load for the old
    // ad and initiate a new load for the new ad.
    if (widget.adPlaceholder.id != oldWidget.adPlaceholder.id) {
      _logger.info(
        'AdLoaderWidget updated for new placeholder ID: '
        '${widget.adPlaceholder.id}. Re-loading ad.',
      );
      // Cancel the previous loading operation if it's still active and not yet
      // completed. This prevents a race condition if a new load is triggered
      // while an old one is still in progress.
      if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
        _loadAdCompleter?.completeError(
          StateError('Ad loading cancelled: Widget updated with new ID.'),
        );
      }
      _loadAdCompleter = null; // Clear the old completer for the new load

      // Immediately set the widget to a loading state to prevent UI flicker.
      // This ensures a smooth transition from the old ad (or no ad) to the
      // loading indicator for the new ad.
      setState(() {
        _loadedAd = null;
        _isLoading = true;
        _hasError = false;
      });
      _loadAd(); // Start loading the new ad
    }
  }

  @override
  void dispose() {
    // Cancel any pending ad loading operation when the widget is disposed.
    // This prevents `setState()` calls on a disposed widget.
    // Ensure the completer is not already completed before attempting to complete it.
    if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
      _loadAdCompleter?.completeError(
        StateError('Ad loading cancelled: Widget disposed.'),
      );
    }
    _loadAdCompleter = null;
    super.dispose();
  }

  /// Loads the native ad for this slot.
  ///
  /// This method first checks the [AdCacheService] for a pre-loaded ad.
  /// If found, it uses the cached ad. Otherwise, it requests a new ad
  /// from the [AdService] and stores it in the cache upon success.
  Future<void> _loadAd() async {
    // Initialize a new completer for this loading operation.
    _loadAdCompleter = Completer<void>();

    // Ensure the widget is still mounted before calling setState.
    // This prevents the "setState() called after dispose()" error
    // if the widget is removed from the tree while the async operation
    // is still in progress.
    if (!mounted) return;
    // Attempt to retrieve the ad from the cache first.
    final cachedAd = _adCacheService.getAd(widget.adPlaceholder.id);

    if (cachedAd != null) {
      _logger.info(
        'Using cached ad for placeholder ID: ${widget.adPlaceholder.id}',
      );
      // Ensure the widget is still mounted before calling setState.
      if (!mounted) return;
      setState(() {
        _loadedAd = cachedAd;
        _isLoading = false;
      });
      // Complete the completer only if it hasn't been completed already
      // (e.g., by dispose() or didUpdateWidget() cancelling an old load).
      if (_loadAdCompleter?.isCompleted == false) {
        _loadAdCompleter!.complete(); // Complete the completer on success
      }
      return;
    }

    _logger.info(
      'Loading new ad for placeholder ID: ${widget.adPlaceholder.id}',
    );
    try {
      String? currentAdId;
      if (widget.adPlaceholder.adPlatformType == AdPlatformType.admob) {
        currentAdId = widget.adPlaceholder.adUnitId;
      } else if (widget.adPlaceholder.adPlatformType == AdPlatformType.local) {
        currentAdId = widget.adPlaceholder.localAdId;
      }

      final adPlatformIdentifiers = AdPlatformIdentifiers(
        feedNativeAdId: widget.adPlaceholder.adType == AdType.native ? currentAdId : null,
        feedBannerAdId: widget.adPlaceholder.adType == AdType.banner ? currentAdId : null,
        feedToArticleInterstitialAdId: widget.adPlaceholder.adType == AdType.interstitial ? currentAdId : null,
        inArticleNativeAdId: null,
        inArticleBannerAdId: null,
      );

      // Construct a minimal AdConfig for the AdService call
      final adConfig = AdConfig(
        enabled: true, // Assuming ads are enabled if we're trying to load one
        primaryAdPlatform: widget.adPlaceholder.adPlatformType,
        platformAdIdentifiers: {
          widget.adPlaceholder.adPlatformType: adPlatformIdentifiers,
        },
        feedAdConfiguration: FeedAdConfiguration(
          enabled: true, // Assuming feed ads are enabled
          adType: widget.adPlaceholder.adType,
          frequencyConfig: const FeedAdFrequencyConfig(
            guestAdFrequency: 0,
            guestAdPlacementInterval: 0,
            authenticatedAdFrequency: 0,
            authenticatedAdPlacementInterval: 0,
            premiumAdFrequency: 0,
            premiumAdPlacementInterval: 0,
          ),
        ),
        articleAdConfiguration: const ArticleAdConfiguration(
          enabled: false, // Not relevant for feed ads
          defaultInArticleAdType: AdType.native,
          inArticleAdSlotConfigurations: [],
        ),
        interstitialAdConfiguration: const InterstitialAdConfiguration(
          enabled: false, // Not relevant for feed ads
          feedInterstitialAdFrequencyConfig: InterstitialAdFrequencyConfig(
            guestTransitionsBeforeShowingInterstitialAds: 0,
            standardUserTransitionsBeforeShowingInterstitialAds: 0,
            premiumUserTransitionsBeforeShowingInterstitialAds: 0,
          ),
        ),
      );

      final adFeedItem = await widget.adService.getAd(
        adConfig: adConfig,
        adType: widget.adPlaceholder.adType,
        adThemeStyle: widget.adThemeStyle,
      );

      if (adFeedItem != null) {
        _logger.info(
          'New ad loaded for placeholder ID: ${widget.adPlaceholder.id}',
        );
        // Store the newly loaded ad in the cache.
        _adCacheService.setAd(widget.adPlaceholder.id, adFeedItem.nativeAd);
        // Ensure the widget is still mounted before calling setState.
        if (!mounted) return;
        setState(() {
          _loadedAd = adFeedItem.nativeAd;
          _isLoading = false;
        });
        // Complete the completer only if it hasn't been completed already.
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter!.complete(); // Complete the completer on success
        }
      } else {
        _logger.warning(
          'Failed to load ad for placeholder ID: ${widget.adPlaceholder.id}. No ad returned.',
        );
        // Ensure the widget is still mounted before calling setState.
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        // Complete the completer with an error only if it hasn't been completed already.
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter?.completeError(
            StateError('Failed to load ad: No ad returned.'),
          ); // Complete with error
        }
      }
    } catch (e, s) {
      _logger.severe(
        'Error loading ad for placeholder ID: ${widget.adPlaceholder.id}: $e',
        e,
        s,
      );
      // Ensure the widget is still mounted before calling setState.
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      // Complete the completer with an error only if it hasn't been completed already.
      if (_loadAdCompleter?.isCompleted == false) {
        _loadAdCompleter?.completeError(e); // Complete with error
      }
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
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    } else if (_hasError || _loadedAd == null) {
      // Show a placeholder or error message if ad loading failed.
      return const PlaceholderAdWidget();
    } else {
      // If an ad is successfully loaded, wrap it in an AdFeedItem
      // and pass it to the AdFeedItemWidget for rendering.
      // This improves separation of concerns, as AdLoaderWidget is now
      // only responsible for loading, not rendering logic.
      return AdFeedItemWidget(
        adFeedItem: AdFeedItem(
          id: widget.adPlaceholder.id,
          nativeAd: _loadedAd!,
        ),
      );
    }
  }
}
