import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';

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
/// A generic, provider-agnostic model representing an inline native advertisement.
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It holds a reference to the original,
/// SDK-specific ad object for rendering purposes and a [provider] type
/// to identify its origin. This model is intended for native ads displayed
/// directly within content feeds or other UI elements.
/// {@endtemplate}
@immutable
class NativeAd extends InlineAd {
  /// {@macro native_ad}
  const NativeAd({
    required super.id,
    required super.provider,
    required super.adObject,
    required this.templateType,
  });

  /// The template type of the native ad, indicating its expected size and layout.
  ///
  /// This is relevant for native ads and can be used to determine the visual
  /// presentation in the UI.
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
}
