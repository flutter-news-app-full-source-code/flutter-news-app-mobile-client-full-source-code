import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
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
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template in_article_ad_loader_widget}
/// A self-contained widget responsible for loading and displaying an in-article ad.
///
/// This widget handles the entire lifecycle of a single in-article ad slot.
/// It attempts to retrieve a cached [InlineAd] first. If no ad is cached,
/// it requests a new one from the [AdService] using `getInArticleAd` and stores
/// it in the cache upon success. It manages its own loading and error states.
///
/// This approach decouples ad loading from the BLoC and ensures that native
/// ad resources are managed efficiently, preventing crashes and improving
/// scrolling performance in lists.
/// {@endtemplate}
class InArticleAdLoaderWidget extends StatefulWidget {
  /// {@macro in_article_ad_loader_widget}
  const InArticleAdLoaderWidget({
    required this.slotConfiguration,
    required this.adService,
    required this.adThemeStyle,
    required this.adConfig,
    super.key,
  });

  /// The configuration for this specific in-article ad slot.
  final InArticleAdSlotConfiguration slotConfiguration;

  /// The service responsible for loading ads from ad networks.
  final AdService adService;

  /// The current theme style for ads, used during ad loading.
  final AdThemeStyle adThemeStyle;

  /// The full remote configuration for ads, used to determine ad loading rules.
  final AdConfig adConfig;

  @override
  State<InArticleAdLoaderWidget> createState() =>
      _InArticleAdLoaderWidgetState();
}

class _InArticleAdLoaderWidgetState extends State<InArticleAdLoaderWidget> {
  InlineAd? _loadedAd;
  bool _isLoading = true;
  bool _hasError = false;
  final Logger _logger = Logger('InArticleAdLoaderWidget');
  final InlineAdCacheService _adCacheService = InlineAdCacheService();

  Completer<void>? _loadAdCompleter;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void didUpdateWidget(covariant InArticleAdLoaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the slotConfiguration changes, it means this widget is being reused
    // for a different ad slot. We need to cancel any ongoing load for the old
    // ad and initiate a new load for the new ad.
    // Also, if the adConfig changes, we should re-evaluate and potentially reload.
    if (widget.slotConfiguration != oldWidget.slotConfiguration ||
        widget.adConfig != oldWidget.adConfig) {
      _logger.info(
        'InArticleAdLoaderWidget updated for new slot configuration or AdConfig changed. Re-loading ad.',
      );
      if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
        _loadAdCompleter?.completeError(
          StateError('Ad loading cancelled: Widget updated with new config.'),
        );
      }
      _loadAdCompleter = null;

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
    if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
      _loadAdCompleter?.completeError(
        StateError('Ad loading cancelled: Widget disposed.'),
      );
    }
    _loadAdCompleter = null;
    super.dispose();
  }

  /// Loads the in-article ad for this slot.
  ///
  /// This method first checks the [InlineAdCacheService] for a pre-loaded [InlineAd].
  /// If found, it uses the cached ad. Otherwise, it requests a new in-article ad
  /// from the [AdService] using `getInArticleAd` and stores it in the cache
  /// upon success.
  Future<void> _loadAd() async {
    _loadAdCompleter = Completer<void>();

    if (!mounted) return;

    // In-article ads are typically unique to their slot, so we use the slotType
    // as part of the cache key to differentiate them.
    final cacheKey = 'in_article_ad_${widget.slotConfiguration.slotType.name}';
    final cachedAd = _adCacheService.getAd(cacheKey);

    if (cachedAd != null) {
      _logger.info(
        'Using cached in-article ad for slot: ${widget.slotConfiguration.slotType.name}',
      );
      if (!mounted) return;
      setState(() {
        _loadedAd = cachedAd;
        _isLoading = false;
      });
      if (_loadAdCompleter?.isCompleted == false) {
        _loadAdCompleter!.complete();
      }
      return;
    }

    _logger.info(
      'Loading new in-article ad for slot: ${widget.slotConfiguration.slotType.name}',
    );
    try {
      // Get the current HeadlineImageStyle from AppBloc
      final headlineImageStyle = context
          .read<AppBloc>()
          .state
          .settings
          .feedPreferences
          .headlineImageStyle;

      // Call AdService.getInArticleAd with the full AdConfig.
      final loadedAd = await widget.adService.getInArticleAd(
        adConfig: widget.adConfig,
        adThemeStyle: widget.adThemeStyle,
        headlineImageStyle: headlineImageStyle, // Pass the headlineImageStyle
      );

      if (loadedAd != null) {
        _logger.info(
          'New in-article ad loaded for slot: ${widget.slotConfiguration.slotType.name}',
        );
        _adCacheService.setAd(cacheKey, loadedAd);
        if (!mounted) return;
        setState(() {
          _loadedAd = loadedAd;
          _isLoading = false;
        });
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter!.complete();
        }
      } else {
        _logger.warning(
          'Failed to load in-article ad for slot: ${widget.slotConfiguration.slotType.name}. '
          'No ad returned.',
        );
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter?.completeError(
            StateError('Failed to load in-article ad: No ad returned.'),
          );
        }
      }
    } catch (e, s) {
      _logger.severe(
        'Error loading in-article ad for slot: ${widget.slotConfiguration.slotType.name}: $e',
        e,
        s,
      );
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      if (_loadAdCompleter?.isCompleted == false) {
        _loadAdCompleter?.completeError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appEnvironment = context.read<AppBloc>().state.environment;
    final headlineImageStyle = context
        .read<AppBloc>()
        .state
        .settings
        .feedPreferences
        .headlineImageStyle;

    // In demo environment, display placeholder ads directly.
    if (appEnvironment == AppEnvironment.demo) {
      // Determine the ad type from the adConfig's articleAdConfiguration
      final adType =
          widget.adConfig.articleAdConfiguration.defaultInArticleAdType;
      switch (adType) {
        case AdType.native:
          return DemoNativeAdWidget(headlineImageStyle: headlineImageStyle);
        case AdType.banner:
          return DemoBannerAdWidget(headlineImageStyle: headlineImageStyle);
        case AdType.interstitial:
        case AdType.video:
          // Interstitial and video ads are not inline, so they won't be
          // handled by InArticleAdLoaderWidget. Fallback to a generic placeholder.
          return const SizedBox.shrink();
      }
    }

    // For other environments (development, production), proceed with real ad loading.
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMedium,
          vertical: AppSpacing.xs,
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Card(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    } else if (_hasError || _loadedAd == null) {
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
      }
    }
  }
}
