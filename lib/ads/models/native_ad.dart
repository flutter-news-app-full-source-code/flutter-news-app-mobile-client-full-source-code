import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@template native_ad}
/// A generic, provider-agnostic model representing a native advertisement.
///
/// This model decouples the application's core logic from specific ad network
/// SDKs (e.g., Google Mobile Ads). It contains common fields found in native
/// ads and holds a reference to the original, SDK-specific ad object for
/// rendering purposes.
/// {@endtemplate}
@immutable
class NativeAd extends Equatable {
  /// {@macro native_ad}
  const NativeAd({
    required this.id,
    required this.headline,
    required this.body,
    required this.callToAction,
    this.iconUrl,
    this.imageUrl,
    this.advertiser,
    this.starRating,
    this.store,
    this.price,
    required this.adObject,
  });

  /// A unique identifier for this specific native ad instance.
  final String id;

  /// The main headline or title of the advertisement.
  final String headline;

  /// The main body text or description of the advertisement.
  final String body;

  /// The text for the call-to-action button (e.g., "Install", "Learn More").
  final String callToAction;

  /// The URL of the ad's icon image (e.g., app icon).
  final String? iconUrl;

  /// The URL of the main image asset for the ad.
  final String? imageUrl;

  /// The name of the advertiser or sponsor.
  final String? advertiser;

  /// The star rating for the advertised app (typically 1.0 to 5.0).
  final double? starRating;

  /// The name of the app store (e.g., "Google Play", "App Store").
  final String? store;

  /// The price of the advertised app or product.
  final String? price;

  /// The original, SDK-specific ad object.
  ///
  /// This object is passed directly to the ad network's UI widget for rendering.
  /// It should be cast back to its specific type (e.g., `google_mobile_ads.NativeAd`)
  /// only within the dedicated ad rendering widget for that provider.
  final Object adObject;

  @override
  List<Object?> get props => [
        id,
        headline,
        body,
        callToAction,
        iconUrl,
        imageUrl,
        advertiser,
        starRating,
        store,
        price,
        adObject,
      ];
}
