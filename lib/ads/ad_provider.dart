import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  /// Loads a native ad.
  ///
  /// Returns a [NativeAd] object if an ad is successfully loaded,
  /// otherwise returns `null`.
  Future<NativeAd?> loadNativeAd();

  // Future methods for other ad types (e.g., interstitial, banner)
  // can be added here as needed in the future.
}
