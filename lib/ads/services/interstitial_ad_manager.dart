import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template interstitial_ad_manager}
/// A service that manages the lifecycle of interstitial ads.
///
/// This manager listens to the [AppBloc] to stay aware of the current
/// [RemoteConfig] and user state. It proactively pre-loads an interstitial
/// ad when conditions are met and provides a mechanism to show it upon
/// an explicit trigger from the UI.
/// {@endtemplate}
class InterstitialAdManager {
  /// {@macro interstitial_ad_manager}
  InterstitialAdManager({
    required AppBloc appBloc,
    required AdService adService,
    required GlobalKey<NavigatorState> navigatorKey,
    Logger? logger,
  }) : _appBloc = appBloc,
       _adService = adService,
       _navigatorKey = navigatorKey,
       _logger = logger ?? Logger('InterstitialAdManager') {
    // Listen to the AppBloc stream to react to state changes.
    _appBlocSubscription = _appBloc.stream.listen(_onAppStateChanged);
    // Initialize with the current state.
    _onAppStateChanged(_appBloc.state);
  }

  final AppBloc _appBloc;
  final AdService _adService;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Logger _logger;

  late final StreamSubscription<AppState> _appBlocSubscription;

  /// The currently pre-loaded interstitial ad.
  InterstitialAd? _preloadedAd;

  /// Tracks internal page transitions since the last internal ad was shown.
  int _internalTransitionCount = 0;

  /// Tracks external URL navigations since the last external ad was shown.
  int _externalTransitionCount = 0;

  /// The current remote configuration for ads.
  RemoteConfig? _remoteConfig;

  /// The current user tier.
  AccessTier? _userTier;

  /// Disposes the manager and cancels stream subscriptions.
  void dispose() {
    _appBlocSubscription.cancel();
    _disposePreloadedAd();
  }

  /// Handles changes in the [AppState].
  void _onAppStateChanged(AppState state) {
    final newRemoteConfig = state.remoteConfig;
    final newUserTier = state.user?.tier;

    // If the ad config or user tier has changed, update internal state
    // and potentially pre-load a new ad.
    if (newRemoteConfig != _remoteConfig || newUserTier != _userTier) {
      _logger.info('Ad config or user tier changed. Updating internal state.');
      _remoteConfig = newRemoteConfig;
      _userTier = newUserTier;
      // A config change might mean we need to load an ad now.
      _maybePreloadAd(state);
    }
  }

  /// Pre-loads an interstitial ad if one is not already loaded and conditions are met.
  ///
  /// This method now takes the current [AppState] to derive theme information
  /// without needing a [BuildContext].
  Future<void> _maybePreloadAd(AppState appState) async {
    if (_preloadedAd != null) {
      _logger.info('An interstitial ad is already pre-loaded. Skipping.');
      return;
    }

    final remoteConfig = _remoteConfig;
    if (remoteConfig == null ||
        !remoteConfig.features.ads.enabled ||
        !remoteConfig.features.ads.navigationAdConfiguration.enabled) {
      _logger.info('Interstitial ads are disabled. Skipping pre-load.');
      return;
    }

    _logger.info('Attempting to pre-load an interstitial ad...');
    try {
      // Determine the brightness for theme creation.
      // If themeMode is system, use platform brightness.
      final brightness = appState.themeMode == ThemeMode.system
          ? SchedulerBinding.instance.window.platformBrightness
          : (appState.themeMode == ThemeMode.dark
                ? Brightness.dark
                : Brightness.light);

      // Create a ThemeData instance from the AppState's settings.
      // This allows us to derive AdThemeStyle without a BuildContext.
      final themeData = brightness == Brightness.light
          ? lightTheme(
              scheme: appState.flexScheme,
              appTextScaleFactor: appState.appTextScaleFactor,
              appFontWeight: appState.appFontWeight,
              fontFamily: appState.fontFamily,
            )
          : darkTheme(
              scheme: appState.flexScheme,
              appTextScaleFactor: appState.appTextScaleFactor,
              appFontWeight: appState.appFontWeight,
              fontFamily: appState.fontFamily,
            );

      final adThemeStyle = AdThemeStyle.fromTheme(themeData);

      final ad = await _adService.getInterstitialAd(
        adConfig: remoteConfig.features.ads,
        adThemeStyle: adThemeStyle,
        userTier: _userTier ?? AccessTier.guest,
      );

      if (ad != null) {
        _preloadedAd = ad;
        _logger.info('Interstitial ad pre-loaded successfully.');
      } else {
        _logger.warning('Failed to pre-load interstitial ad.');
      }
    } catch (e, s) {
      _logger.severe('Error pre-loading interstitial ad: $e', e, s);
    }
  }

  /// Disposes the currently pre-loaded ad to release its resources.
  void _disposePreloadedAd() {
    if (_preloadedAd?.provider == AdPlatformType.admob &&
        _preloadedAd?.adObject is admob.InterstitialAd) {
      _logger.info('Disposing pre-loaded AdMob interstitial ad.');
      (_preloadedAd!.adObject as admob.InterstitialAd).dispose();
    }
    _preloadedAd = null;
  }

  /// Called by the UI before an ad-eligible navigation occurs.
  ///
  /// This method increments the transition counter and shows a pre-loaded ad
  /// if the frequency criteria are met.
  ///
  /// Returns a [Future] that completes when the ad is dismissed, allowing the
  /// caller to await the ad's lifecycle before proceeding with navigation.
  Future<void> onPotentialAdTrigger() async {
    _internalTransitionCount++;
    _logger.info(
      'Internal navigation trigger. Count: $_internalTransitionCount',
    );

    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) {
      _logger.warning(
        'No remote config available. Cannot determine ad frequency.',
      );
      return;
    }

    final frequencyConfig = remoteConfig
        .features
        .ads
        .navigationAdConfiguration
        .visibleTo[_userTier];

    final requiredTransitions =
        frequencyConfig?.internalNavigationsBeforeShowingInterstitialAd ?? 0;

    if (requiredTransitions > 0 &&
        _internalTransitionCount >= requiredTransitions) {
      _logger.info(
        'Internal transition count meets threshold. Attempting to show ad.',
      );
      await _showAd();
      _internalTransitionCount = 0;
    } else {
      _logger.info(
        'Internal transition count ($_internalTransitionCount) has not met '
        'threshold ($requiredTransitions).',
      );
    }
  }

  /// Called by the UI before an external navigation (opening a URL) occurs.
  ///
  /// This method increments the external navigation counter and shows a
  /// pre-loaded ad if the frequency criteria are met.
  ///
  /// Returns a [Future] that completes when the ad is dismissed, allowing the
  /// caller to await the ad's lifecycle before proceeding with navigation.
  Future<void> onExternalNavigationTrigger() async {
    _externalTransitionCount++;
    _logger.info(
      'External navigation trigger. Count: $_externalTransitionCount',
    );

    final remoteConfig = _remoteConfig;
    if (remoteConfig == null) {
      _logger.warning(
        'No remote config available. Cannot determine ad frequency.',
      );
      return;
    }

    final frequencyConfig = remoteConfig
        .features
        .ads
        .navigationAdConfiguration
        .visibleTo[_userTier];

    final requiredTransitions =
        frequencyConfig?.externalNavigationsBeforeShowingInterstitialAd ?? 0;

    if (requiredTransitions > 0 &&
        _externalTransitionCount >= requiredTransitions) {
      _logger.info(
        'External navigation count meets threshold. Attempting to show ad.',
      );
      await _showAd();
      _externalTransitionCount = 0;
    } else {
      _logger.info(
        'External navigation count ($_externalTransitionCount) has not met '
        'threshold ($requiredTransitions).',
      );
    }
  }

  /// Shows the pre-loaded interstitial ad.
  ///
  /// Returns a [Future] that completes when the ad is dismissed.
  Future<void> _showAd() async {
    if (_preloadedAd == null) {
      _logger.warning(
        'Show ad called, but no ad is pre-loaded. Pre-loading now.',
      );
      // Attempt a last-minute load if no ad is ready.
      await _maybePreloadAd(_appBloc.state);
      if (_preloadedAd == null) {
        _logger.severe('Last-minute ad load failed. Cannot show ad.');
        return;
      }
    }

    final adToShow = _preloadedAd!;
    // Clear the pre-loaded ad before showing
    _preloadedAd = null;

    try {
      switch (adToShow.provider) {
        case AdPlatformType.admob:
          // AdMob does not require context to be shown.
          await _showAdMobAd(adToShow);
      }
    } catch (e, s) {
      _logger.severe('Error showing interstitial ad: $e', e, s);
    } finally {
      // After the ad is shown or fails to show, dispose of it and
      // start pre-loading the next one for the next opportunity.

      // Ensure the ad object is disposed
      _disposePreloadedAd();
      unawaited(_maybePreloadAd(_appBloc.state));
    }
  }

  Future<void> _showAdMobAd(InterstitialAd ad) async {
    if (ad.adObject is! admob.InterstitialAd) return;

    final completer = Completer<void>();
    final admobAd = ad.adObject as admob.InterstitialAd
      ..fullScreenContentCallback = admob.FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) =>
            _logger.info('AdMob ad showed full screen.'),
        onAdDismissedFullScreenContent: (ad) {
          _logger.info('AdMob ad dismissed.');
          ad.dispose();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _logger.severe('AdMob ad failed to show: $error');
          ad.dispose();
          if (!completer.isCompleted) {
            // Complete normally even on failure to unblock navigation.
            completer.complete();
          }
        },
      );
    await admobAd.show();
    return completer.future;
  }
}
