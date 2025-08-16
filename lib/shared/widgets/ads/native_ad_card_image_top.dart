import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/native_ad_view.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template native_ad_card_image_top}
/// A widget to display a native ad with a large image at the top,
/// visually mimicking [HeadlineTileImageTop].
///
/// This widget accepts a [NativeAdView] to render the actual ad content,
/// ensuring it remains provider-agnostic.
/// {@endtemplate}
class NativeAdCardImageTop extends StatelessWidget {
  /// {@macro native_ad_card_image_top}
  const NativeAdCardImageTop({required this.adView, super.key});

  /// The widget responsible for rendering the native ad content.
  final NativeAdView adView;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: adView, // Directly render the provided NativeAdView
    );
  }
}
