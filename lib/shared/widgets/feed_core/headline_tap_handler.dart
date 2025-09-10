import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';

/// {@template headline_tap_handler}
/// A utility class for handling headline taps, including interstitial ad
/// transition counting and navigation.
/// {@endtemplate}
abstract final class HeadlineTapHandler {
  /// Handles a tap on a [Headline] item.
  ///
  /// This method performs two key actions:
  /// 1. Notifies the [InterstitialAdManager] of a potential ad transition.
  /// 2. Navigates to the [Routes.articleDetailsName] page for the given headline.
  ///
  /// - [context]: The current [BuildContext] to access BLoCs and for navigation.
  /// - [headline]: The [Headline] item that was tapped.
  static void handleHeadlineTap(BuildContext context, Headline headline) {
    context.read<InterstitialAdManager>().onPotentialAdTrigger();
    context.goNamed(
      Routes.articleDetailsName,
      pathParameters: {'id': headline.id},
      extra: headline,
    );
  }
}
