import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';

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

  /// Loads an inline native ad, optionally tailoring it to a specific style.
  ///
  /// Returns a [NativeAd] object if an ad is successfully loaded,
  /// otherwise returns `null`. This method is intended for native ads
  /// that are displayed directly within content feeds.
  ///
  /// The [adPlatformIdentifiers] provides the platform-specific ad unit IDs.
  /// The [adId] is the specific identifier for the ad slot (e.g., native ad unit ID).
  /// The [adThemeStyle] provides UI-agnostic theme properties for ad styling.
  Future<NativeAd?> loadNativeAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  });

  /// Loads an inline banner ad.
  ///
  /// Returns a [NativeAd] object if an ad is successfully loaded,
  /// otherwise returns `null`. This method is intended for banner ads
  /// that are displayed directly within content feeds.
  ///
  /// The [adPlatformIdentifiers] provides the platform-specific ad unit IDs.
  /// The [adId] is the specific identifier for the ad slot (e.g., banner ad unit ID).
  /// The [adThemeStyle] provides UI-agnostic theme properties for ad styling.
  Future<NativeAd?> loadBannerAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  });

  /// Loads a full-screen interstitial ad.
  ///
  /// Returns an [InterstitialAd] object if an ad is successfully loaded,
  /// otherwise returns `null`. This method is intended for interstitial ads
  /// that are displayed as full-screen overlays, typically on route changes.
  ///
  /// The [adPlatformIdentifiers] provides the platform-specific ad unit IDs.
  /// The [adId] is the specific identifier for the ad slot (e.g., interstitial ad unit ID).
  /// The [adThemeStyle] provides UI-agnostic theme properties for ad styling.
  Future<InterstitialAd?> loadInterstitialAd({
    required AdPlatformIdentifiers adPlatformIdentifiers,
    required String? adId,
    required AdThemeStyle adThemeStyle,
  });
}
