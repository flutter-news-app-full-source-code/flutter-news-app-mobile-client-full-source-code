import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/banner_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/admob_inline_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/demo_banner_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/demo_native_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_banner_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_native_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template feed_ad_loader_widget}
/// A self-contained widget responsible for loading and displaying an inline ad
/// specifically within content feeds (e.g., main feed, search results).
///
/// This widget handles the entire lifecycle of a single ad slot in the feed.
/// It attempts to retrieve a cached [InlineAd] first. If no ad is cached,
/// it requests a new one from the [AdService] using `getFeedAd` and stores
/// it in the cache upon success. It manages its own loading and error states.
///
/// This approach decouples ad loading from the BLoC and ensures that native
/// ad resources are managed efficiently, preventing crashes and improving
/// scrolling performance in lists. It specifically handles inline ads (native
/// and banner), while interstitial ads are managed separately.
/// {@endtemplate}
class FeedAdLoaderWidget extends StatefulWidget {
  /// {@macro feed_ad_loader_widget}
  const FeedAdLoaderWidget({
    required this.adPlaceholder,
    required this.adService,
    required this.adThemeStyle,
    required this.adConfig,
    super.key,
  });

  /// The stateless placeholder representing this ad slot.
  final AdPlaceholder adPlaceholder;

  /// The service responsible for loading ads from ad networks.
  final AdService adService;

  /// The current theme style for ads, used during ad loading.
  final AdThemeStyle adThemeStyle;

  /// The full remote configuration for ads, used to determine ad loading rules.
  final AdConfig adConfig;

  @override
  State<FeedAdLoaderWidget> createState() => _FeedAdLoaderWidgetState();
}

class _FeedAdLoaderWidgetState extends State<FeedAdLoaderWidget> {
  InlineAd? _loadedAd;
  bool _isLoading = true;
  bool _hasError = false;
  final Logger _logger = Logger('FeedAdLoaderWidget');
  final InlineAdCacheService _adCacheService = InlineAdCacheService();

  /// Completer to manage the lifecycle of the ad loading future.
  /// This helps in cancelling pending operations if the widget is disposed
  /// or updated, preventing `setState` calls on an unmounted widget
  /// and avoiding `StateError` from completing a completer multiple times.
  Completer<void>? _loadAdCompleter;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void didUpdateWidget(covariant FeedAdLoaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the adPlaceholder ID changes, it means this widget is being reused
    // for a different ad slot. We need to cancel any ongoing load for the old
    // ad and initiate a new load for the new ad.
    // Also, if the adConfig changes, we should re-evaluate and potentially reload.
    if (widget.adPlaceholder.id != oldWidget.adPlaceholder.id ||
        widget.adConfig != oldWidget.adConfig) {
      _logger.info(
        'FeedAdLoaderWidget updated for new placeholder ID: ' // Renamed log
        '${widget.adPlaceholder.id} or AdConfig changed. Re-loading ad.',
      );
      // Cancel the previous loading operation if it's still active and not yet
      // completed. This prevents a race condition if a new load is triggered
      // while an old one is still in progress.
      if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
        _loadAdCompleter?.completeError(
          StateError(
            'Ad loading cancelled: Widget updated with new ID or config.',
          ),
        );
      }
      _loadAdCompleter = null;

      // Immediately set the widget to a loading state to prevent UI flicker.
      // This ensures a smooth transition from the old ad (or no ad) to the
      // loading indicator for the new ad.
      setState(() {
        _loadedAd = null;
        _isLoading = true;
        _hasError = false;
      });
      _loadAd();
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

  /// Loads the inline ad for this feed slot.
  ///
  /// This method first checks the [InlineAdCacheService] for a pre-loaded [InlineAd].
  /// If found, it uses the cached ad. Otherwise, it requests a new inline ad
  /// from the [AdService] using `getFeedAd` and stores it in the cache
  /// upon success.
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
        'Using cached ad for feed placeholder ID: ${widget.adPlaceholder.id}', // Renamed log
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
        _loadAdCompleter!.complete();
      }
      return;
    }

    _logger.info(
      'Loading new ad for feed placeholder ID: ${widget.adPlaceholder.id}', // Renamed log
    );
    try {
      // The adId is now directly available from the placeholder.
      final adIdentifier = widget.adPlaceholder.adId;

      if (adIdentifier == null || adIdentifier.isEmpty) {
        _logger.warning(
          'Ad placeholder ID ${widget.adPlaceholder.id} has no adIdentifier. '
          'Cannot load ad.',
        );
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter?.completeError(
            StateError('Failed to load ad: No ad identifier.'),
          );
        }
        return;
      }

      // Get the current HeadlineImageStyle from AppBloc
      final headlineImageStyle = context
          .read<AppBloc>()
          .state
          .settings
          .feedPreferences
          .headlineImageStyle;

      // Call AdService.getFeedAd with the full AdConfig and adType from the placeholder.
      final loadedAd = await widget.adService.getFeedAd(
        adConfig: widget.adConfig, // Pass the full AdConfig
        adType: widget.adPlaceholder.adType,
        adThemeStyle: widget.adThemeStyle,
        headlineImageStyle: headlineImageStyle, // Pass the headlineImageStyle
      );

      if (loadedAd != null) {
        _logger.info(
          'New ad loaded for feed placeholder ID: ${widget.adPlaceholder.id}', // Renamed log
        );
        // Store the newly loaded ad in the cache.
        _adCacheService.setAd(widget.adPlaceholder.id, loadedAd);
        // Ensure the widget is still mounted before calling setState.
        if (!mounted) return;
        setState(() {
          _loadedAd = loadedAd;
          _isLoading = false;
        });
        // Complete the completer only if it hasn't been completed already.
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter!.complete();
        }
      } else {
        _logger.warning(
          'Failed to load ad for feed placeholder ID: ${widget.adPlaceholder.id}. ' // Renamed log
          'No ad returned.',
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
          );
        }
      }
    } catch (e, s) {
      _logger.severe(
        'Error loading ad for feed placeholder ID: ${widget.adPlaceholder.id}: $e', // Renamed log
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
        _loadAdCompleter?.completeError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headlineImageStyle = context
        .read<AppBloc>()
        .state
        .settings
        .feedPreferences
        .headlineImageStyle;

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
      // Fallback for unsupported ad types or errors
      return const SizedBox.shrink();
    } else {
      // If an ad is successfully loaded, dispatch to the appropriate
      // provider-specific widget for rendering.
      switch (_loadedAd!.provider) {
        case AdPlatformType.admob:
          return AdmobInlineAdWidget(
            inlineAd: _loadedAd!,
            headlineImageStyle: headlineImageStyle,
          );
        case AdPlatformType.local:
          if (_loadedAd is NativeAd && _loadedAd!.adObject is LocalNativeAd) {
            return LocalNativeAdWidget(
              localNativeAd: _loadedAd!.adObject as LocalNativeAd,
              headlineImageStyle: headlineImageStyle,
            );
          } else if (_loadedAd is BannerAd &&
              _loadedAd!.adObject is LocalBannerAd) {
            return LocalBannerAdWidget(
              localBannerAd: _loadedAd!.adObject as LocalBannerAd,
              headlineImageStyle: headlineImageStyle,
            );
          }
          // Fallback for unsupported local ad types or errors
          return const SizedBox.shrink();
        case AdPlatformType.demo:
          // In demo environment, display placeholder ads directly.
          switch (widget.adPlaceholder.adType) {
            case AdType.native:
              return DemoNativeAdWidget(headlineImageStyle: headlineImageStyle);
            case AdType.banner:
              return DemoBannerAdWidget(headlineImageStyle: headlineImageStyle);
            case AdType.interstitial:
            case AdType.video:
              // Interstitial and video ads are not inline, so they won't be
              // handled by FeedAdLoaderWidget. Fallback to a generic placeholder.
              return const SizedBox.shrink();
          }
      }
    }
  }
}
