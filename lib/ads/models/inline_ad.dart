import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:core/core.dart'; // Import core for AdPlatformType

/// {@template inline_ad}
/// An abstract base class for all inline ad types (native and banner).
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It holds a reference to the original,
/// SDK-specific ad object for rendering purposes and a [provider] type
/// to identify its origin. This model is intended for ads displayed directly
/// within content feeds or other UI elements, not for full-screen interstitials.
/// {@endtemplate}
@immutable
abstract class InlineAd extends Equatable {
  /// {@macro inline_ad}
  const InlineAd({
    required this.id,
    required this.provider,
    required this.adObject,
  });

  /// A unique identifier for this specific inline ad instance.
  final String id;

  /// The ad provider that this ad belongs to.
  ///
  /// This is used by the UI to determine which rendering widget to use.
  final AdPlatformType provider;

  /// The original, SDK-specific ad object.
  ///
  /// This object is passed directly to the ad network's UI widget for rendering.
  /// It should be cast back to its specific type (e.g., `google_mobile_ads.NativeAd`
  /// or `google_mobile_ads.BannerAd`) only within the dedicated ad rendering
  /// widget for that provider.
  final Object adObject;

  @override
  List<Object?> get props => [id, provider, adObject];
}
