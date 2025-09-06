import 'package:core/core.dart'; // Import core for AdPlatformType
import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';

/// {@template banner_ad}
/// A generic, provider-agnostic model representing an inline banner advertisement.
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It holds a reference to the original,
/// SDK-specific ad object for rendering purposes and a [provider] type
/// to identify its origin. This model is intended for banner ads displayed
/// directly within content feeds or other UI elements.
/// {@endtemplate}
@immutable
class BannerAd extends InlineAd {
  /// {@macro banner_ad}
  const BannerAd({
    required super.id,
    required super.provider,
    required super.adObject,
  });

  /// Creates a copy of this [BannerAd] but with the given fields replaced with
  /// the new values.
  BannerAd copyWith({String? id, AdPlatformType? provider, Object? adObject}) {
    return BannerAd(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      adObject: adObject ?? this.adObject,
    );
  }

  @override
  List<Object?> get props => [id, provider, adObject];
}
