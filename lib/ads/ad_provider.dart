import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;

/// {@template ad_provider}
/// An abstract class defining the interface for any ad network provider.
///
/// This abstraction allows the application to integrate with different
/// ad networks (e.g., AdMob, Meta Audience Network) through a common API,
/// promoting extensibility and decoupling.
/// {@endtemplate}
abstract class AdProvider {
  /// {@macro ad_provider}
  const AdProvider();

  /// Initializes the ad network SDK.
  ///
  /// This method should be called once at application startup.
  /// It handles any necessary setup for the specific ad network.
  Future<void> initialize();

  /// Loads a native ad, optionally tailoring it to a specific style.
  ///
  /// Returns a [app_native_ad.NativeAd] object if an ad is successfully loaded,
  /// otherwise returns `null`.
  ///
  /// The [adPlatformIdentifiers] provides the platform-specific ad unit IDs.
  /// The [adId] is the specific identifier for the ad slot (e.g., native ad unit ID).
  /// The [adType] specifies the type of ad to load (e.g., native, banner).
  /// The [adThemeStyle] provides UI-agnostic theme properties for ad styling.
  Future<app_native_ad.NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  });

  /// Loads a banner ad.
  ///
  /// Returns a [app_native_ad.NativeAd] object if an ad is successfully loaded,
  /// otherwise returns `null`.
  ///
  /// The [adPlatformIdentifiers] provides the platform-specific ad unit IDs.
  /// The [adId] is the specific identifier for the ad slot (e.g., banner ad unit ID).
  /// The [adType] specifies the type of ad to load (e.g., native, banner).
  /// The [adThemeStyle] provides UI-agnostic theme properties for ad styling.
  Future<app_native_ad.NativeAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  });

  /// Loads an interstitial ad.
  ///
  /// Returns a [app_native_ad.NativeAd] object if an ad is successfully loaded,
  /// otherwise returns `null`.
  ///
  /// The [adPlatformIdentifiers] provides the platform-specific ad unit IDs.
  /// The [adId] is the specific identifier for the ad slot (e.g., interstitial ad unit ID).
  /// The [adType] specifies the type of ad to load (must be [AdType.interstitial]).
  /// The [adThemeStyle] provides UI-agnostic theme properties for ad styling.
  Future<app_native_ad.NativeAd?> loadInterstitialAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
  });
}
