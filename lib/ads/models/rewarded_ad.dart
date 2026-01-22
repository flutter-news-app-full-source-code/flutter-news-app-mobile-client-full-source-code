import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// {@template rewarded_ad}
/// A generic model representing a loaded rewarded ad.
///
/// This class wraps the platform-specific ad object and provides a
/// consistent interface for the application to interact with it.
/// {@endtemplate}
class RewardedAd extends Equatable {
  /// {@macro rewarded_ad}
  const RewardedAd({
    required this.id,
    required this.provider,
    required this.adObject,
  });

  /// The unique identifier for this ad instance.
  final String id;

  /// The ad platform provider (e.g., AdMob).
  final AdPlatformType provider;

  /// The underlying platform-specific ad object.
  final Object adObject;

  @override
  List<Object> get props => [id, provider, adObject];
}
