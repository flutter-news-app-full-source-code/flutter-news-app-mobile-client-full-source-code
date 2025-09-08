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

  /// Stores the name of the previous route.
  String? _previousRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final currentRouteName = route.settings.name;
    _logger.info(
      'AdNavigatorObserver: Route pushed: $currentRouteName (Previous: $_previousRouteName)',
    );
    if (route is PageRoute && currentRouteName != null) {
      _handlePageTransition(currentRouteName);
    }
    _previousRouteName = currentRouteName;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final currentRouteName = previousRoute
        ?.settings
        .name; // After pop, previousRoute is the new current
    _logger.info(
      'AdNavigatorObserver: Route popped: ${route.settings.name} (New Current: $currentRouteName)',
    );
    if (route is PageRoute && currentRouteName != null) {
      _handlePageTransition(currentRouteName);
    }
    _previousRouteName = currentRouteName;
  }

  /// Determines if a route transition is eligible for an interstitial ad.
  ///
  /// An ad is considered eligible if the transition is from a content list
  /// (e.g., feed, search) to a detail page (e.g., article, entity details).
  bool _isEligibleForInterstitialAd(String currentRouteName) {
    // Define content list routes
    const contentListRoutes = {
      'feed',
      'search',
      'followedTopicsList',
      'followedSourcesList',
      'followedCountriesList',
      'accountSavedHeadlines',
    };

    // Define detail page routes
    const detailPageRoutes = {
      'articleDetails',
      'searchArticleDetails',
      'accountArticleDetails',
      'globalArticleDetails',
      'entityDetails',
    };

    final previous = _previousRouteName;
    final current = currentRouteName;

    final isFromContentList =
        previous != null && contentListRoutes.contains(previous);
    final isToDetailPage = detailPageRoutes.contains(current);

    _logger.info(
      'AdNavigatorObserver: Eligibility check: Previous: $previous (Is Content List: $isFromContentList), '
      'Current: $current (Is Detail Page: $isToDetailPage)',
    );

    return isFromContentList && isToDetailPage;
  }

  /// Handles a page transition event, checks ad frequency, and shows an ad if needed.
  void _handlePageTransition(String currentRouteName) {
    final appState = appStateProvider();
    final remoteConfig = appState.remoteConfig;
    final user = appState.user;

    _logger.info(
      'AdNavigatorObserver: _handlePageTransition called for route: $currentRouteName',
    );

    // Only proceed if remote config is available, ads are globally enabled,
    // and interstitial ads are enabled in the config.
    if (remoteConfig == null) {
      _logger.warning('AdNavigatorObserver: RemoteConfig is null. Cannot check ad enablement.');
      return;
    }
    if (!remoteConfig.adConfig.enabled) {
      _logger.info('AdNavigatorObserver: Ads are globally disabled in RemoteConfig.');
      return;
    }
    if (!remoteConfig.adConfig.interstitialAdConfiguration.enabled) {
      _logger.info('AdNavigatorObserver: Interstitial ads are disabled in RemoteConfig.');
      return;
    }

    // Only increment count if the transition is eligible for an interstitial ad.
    if (_isEligibleForInterstitialAd(currentRouteName)) {
      _pageTransitionCount++;
      _logger.info(
        'AdNavigatorObserver: Eligible page transition. Current count: $_pageTransitionCount',
      );
    } else {
      _logger.info(
        'AdNavigatorObserver: Ineligible page transition. Count remains: $_pageTransitionCount',
      );
      return; // Do not proceed if not an eligible transition
    }

    final interstitialConfig =
        remoteConfig.adConfig.interstitialAdConfiguration;
    final frequencyConfig = interstitialConfig
        .feedInterstitialAdFrequencyConfig; // Using existing name

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
      'AdNavigatorObserver: Required transitions for user role ${user?.appRole}: $requiredTransitions. '
      'Current eligible transitions: $_pageTransitionCount',
    );

    // Check if it's time to show an interstitial ad.
    if (requiredTransitions > 0 &&
        _pageTransitionCount >= requiredTransitions) {
      _logger.info('AdNavigatorObserver: Interstitial ad due. Requesting ad.');
      unawaited(_showInterstitialAd()); // Use unawaited to not block navigation
      // Reset count only after an ad is due (whether it shows or fails)
      _pageTransitionCount = 0;
    } else {
      _logger.info(
        'AdNavigatorObserver: Interstitial ad not yet due. '
        'Required: $requiredTransitions, Current: $_pageTransitionCount',
      );
    }
  }

  /// Requests and shows an interstitial ad if conditions are met.
  Future<void> _showInterstitialAd() async {
    _logger.info('AdNavigatorObserver: Attempting to show interstitial ad.');
    final appState = appStateProvider();
    final appEnvironment = appState.environment;
    final remoteConfig = appState.remoteConfig;

    // In demo environment, display a placeholder interstitial ad directly.
    if (appEnvironment == AppEnvironment.demo) {
      _logger.info('AdNavigatorObserver: Demo environment: Showing placeholder interstitial ad.');
      if (navigator?.context == null) {
        _logger.severe('AdNavigatorObserver: Navigator context is null. Cannot show demo interstitial ad.');
        return;
      }
      await showDialog<void>(
        context: navigator!.context,
        builder: (context) => const DemoInterstitialAdDialog(),
      );
      _logger.info('AdNavigatorObserver: Placeholder interstitial ad shown.');
      return;
    }

    // For other environments (development, production), proceed with real ad loading.
    // This is a secondary check. The primary check is in _handlePageTransition.
    if (remoteConfig == null || !remoteConfig.adConfig.enabled) {
      _logger.warning(
        'AdNavigatorObserver: Interstitial ads disabled or remote config not available. '
        'This should have been caught earlier in _handlePageTransition.',
      );
      return;
    }

    final adConfig = remoteConfig.adConfig;
    final interstitialConfig = adConfig.interstitialAdConfiguration;

    if (!interstitialConfig.enabled) {
      _logger.warning(
        'AdNavigatorObserver: Interstitial ads are specifically disabled in config. '
        'This should have been caught earlier in _handlePageTransition.',
      );
      return;
    }

    _logger.info('AdNavigatorObserver: Requesting interstitial ad from AdService...');
    final interstitialAd = await adService.getInterstitialAd(
      adConfig: adConfig,
      adThemeStyle: _adThemeStyle,
    );

    if (interstitialAd != null) {
      _logger.info('AdNavigatorObserver: Interstitial ad loaded. Showing...');
      if (navigator?.context == null) {
        _logger.severe('AdNavigatorObserver: Navigator context is null. Cannot show interstitial ad.');
        return;
      }
      // Show the AdMob interstitial ad.
      if (interstitialAd.provider == AdPlatformType.admob &&
          interstitialAd.adObject is admob.InterstitialAd) {
        _logger.info('AdNavigatorObserver: Showing AdMob interstitial ad.');
        final admobInterstitialAd =
            interstitialAd.adObject as admob.InterstitialAd
              ..fullScreenContentCallback = admob.FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  _logger.info('AdNavigatorObserver: AdMob Interstitial Ad dismissed.');
                  ad.dispose();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  _logger.severe('AdNavigatorObserver: AdMob Interstitial Ad failed to show: $error');
                  ad.dispose();
                },
                onAdShowedFullScreenContent: (ad) {
                  _logger.info('AdNavigatorObserver: AdMob Interstitial Ad showed.');
                },
              );
        await admobInterstitialAd.show();
      } else if (interstitialAd.provider == AdPlatformType.local &&
          interstitialAd.adObject is LocalInterstitialAd) {
        _logger.info('AdNavigatorObserver: Showing local interstitial ad.');
        await showDialog<void>(
          context: navigator!.context,
          builder: (context) => LocalInterstitialAdDialog(
            localInterstitialAd: interstitialAd.adObject as LocalInterstitialAd,
          ),
        );
        _logger.info('AdNavigatorObserver: Local interstitial ad shown.');
      } else {
        _logger.warning(
          'AdNavigatorObserver: Loaded interstitial ad has unknown provider '
          'or adObject type: ${interstitialAd.provider}, ${interstitialAd.adObject.runtimeType}',
        );
      }
    } else {
      _logger.warning(
        'AdNavigatorObserver: No interstitial ad loaded by AdService, even though one was due. '
        'Check AdService implementation and ad unit availability.',
      );
    }
  }
}
