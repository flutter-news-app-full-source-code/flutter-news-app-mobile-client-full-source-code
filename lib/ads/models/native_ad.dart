import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:core/core.dart'; // Import core for AdPlatformType

part 'native_ad.g.dart';

/// {@template native_ad_template_type}
/// Defines the visual template type for an inline native ad.
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
/// A generic, provider-agnostic model representing an inline native or banner advertisement.
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It holds a reference to the original,
/// SDK-specific ad object for rendering purposes and a [provider] type
/// to identify its origin. This model is intended for ads displayed directly
/// within content feeds or other UI elements, not for full-screen interstitials.
/// {@endtemplate}
@immutable
@JsonSerializable(explicitToJson: true, includeIfNull: true, checked: true)
class NativeAd extends Equatable {
  /// {@macro native_ad}
  const NativeAd({
    required this.id,
    required this.provider,
    required this.adObject,
    required this.templateType,
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

  /// The template type of the native ad, indicating its expected size and layout.
  ///
  /// This is relevant for native ads and can be used to determine the visual
  /// presentation in the UI. For banner ads, this might default to a small
  /// template type or be ignored by the rendering widget.
  final NativeAdTemplateType templateType;

  /// Creates a copy of this [NativeAd] but with the given fields replaced with
  /// the new values.
  NativeAd copyWith({
    String? id,
    AdPlatformType? provider,
    Object? adObject,
    NativeAdTemplateType? templateType,
  }) {
    return NativeAd(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      adObject: adObject ?? this.adObject,
      templateType: templateType ?? this.templateType,
    );
  }

  @override
  List<Object?> get props => [id, provider, adObject, templateType];

  /// Converts this [NativeAd] instance to JSON data.
  Map<String, dynamic> toJson() => _$NativeAdToJson(this);

  /// Creates an [NativeAd] from JSON data.
  factory NativeAd.fromJson(Map<String, dynamic> json) =>
      _$NativeAdFromJson(json);
}
