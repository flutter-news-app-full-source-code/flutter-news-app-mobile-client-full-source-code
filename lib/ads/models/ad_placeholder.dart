import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// {@template ad_placeholder}
/// A stateless [FeedItem] that acts as a marker for an ad slot in the feed.
///
/// This model is used in the BLoC's state to indicate where an ad should be
/// displayed, without holding the actual, stateful native ad object.
/// The actual ad loading and display logic is handled by a dedicated widget
/// that interacts with an ad cache.
/// {@endtemplate}
class AdPlaceholder extends FeedItem with EquatableMixin {
  /// {@macro ad_placeholder}
  const AdPlaceholder({
    required this.id,
    required this.adPlatformType,
    required this.adType,
    this.adId,
  }) : super(type: 'ad_placeholder');

  /// A unique identifier for this specific ad placeholder instance.
  ///
  /// This ID is used by the ad loading widget to request a specific ad
  /// from the ad cache or to load a new one if not found.
  final String id;

  /// The platform type of the ad (e.g., AdMob, Local).
  final AdPlatformType adPlatformType;

  /// The type of the ad (e.g., native, banner).
  final AdType adType;

  /// The platform-specific ad identifier (e.g., AdMob unit ID, Local ad ID).
  final String? adId;

  @override
  List<Object?> get props => [id, adPlatformType, adType, adId, type];
}
