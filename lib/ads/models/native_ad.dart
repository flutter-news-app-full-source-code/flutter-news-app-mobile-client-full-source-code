import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@template native_ad}
/// A generic, provider-agnostic model representing a native advertisement.
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It holds a reference to the original,
/// SDK-specific ad object for rendering purposes.
/// {@endtemplate}
@immutable
class NativeAd extends Equatable {
  /// {@macro native_ad}
  const NativeAd({
    required this.id,
    required this.adObject,
  });

  /// A unique identifier for this specific native ad instance.
  final String id;

  /// The original, SDK-specific ad object.
  ///
  /// This object is passed directly to the ad network's UI widget for rendering.
  /// It should be cast back to its specific type (e.g., `google_mobile_ads.NativeAd`)
  /// only within the dedicated ad rendering widget for that provider.
  final Object adObject;

  @override
  List<Object?> get props => [
        id,
        adObject,
      ];
}
