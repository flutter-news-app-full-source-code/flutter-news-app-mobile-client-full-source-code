import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;

/// {@template ad_feed_item}
/// A [FeedItem] that wraps a loaded native ad object from an ad network SDK.
///
/// This class allows actual, displayable ad objects (like [app_native_ad.NativeAd]
/// from our generic ad model) to be seamlessly integrated into the application's
/// generic feed structure alongside other content types (e.g., [Headline]).
/// {@endtemplate}
class AdFeedItem extends FeedItem with EquatableMixin {
  /// {@macro ad_feed_item}
  const AdFeedItem({required this.id, required this.nativeAd})
    : super(type: 'ad_feed_item');

  /// A unique identifier for this specific ad instance in the feed.
  ///
  /// This is distinct from the ad unit ID and is used for tracking
  /// the ad within the feed.
  final String id;

  /// The loaded native ad object, represented by our generic [app_native_ad.NativeAd] model.
  ///
  /// This object contains the actual ad content and is ready for display.
  final app_native_ad.NativeAd nativeAd;

  @override
  List<Object?> get props => [id, nativeAd, type];
}
