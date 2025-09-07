import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/widgets.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';

/// A function that provides the current [AppState].
///
/// This is used for dependency injection to decouple the [AdNavigatorObserver]
/// from a direct dependency on the [AppBloc] instance, making it more
/// testable and reusable.
typedef AppStateProvider = AppState Function();

/// {@template ad_navigator_observer}
/// A [NavigatorObserver] that listens to route changes and triggers
/// interstitial ad display based on [RemoteConfig] settings.
///
/// This observer is responsible for:
/// 1. Tracking page transitions to determine when an interstitial ad should be shown.
/// 2. Requesting an interstitial ad from the [AdService] when the criteria are met.
/// 3. Showing the interstitial ad to the user.
///
/// It retrieves the current [AppState] via the [appStateProvider] to get the
/// latest [RemoteConfig] and user's ad frequency settings.
/// {@endtemplate}
class AdNavigatorObserver extends NavigatorObserver {
  /// {@macro ad_navigator_observer}
  AdNavigatorObserver({
    required this.appStateProvider,
    required this.adService,
    required AdThemeStyle adThemeStyle,
    Logger? logger,
  }) : _logger = logger ?? Logger('AdNavigatorObserver'),
       _adThemeStyle = adThemeStyle;

  /// A function that provides the current [AppState].
  final AppStateProvider appStateProvider;

  /// The service responsible for fetching and loading ads.
  final AdService adService;

  final Logger _logger;
  final AdThemeStyle _adThemeStyle;

  /// Tracks the number of page transitions since the last interstitial ad.
  int _pageTransitionCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logger.info('Route pushed: ${route.settings.name}');
    if (route is PageRoute && route.settings.name != null) {
      _handlePageTransition();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logger.info('Route popped: ${route.settings.name}');
    if (route is PageRoute && route.settings.name != null) {
      _handlePageTransition();
    }
  }

  /// Handles a page transition event, checks ad frequency, and shows an ad if needed.
  void _handlePageTransition() {
    _pageTransitionCount++;
    _logger.info('Page transitioned. Current count: $_pageTransitionCount');

    final appState = appStateProvider();
    final remoteConfig = appState.remoteConfig;
    final user = appState.user;

    // Only proceed if remote config is available, ads are globally enabled,
    // and interstitial ads are enabled in the config.
    if (remoteConfig == null ||
        !remoteConfig.adConfig.enabled ||
        !remoteConfig.adConfig.interstitialAdConfiguration.enabled) {
      _logger.info('Interstitial ads are not enabled or config not ready.');
      return;
    }

    final interstitialConfig =
        remoteConfig.adConfig.interstitialAdConfiguration;
    final frequencyConfig =
        interstitialConfig.feedInterstitialAdFrequencyConfig;

    // Determine the required transitions based on user role.
    final int requiredTransitions;
    switch (user?.appRole) {
      case AppUserRole.guestUser:
        requiredTransitions =
            frequencyConfig.guestTransitionsBeforeShowingInterstitialAds;
      case AppUserRole.standardUser:
        requiredTransitions =
            frequencyConfig.standardUserTransitionsBeforeShowingInterstitialAds;
      case AppUserRole.premiumUser:
        requiredTransitions =
            frequencyConfig.premiumUserTransitionsBeforeShowingInterstitialAds;
      case null:
        // If user is null, default to guest user settings.
        requiredTransitions =
            frequencyConfig.guestTransitionsBeforeShowingInterstitialAds;
    }

    _logger.info(
      'Required transitions for user role ${user?.appRole}: $requiredTransitions',
    );

    // Check if it's time to show an interstitial ad.
    if (requiredTransitions > 0 &&
        _pageTransitionCount >= requiredTransitions) {
      _logger.info('Interstitial ad due. Requesting ad.');
      _showInterstitialAd();
      _pageTransitionCount = 0;
    }
  }

  /// Requests and shows an interstitial ad if conditions are met.
  Future<void> _showInterstitialAd() async {
    final appState = appStateProvider();
    final appEnvironment = appState.environment;
    final remoteConfig = appState.remoteConfig;

    // In demo environment, display a placeholder interstitial ad directly.
    if (appEnvironment == AppEnvironment.demo) {
      _logger.info('Demo environment: Showing placeholder interstitial ad.');
      await showDialog<void>(
        context: navigator!.context,
        builder: (context) => const DemoInterstitialAdDialog(),
      );
      return;
    }

    // For other environments (development, production), proceed with real ad loading.
    // This is a secondary check. The primary check is in _handlePageTransition.
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

    _logger.info('Attempting to load interstitial ad...');
    final interstitialAd = await adService.getInterstitialAd(
      adConfig: adConfig,
      adThemeStyle: _adThemeStyle,
    );

    if (interstitialAd != null) {
      _logger.info('Interstitial ad loaded. Showing...');
      // Show the AdMob interstitial ad.
      if (interstitialAd.provider == AdPlatformType.admob &&
          interstitialAd.adObject is admob.InterstitialAd) {
        final admobInterstitialAd =
            interstitialAd.adObject as admob.InterstitialAd
              ..fullScreenContentCallback = admob.FullScreenContentCallback(
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
        _logger.info('Showing local interstitial ad.');
        await showDialog<void>(
          context: navigator!.context,
          builder: (context) => LocalInterstitialAdDialog(
            localInterstitialAd: interstitialAd.adObject as LocalInterstitialAd,
          ),
        );
      }
    } else {
      _logger.info('No interstitial ad loaded.');
    }
  }
}
