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
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_banner_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/local_native_ad_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
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
///
/// **AdMob In-Article Ad Handling:**
/// For AdMob in-article ads, this widget intentionally bypasses the
/// [InlineAdCacheService]. This is a critical design decision to prevent
/// the "AdWidget is already in the Widget tree" error that occurs when
/// navigating between multiple article detail pages. Each AdMob in-article
/// ad will be loaded as a new instance, ensuring unique `admob.Ad` objects
/// for each `AdmobInlineAdWidget` in the widget tree.
/// {@endtemplate}
class InArticleAdLoaderWidget extends StatefulWidget {
  /// {@macro in_article_ad_loader_widget}
  const InArticleAdLoaderWidget({
    required this.slotConfiguration,
    required this.adThemeStyle,
    required this.adConfig,
    super.key,
  });

  /// The configuration for this specific in-article ad slot.
  final InArticleAdSlotConfiguration slotConfiguration;

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
  late final InlineAdCacheService _adCacheService;
  late final AdService
  _adService; // AdService will be accessed via _adCacheService

  Completer<void>? _loadAdCompleter;

  @override
  void initState() {
    super.initState();
    _adCacheService = context.read<InlineAdCacheService>();
    _adService = context.read<AdService>();
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
      // Dispose of the old ad's resources before loading a new one.
      final oldCacheKey =
          'in_article_ad_${oldWidget.slotConfiguration.slotType.name}';
      // Only dispose if it was actually cached (i.e., not an AdMob in-article ad).
      // The removeAndDisposeAd method handles the check internally.
      _adCacheService.removeAndDisposeAd(oldCacheKey);

      if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
        _loadAdCompleter!.complete(); // Complete normally to prevent crashes
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
    // Dispose of the ad's resources when the widget is permanently removed.
    final cacheKey = 'in_article_ad_${widget.slotConfiguration.slotType.name}';
    // Only dispose if it was actually cached (i.e., not an AdMob in-article ad).
    // The removeAndDisposeAd method handles the check internally.
    _adCacheService.removeAndDisposeAd(cacheKey);

    if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
      _loadAdCompleter!.complete(); // Complete normally to prevent crashes
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
  ///
  /// **AdMob Specific Behavior:**
  /// For AdMob in-article ads, this method intentionally bypasses the cache.
  /// This ensures that each `AdmobInlineAdWidget` receives a unique `admob.Ad`
  /// object, preventing the "AdWidget is already in the Widget tree" error
  /// when multiple article detail pages are in the navigation stack.
  Future<void> _loadAd() async {
    _loadAdCompleter = Completer<void>();

    if (!mounted) return;

    // In-article ads are typically unique to their slot, so we use the slotType
    // as part of the cache key to differentiate them.
    final cacheKey = 'in_article_ad_${widget.slotConfiguration.slotType.name}';
    InlineAd? loadedAd;

    // Determine if the primary ad platform is AdMob.
    final isAdMob = widget.adConfig.primaryAdPlatform == AdPlatformType.admob;

    if (!isAdMob) {
      // For non-AdMob platforms (e.g., Local, Demo), try to get from cache.
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
    } else {
      _logger.info(
        'AdMob is primary ad platform. Bypassing cache for in-article ad '
        'for slot: ${widget.slotConfiguration.slotType.name}.',
      );
    }

    _logger.info(
      'Loading new in-article ad for slot: ${widget.slotConfiguration.slotType.name}',
    );
    try {
      // Call AdService.getInArticleAd with the full AdConfig.
      loadedAd = await _adService.getInArticleAd(
        adConfig: widget.adConfig,
        adThemeStyle: widget.adThemeStyle,
      );

      if (loadedAd != null) {
        _logger.info(
          'New in-article ad loaded for slot: ${widget.slotConfiguration.slotType.name}',
        );
        // Only cache non-AdMob ads. AdMob ads are not cached to prevent reuse issues.
        if (!isAdMob) {
          _adCacheService.setAd(cacheKey, loadedAd);
        } else {
          _logger.info(
            'AdMob in-article ad not cached to prevent reuse issues.',
          );
        }

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
        // Complete the completer normally, indicating that loading finished
        // but no ad was available. This prevents crashes.
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter!.complete();
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
      // Complete the completer normally, indicating that loading finished
      // but an error occurred. This prevents crashes.
      if (_loadAdCompleter?.isCompleted == false) {
        _loadAdCompleter!.complete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final headlineImageStyle = context.read<AppBloc>().state.headlineImageStyle;

    if (_isLoading || _hasError || _loadedAd == null) {
      // Show a user-friendly message when loading, on error, or if no ad is loaded.
      return Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMedium,
          vertical: AppSpacing.xs,
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingMedium,
            ),
            child: Center(
              child: Text(
                l10n.adInfoPlaceholderText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    } else {
      // If an ad is successfully loaded, dispatch to the appropriate
      // provider-specific widget for rendering.
      switch (_loadedAd!.provider) {
        case AdPlatformType.admob:
          return AdmobInlineAdWidget(
            inlineAd: _loadedAd!,
            headlineImageStyle: headlineImageStyle,
            bannerAdShape: widget.adConfig.articleAdConfiguration.bannerAdShape,
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
              bannerAdShape:
                  widget.adConfig.articleAdConfiguration.bannerAdShape,
            );
          }
          // Fallback for unsupported local ad types or errors
          return const SizedBox.shrink();
        case AdPlatformType.demo:
          // In demo environment, display placeholder ads directly.
          // In-article ads are now always banners, so we use DemoBannerAdWidget.
          return DemoBannerAdWidget(
            bannerAdShape: widget.adConfig.articleAdConfiguration.bannerAdShape,
          );
      }
    }
  }
}
