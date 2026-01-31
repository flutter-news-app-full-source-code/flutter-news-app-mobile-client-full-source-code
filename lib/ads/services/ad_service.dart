import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/rewarded_ad.dart';

/// {@template ad_service_interface}
/// An interface for the service responsible for managing and providing ads.
///
/// This contract allows for different implementations, such as a concrete
/// mobile ad service or a no-op service for when ads are disabled.
/// {@endtemplate}
abstract class AdService {
  /// Initializes all underlying ad providers.
  Future<void> initialize();

  /// Disposes of an ad object by delegating to the appropriate [AdProvider].
  Future<void> disposeAd(dynamic adModel);

  /// Retrieves a loaded inline ad (native or banner) for display in a feed.
  Future<InlineAd?> getFeedAd({
    required AdConfig adConfig,
    required AdType adType,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
    FeedItemImageStyle? feedItemImageStyle,
  });

  /// Retrieves a loaded full-screen interstitial ad.
  Future<InterstitialAd?> getInterstitialAd({
    required AdConfig adConfig,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
  });

  /// Retrieves a loaded full-screen rewarded ad.
  Future<RewardedAd?> getRewardedAd({
    required AdConfig adConfig,
    required AdThemeStyle adThemeStyle,
    required AccessTier userTier,
  });

  /// Injects stateless [AdPlaceholder] markers into a list of [FeedItem]s
  /// based on configured ad frequency rules.
  Future<List<FeedItem>> injectFeedAdPlaceholders({
    required List<FeedItem> feedItems,
    required User? user,
    required RemoteConfig remoteConfig,
    required FeedItemImageStyle imageStyle,
    required AdThemeStyle adThemeStyle,
    UserRewards? userRewards,
    int processedContentItemCount = 0,
  });
}
