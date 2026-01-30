import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/rewarded_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// A callback function that is invoked when a rewarded ad is shown.
typedef RewardedAdShowCallback = void Function();

/// A callback function that is invoked when a rewarded ad fails to show.
typedef RewardedAdFailedToShowCallback = void Function(String error);

/// A callback function that is invoked when a rewarded ad is dismissed.
typedef RewardedAdDismissedCallback = void Function();

/// A callback function that is invoked when a reward is earned from an ad.
typedef RewardEarnedCallback = void Function(RewardType rewardType);

/// {@template rewarded_ad_manager}
/// A service that manages the lifecycle of rewarded ads.
///
/// This manager listens to the [AppBloc] to stay aware of the current
/// [RemoteConfig] and user state. It proactively pre-loads a rewarded
/// ad when conditions are met and provides a mechanism to show it upon
/// an explicit trigger from the UI.
/// {@endtemplate}
class RewardedAdManager {
  /// {@macro rewarded_ad_manager}
  RewardedAdManager({
    required AppBloc appBloc,
    required AdService adService,
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : _appBloc = appBloc,
       _adService = adService,
       _analyticsService = analyticsService,
       _logger = logger ?? Logger('RewardedAdManager') {
    _appBlocSubscription = _appBloc.stream.listen(_onAppStateChanged);
    _onAppStateChanged(_appBloc.state);
  }

  final AppBloc _appBloc;
  final AdService _adService;
  final AnalyticsService _analyticsService;
  final Logger _logger;

  late final StreamSubscription<AppState> _appBlocSubscription;

  /// The currently pre-loaded rewarded ad.
  RewardedAd? _preloadedAd;

  /// The current remote configuration for ads.
  RemoteConfig? _remoteConfig;

  /// The current user tier.
  AccessTier? _userTier;

  /// Disposes the manager and cancels stream subscriptions.
  void dispose() {
    _appBlocSubscription.cancel();
    _disposePreloadedAd();
  }

  void _onAppStateChanged(AppState state) {
    final newRemoteConfig = state.remoteConfig;
    final newUserTier = state.user?.tier;

    if (newRemoteConfig != _remoteConfig || newUserTier != _userTier) {
      _logger.info('Ad config or user tier changed. Updating internal state.');
      _remoteConfig = newRemoteConfig;
      _userTier = newUserTier;
      _maybePreloadAd(state);
    }
  }

  Future<void> _maybePreloadAd(AppState appState) async {
    if (_preloadedAd != null) {
      _logger.info('A rewarded ad is already pre-loaded. Skipping.');
      return;
    }

    final remoteConfig = _remoteConfig;
    if (remoteConfig == null ||
        !remoteConfig.features.ads.enabled ||
        !remoteConfig.features.rewards.enabled) {
      _logger.info('Rewarded ads are disabled. Skipping pre-load.');
      return;
    }

    _logger.info('Attempting to pre-load a rewarded ad...');
    try {
      final brightness = appState.themeMode == ThemeMode.system
          ? SchedulerBinding.instance.window.platformBrightness
          : (appState.themeMode == ThemeMode.dark
                ? Brightness.dark
                : Brightness.light);

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

      final ad = await _adService.getRewardedAd(
        adConfig: remoteConfig.features.ads,
        adThemeStyle: adThemeStyle,
        userTier: _userTier ?? AccessTier.guest,
      );

      if (ad != null) {
        _preloadedAd = ad;
        _logger.info('Rewarded ad pre-loaded successfully.');
      } else {
        _logger.warning('Failed to pre-load rewarded ad.');
      }
    } catch (e, s) {
      _logger.severe('Error pre-loading rewarded ad: $e', e, s);
    }
  }

  void _disposePreloadedAd() {
    if (_preloadedAd != null) {
      _adService.disposeAd(_preloadedAd);
      _preloadedAd = null;
    }
  }

  /// Shows a pre-loaded rewarded ad.
  Future<void> showAd({
    required RewardType rewardType,
    required RewardedAdShowCallback onAdShowed,
    required RewardedAdFailedToShowCallback onAdFailedToShow,
    required RewardedAdDismissedCallback onAdDismissed,
    required RewardEarnedCallback onRewardEarned,
  }) async {
    if (_preloadedAd == null) {
      _logger.warning(
        'Show ad called, but no ad is pre-loaded. Pre-loading now.',
      );
      await _maybePreloadAd(_appBloc.state);
      if (_preloadedAd == null) {
        _logger.severe('Last-minute ad load failed. Cannot show ad.');
        onAdFailedToShow('Failed to load ad.');
        return;
      }
    }

    final adToShow = _preloadedAd!;
    _preloadedAd = null;

    try {
      if (adToShow.provider == AdPlatformType.admob) {
        final admobAd = adToShow.adObject as admob.RewardedAd;
        final userId = _appBloc.state.user?.id;

        // Configure Server-Side Verification (SSV) options.
        // We pass the userId and the rewardType (as custom data) to the backend
        // via the ad provider's verification callback.
        if (userId != null) {
          await admobAd.setServerSideOptions(
            admob.ServerSideVerificationOptions(
              userId: userId,
              customData: rewardType.name,
            ),
          );
        }

        admobAd.fullScreenContentCallback = admob.FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            _logger.info('AdMob rewarded ad showed full screen.');
            onAdShowed();
          },
          onAdDismissedFullScreenContent: (ad) {
            _logger.info('AdMob rewarded ad dismissed.');
            onAdDismissed();
            ad.dispose();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            _logger.severe('AdMob rewarded ad failed to show: $error');
            onAdFailedToShow(error.message);
            ad.dispose();
          },
        );

        await admobAd.show(
          onUserEarnedReward: (ad, reward) {
            _logger.info(
              'User earned reward: amount=${reward.amount}, type=${reward.type}',
            );
            unawaited(
              _analyticsService.logEvent(
                AnalyticsEvent.adRewardEarned,
                payload: AdRewardEarnedPayload(
                  adProvider: AdPlatformType.admob,
                  adType: AdType.rewarded,
                  adPlacement: 'rewards_hub',
                  rewardAmount: reward.amount,
                  rewardType: rewardType,
                ),
              ),
            );
            onRewardEarned(rewardType);
          },
        );
      }
    } catch (e, s) {
      _logger.severe('Error showing rewarded ad: $e', e, s);
      onAdFailedToShow('An unexpected error occurred.');
    } finally {
      _disposePreloadedAd();
      unawaited(_maybePreloadAd(_appBloc.state));
    }
  }
}
