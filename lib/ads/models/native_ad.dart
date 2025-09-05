import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:core/core.dart'; // Import core for AdPlatformType

/// {@template native_ad_template_type}
/// Defines the visual template type for a native ad.
///
/// This is used to determine the expected size and layout of the native ad
/// when rendering it in the UI.
/// {@endtemplate}
enum NativeAdTemplateType {
  /// A small native ad template, typically used for compact layouts.
  small,

  /// A medium native ad template, typically used for more prominent layouts.
  medium,
}

/// {@template native_ad}
/// A generic, provider-agnostic model representing a native advertisement.
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It holds a reference to the original,
/// SDK-specific ad object for rendering purposes and a [provider] type
/// to identify its origin.
/// {@endtemplate}
@immutable
class NativeAd extends Equatable {
  /// {@macro native_ad}
  const NativeAd({
    required this.id,
    required this.provider,
    required this.adObject,
    required this.templateType,
  });

  /// A unique identifier for this specific native ad instance.
  final String id;

  /// The ad provider that this ad belongs to.
  ///
  /// This is used by the UI to determine which rendering widget to use.
  final AdPlatformType provider; // Changed from AdProviderType to AdPlatformType

  /// The original, SDK-specific ad object.
  ///
  /// This object is passed directly to the ad network's UI widget for rendering.
  /// It should be cast back to its specific type (e.g., `google_mobile_ads.NativeAd`)
  /// only within the dedicated ad rendering widget for that provider.
  final Object adObject;

  /// The template type of the native ad, indicating its expected size and layout.
  final NativeAdTemplateType templateType;

  @override
  List<Object?> get props => [id, provider, adObject, templateType];
}
