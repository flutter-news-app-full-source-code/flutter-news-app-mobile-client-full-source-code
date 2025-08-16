import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// {@template ad_feed_item}
/// A [FeedItem] that wraps a loaded native ad object from an ad network SDK.
///
/// This class allows actual, displayable ad objects (like [NativeAd] from
/// Google Mobile Ads) to be seamlessly integrated into the application's
/// generic feed structure alongside other content types (e.g., [Headline]).
/// {@endtemplate}
class AdFeedItem extends FeedItem with EquatableMixin {
  /// {@macro ad_feed_item}
  const AdFeedItem({
    required this.id,
    required this.nativeAd,
  }) : super(type: 'ad_feed_item');

  /// A unique identifier for this specific ad instance in the feed.
  ///
  /// This is distinct from the ad unit ID and is used for tracking
  /// the ad within the feed.
  final String id;

  /// The loaded native ad object from the ad network SDK.
  ///
  /// This object contains the actual ad content and is ready for display.
  final NativeAd nativeAd;

  @override
  List<Object?> get props => [id, nativeAd, type];
}
