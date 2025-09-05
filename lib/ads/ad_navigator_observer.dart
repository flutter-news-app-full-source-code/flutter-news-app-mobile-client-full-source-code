import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:logging/logging.dart';

/// {@template ad_navigator_observer}
/// A [NavigatorObserver] that listens to route changes and triggers
/// interstitial ad display based on [RemoteConfig] settings.
///
/// This observer is responsible for:
/// 1. Tracking page transitions to determine when an interstitial ad should be shown.
/// 2. Requesting an interstitial ad from the [AdService] when the criteria are met.
/// 3. Showing the interstitial ad to the user.
///
/// It interacts with the [AppBloc] to get the current [RemoteConfig] and
/// user's ad frequency settings, and to dispatch events for page transitions.
/// {@endtemplate}
class AdNavigatorObserver extends NavigatorObserver {
  /// {@macro ad_navigator_observer}
  AdNavigatorObserver({
    required this.appBloc,
    required this.adService,
    Logger? logger,
  }) : _logger = logger ?? Logger('AdNavigatorObserver');

  final AppBloc appBloc;
  final AdService adService;
  final Logger _logger;

  /// Tracks the number of page transitions since the last interstitial ad was shown.
  /// This is managed by the AppBloc.

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logger.info('Route pushed: ${route.settings.name}');
    _handlePageTransition();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logger.info('Route popped: ${route.settings.name}');
    _handlePageTransition();
  }

  /// Handles a page transition event.
  ///
  /// Dispatches an [AppPageTransitioned] event to the [AppBloc] to update
  /// the transition count and potentially trigger an interstitial ad.
  void _handlePageTransition() {
    // Only consider actual page routes, not overlays or dialogs.
    // This check is a simplification; a more robust solution might inspect
    // route types or use GoRouter's specific navigation events.
    if (navigator?.currentRoutes.last.settings.name != null) {
      appBloc.add(const AppPageTransitioned());
    }
  }

  /// Requests and shows an interstitial ad if conditions are met.
  ///
  /// This method is called by the [AppBloc] when it determines an ad is due.
  Future<void> showInterstitialAd() async {
    final remoteConfig = appBloc.state.remoteConfig;
    final user = appBloc.state.user;

    if (remoteConfig == null || !remoteConfig.adConfig.enabled) {
      _logger.info('Interstitial ads disabled or remote config not available.');
      return;
    }

    final adConfig = remoteConfig.adConfig;
    final interstitialConfig = adConfig.interstitialAdConfiguration;

    if (!interstitialConfig.enabled) {
      _logger.info('Interstitial ads are specifically disabled in config.');
      return;
    }

    // Create AdThemeStyle from current theme for ad loading.
    // This requires a BuildContext, which is not directly available here.
    // The AppBloc will need to provide the AdThemeStyle or the AdService
    // will need to be able to create it. For now, we'll assume a default
    // or that the AdService can handle it.
    //
    // TODO(fulleni): Revisit how AdThemeStyle is passed for interstitial ads.
    // For now, a placeholder AdThemeStyle is used.
    final adThemeStyle = AdThemeStyle.fromTheme(ThemeData());

    _logger.info('Attempting to load interstitial ad...');
    final interstitialAd = await adService.getInterstitialAd(
      adConfig: adConfig,
      adThemeStyle: adThemeStyle,
    );

    if (interstitialAd != null) {
      _logger.info('Interstitial ad loaded. Showing...');
      // Show the AdMob interstitial ad.
      if (interstitialAd.provider == AdPlatformType.admob &&
          interstitialAd.adObject is admob.InterstitialAd) {
        final admobInterstitialAd =
            interstitialAd.adObject as admob.InterstitialAd;
        admobInterstitialAd.fullScreenContentCallback =
            admob.FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            _logger.info('Interstitial Ad dismissed.');
            ad.dispose();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            _logger.severe('Interstitial Ad failed to show: $error');
            ad.dispose();
          },
          onAdShowedFullScreenContent: (ad) {
            _logger.info('Interstitial Ad showed.');
          },
        );
        await admobInterstitialAd.show();
      } else if (interstitialAd.provider == AdPlatformType.local &&
          interstitialAd.adObject is LocalInterstitialAd) {
        // TODO(fulleni): Implement showing local interstitial ad (e.g., via a dialog).
        _logger.info('Showing local interstitial ad (placeholder).');
      }
    } else {
      _logger.info('No interstitial ad loaded.');
    }
  }
}
