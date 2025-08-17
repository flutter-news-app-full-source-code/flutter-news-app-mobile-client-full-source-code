import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@template ad_provider_type}
/// Defines the supported ad network providers.
///
/// This enum is used to identify the source of a [NativeAd] object,
/// allowing the UI to select the correct rendering widget at runtime.
/// {@endtemplate}
enum AdProviderType {
  /// Google AdMob provider.
  admob,

  /// A placeholder provider for platforms where native ads are not supported.
  ///
  /// This is primarily used for the web demo environment to maintain UI
  /// consistency without relying on native SDKs.
  placeholder,
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
  });

  /// A unique identifier for this specific native ad instance.
  final String id;

  /// The ad provider that this ad belongs to.
  ///
  /// This is used by the UI to determine which rendering widget to use.
  final AdProviderType provider;

  /// The original, SDK-specific ad object.
  ///
  /// This object is passed directly to the ad network's UI widget for rendering.
  /// It should be cast back to its specific type (e.g., `google_mobile_ads.NativeAd`)
  /// only within the dedicated ad rendering widget for that provider.
  final Object adObject;

  @override
  List<Object?> get props => [id, provider, adObject];
}
