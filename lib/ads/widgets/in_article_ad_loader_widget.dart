import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
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
/// A self-contained, stateful widget that manages the entire lifecycle
/// of a single in-article ad slot.
///
/// This widget is designed to be robust and efficient. It fetches an
/// [InlineAd] from the [AdService] in its `initState` method and
/// stores it in its own local state. Crucially, it is responsible
/// for disposing of the loaded ad's resources in its `dispose` method.
///
/// This approach ensures that the ad's lifecycle is tightly coupled
/// with the widget's lifecycle, preventing ad cache collisions when
/// multiple instances of the same article page are in the navigation
/// stack. It also ensures proper resource cleanup when the widget
/// is removed from the widget tree.
/// {@endtemplate}
class InArticleAdLoaderWidget extends StatefulWidget {
  /// {@macro in_article_ad_loader_widget}
  const InArticleAdLoaderWidget({
    required this.slotType,
    required this.adThemeStyle,
    required this.adConfig,
    super.key,
  });

  /// The type of the in-article ad slot.
  final InArticleAdSlotType slotType;

  /// The current theme style for ads, used during ad loading.
  final AdThemeStyle adThemeStyle;

  /// The full remote configuration for ads, used to determine ad loading rules.
  final AdConfig adConfig;

  @override
  State<InArticleAdLoaderWidget> createState() =>
      _InArticleAdLoaderWidgetState();
}

class _InArticleAdLoaderWidgetState extends State<InArticleAdLoaderWidget> {
  /// The currently loaded inline ad object.
  /// This is managed entirely by this widget's state.
  InlineAd? _loadedAd;
  bool _isLoading = true;
  bool _hasError = false;
  final Logger _logger = Logger('InArticleAdLoaderWidget');
  late final AdService _adService;

  Completer<void>? _loadAdCompleter;

  @override
  void initState() {
    super.initState();
    // AdService is used to fetch new ads and dispose of them.
    _adService = context.read<AdService>();
    _loadAd();
  }

  @override
  void didUpdateWidget(covariant InArticleAdLoaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the slotType or adConfig changes, it means this widget is
    // being reused for a different ad slot or its configuration has
    // been updated. We need to cancel any ongoing load for the old ad
    // and initiate a new load for the new ad.
    // Also, if the adConfig changes, we should re-evaluate and potentially
    // reload.
    if (widget.slotType != oldWidget.slotType ||
        widget.adConfig != oldWidget.adConfig) {
      _logger.info(
        'InArticleAdLoaderWidget updated for new slot type: '
        '${widget.slotType.name} or adConfig changed. Re-loading ad.',
      );

      // Cancel the previous loading operation if it's still active and not yet
      // completed. This prevents a race condition if a new load is triggered.
      if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
        // Complete normally to prevent crashes
        _loadAdCompleter!.complete();
      }
      _loadAdCompleter = null;

      // If an ad was previously loaded, dispose of its resources
      // immediately as this widget is now responsible for its lifecycle.
      if (_loadedAd != null) {
        _logger.info(
          'Disposing old ad for slot "${oldWidget.slotType.name}" '
          'before loading new one.',
        );
        _adService.disposeAd(_loadedAd!);
      }

      // Immediately set the widget to a loading state to prevent UI flicker.
      // This ensures a smooth transition from the old ad (or no ad) to the
      // loading indicator for the new ad.
      if (mounted) {
        setState(() {
          _loadedAd = null;
          _isLoading = true;
          _hasError = false;
        });
      }
      _loadAd();
    }
  }

  @override
  void dispose() {
    // The ad object (_loadedAd) is managed by this widget.
    // Therefore, its resources MUST be explicitly disposed of here
    // when the widget is removed from the widget tree to prevent
    // memory leaks.
    if (_loadedAd != null) {
      _logger.info(
        'Disposing in-article ad for slot "${widget.slotType.name}" '
        'as widget is being disposed.',
      );
      _adService.disposeAd(_loadedAd!);
    }

    // Cancel any pending ad loading operation when the widget is disposed.
    // This prevents `setState()` calls on a disposed widget.
    if (_loadAdCompleter != null && !_loadAdCompleter!.isCompleted) {
      // Complete normally to prevent crashes
      _loadAdCompleter!.complete();
    }
    _loadAdCompleter = null;
    super.dispose();
  }

  /// Loads the in-article ad for this slot.
  ///
  /// This method directly requests a new in-article ad from the
  /// [AdService] using `getInArticleAd`. It stores the loaded ad in
  /// its local state (`_loadedAd`). This widget does not use an
  /// external cache for its ads; its lifecycle is entirely self-managed.
  ///
  /// It also includes defensive checks (`mounted`) to prevent `setState` calls
  /// on disposed widgets and ensures the `_loadAdCompleter` is always
  /// completed to prevent `StateError`s.
  Future<void> _loadAd() async {
    // Initialize a new completer for this loading operation.
    _loadAdCompleter = Completer<void>();

    // Ensure the widget is still mounted before proceeding.
    // This prevents the "setState() called after dispose()" error.
    if (!mounted) {
      if (_loadAdCompleter?.isCompleted == false) {
        _loadAdCompleter!.complete();
      }
      return;
    }

    _logger.info('Loading new in-article ad for slot: ${widget.slotType.name}');
    try {
      // Get the current user role from AppBloc
      final appBlocState = context.read<AppBloc>().state;
      final userRole = appBlocState.user?.appRole ?? AppUserRole.guestUser;

      // Call AdService.getInArticleAd with the full AdConfig.
      final loadedAd = await _adService.getInArticleAd(
        adConfig: widget.adConfig,
        adThemeStyle: widget.adThemeStyle,
        userRole: userRole,
        slotType: widget.slotType,
      );

      if (loadedAd != null) {
        _logger.info(
          'New in-article ad loaded for slot: ${widget.slotType.name}',
        );
        if (mounted) {
          setState(() {
            _loadedAd = loadedAd;
            _isLoading = false;
          });
        }
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter!.complete();
        }
      } else {
        _logger.warning(
          'Failed to load in-article ad for slot: ${widget.slotType.name}. '
          'No ad returned.',
        );
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        if (_loadAdCompleter?.isCompleted == false) {
          _loadAdCompleter!.complete();
        }
      }
    } catch (e, s) {
      _logger.severe(
        'Error loading in-article ad for slot: ${widget.slotType.name}: $e',
        e,
        s,
      );
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
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
      // Show a user-friendly message when loading, on error, or if no ad is
      // loaded.
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
