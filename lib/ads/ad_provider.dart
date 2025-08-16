import 'package:core/core.dart';
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
  /// The [imageStyle] is used to select an appropriate native ad template
  /// that best matches the visual density of the surrounding content.
  Future<app_native_ad.NativeAd?> loadNativeAd({
    required HeadlineImageStyle imageStyle,
  });

  // Future methods for other ad types (e.g., interstitial, banner)
  // can be added here as needed in the future.
}
