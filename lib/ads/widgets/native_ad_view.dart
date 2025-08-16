import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;

/// {@template native_ad_view}
/// An abstract widget that defines the interface for rendering a native ad.
///
/// Concrete implementations of this widget will be responsible for displaying
/// the native ad content from a specific ad network SDK (e.g., AdMob).
/// This abstraction ensures that the higher-level UI components remain
/// provider-agnostic.
/// {@endtemplate}
abstract class NativeAdView extends StatelessWidget {
  /// {@macro native_ad_view}
  const NativeAdView({required this.nativeAd, super.key});

  /// The generic native ad data to display.
  ///
  /// This object contains the original, SDK-specific ad object, which concrete
  /// implementations will cast and render.
  final app_native_ad.NativeAd nativeAd;
}
