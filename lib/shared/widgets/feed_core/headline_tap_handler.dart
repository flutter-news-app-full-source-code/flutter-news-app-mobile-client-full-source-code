import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';

/// {@template headline_tap_handler}
/// A utility class for handling headline taps, including interstitial ad
/// transition counting and navigation.
/// {@endtemplate}
abstract final class HeadlineTapHandler {
  /// Handles a tap on a [Headline] item.
  ///
  /// This method performs two key actions sequentially:
  /// 1. Notifies the [InterstitialAdManager] of a potential ad transition and
  ///    awaits its completion (e.g., the user closing the ad).
  /// 2. Navigates to the [Routes.articleDetailsName] page for the given headline,
  ///    but only after the ad has been handled and if the context is still mounted.
  ///
  /// - [context]: The current [BuildContext] to access BLoCs and for navigation.
  /// - [headline]: The [Headline] item that was tapped.
  static Future<void> handleHeadlineTap(
    BuildContext context,
    Headline headline,
  ) async {
    // Await for the ad to be shown and dismissed.
    await context.read<InterstitialAdManager>().onPotentialAdTrigger();

    // Check if the widget is still in the tree before navigating.
    if (!context.mounted) return;

    // Proceed with navigation after the ad is closed.
    await context.pushNamed(
      Routes.articleDetailsName,
      pathParameters: {'id': headline.id},
      extra: headline,
    );
  }
}
