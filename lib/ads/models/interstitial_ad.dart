import 'package:core/core.dart'; // Import core for AdPlatformType
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@template interstitial_ad}
/// A generic, provider-agnostic model representing a full-screen interstitial advertisement.
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It holds a reference to the original,
/// SDK-specific ad object for display purposes and a [provider] type
/// to identify its origin. This model is intended for internal usage only
/// and is not serialized to/from JSON.
/// {@endtemplate}
@immutable
class InterstitialAd extends Equatable {
  /// {@macro interstitial_ad}
  const InterstitialAd({
    required this.id,
    required this.provider,
    required this.adObject,
  });

  /// A unique identifier for this specific interstitial ad instance.
  final String id;

  /// The ad provider that this ad belongs to.
  ///
  /// This is used to determine which ad network's interstitial ad is being
  /// managed.
  final AdPlatformType provider;

  /// The original, SDK-specific ad object.
  ///
  /// This object is typically an instance of an ad network's interstitial ad
  /// class (e.g., `google_mobile_ads.InterstitialAd`). It should be cast back
  /// to its specific type only when interacting with the ad network's API
  /// for showing the ad.
  final Object adObject;

  /// Creates a copy of this [InterstitialAd] but with the given fields replaced with
  /// the new values.
  InterstitialAd copyWith({
    String? id,
    AdPlatformType? provider,
    Object? adObject,
  }) {
    return InterstitialAd(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      adObject: adObject ?? this.adObject,
    );
  }

  @override
  List<Object?> get props => [id, provider, adObject];
}
