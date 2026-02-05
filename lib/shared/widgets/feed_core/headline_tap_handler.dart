import 'dart:async';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/in_app_browser.dart';
import 'package:url_launcher/url_launcher.dart';

/// {@template headline_tap_handler}
/// A utility class for handling headline taps, including interstitial ad
/// transition counting and navigation.
/// {@endtemplate}
abstract final class HeadlineTapHandler {
  /// Handles a tap on a [Headline] item.
  ///
  /// This method performs two key actions sequentially:
  /// 1. Notifies the [InterstitialAdManager] of an external navigation trigger
  ///    and awaits its completion (e.g., the user closing the ad).
  /// 2. Determines the correct link-opening behavior by checking user settings
  ///    first, then falling back to the remote configuration.
  /// 3. Launches the headline's URL using the determined browser behavior,
  ///    but only after the ad has been handled and if the context is still
  ///    mounted.
  ///
  /// - [context]: The current [BuildContext] to access BLoCs and for navigation.
  /// - [headline]: The [Headline] item that was tapped.
  static Future<void> handleHeadlineTap(
    BuildContext context,
    Headline headline,
  ) async {
    // Log the content view event immediately.
    unawaited(
      context.read<AnalyticsService>().logEvent(
        AnalyticsEvent.contentViewed,
        payload: ContentViewedPayload(
          contentId: headline.id,
          contentType: ContentType.headline,
        ),
      ),
    );

    // Notify the ad manager of an external navigation and await ad dismissal.
    await context.read<InterstitialAdManager>().onExternalNavigationTrigger();

    // Check if the widget is still in the tree before navigating.
    if (!context.mounted) return;

    final appState = context.read<AppBloc>().state;
    var behavior = appState.settings?.feedSettings.feedItemClickBehavior;

    // If user setting is default, fall back to remote config.
    if (behavior == FeedItemClickBehavior.defaultBehavior) {
      behavior = appState.remoteConfig?.features.feed.itemClickBehavior;
    }

    // Use the new InAppBrowser for internal navigation, otherwise use url_launcher.
    if (behavior == FeedItemClickBehavior.internalNavigation) {
      await InAppBrowser.show(
        context,
        url: headline.url,
        contentId: headline.id,
      );
    } else {
      if (await canLaunchUrl(Uri.parse(headline.url))) {
        await launchUrl(
          Uri.parse(headline.url),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  /// Handles a tap on a headline when only the ID is available.
  ///
  /// This method is used for scenarios like tapping a push notification where
  /// the full [Headline] object is not readily available. It performs the
  /// following steps:
  /// 1. Shows a temporary loading indicator.
  /// 2. Fetches the full [Headline] object from the repository using the ID.
  /// 3. Hides the loading indicator.
  /// 4. Delegates to the [handleHeadlineTap] method to perform the standard
  ///    ad trigger and URL launching logic.
  ///
  /// - [context]: The current [BuildContext] to access BLoCs and for navigation.
  /// - [headlineId]: The ID of the [Headline] item that was tapped.
  static Future<void> handleHeadlineTapById(
    BuildContext context,
    String headlineId,
  ) async {
    // Show a loading dialog that is resilient to context changes.
    final navigator = Navigator.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final headline = await context.read<DataRepository<Headline>>().read(
        id: headlineId,
      );
      if (!context.mounted) return;
      await handleHeadlineTap(context, headline);
    } finally {
      if (navigator.canPop()) navigator.pop();
    }
  }

  /// Handles a tap on a headline from a system notification.
  ///
  /// This method is specifically for taps that originate from the OS
  /// notification tray. It fetches the headline by its ID and then **always**
  /// opens it in an in-app browser, overriding any user or remote settings.
  /// This provides a smoother, more integrated user experience for notification
  /// interactions.
  ///
  /// - [context]: The current [BuildContext] to access BLoCs and for navigation.
  /// - [headlineId]: The ID of the [Headline] item that was tapped.
  /// - [notificationId]: The optional ID of the notification itself, used to
  ///   mark it as read.
  static Future<void> handleTapFromSystemNotification(
    BuildContext context,
    String headlineId, {
    String? notificationId,
  }) async {
    // If a notificationId is provided, dispatch an event to mark it as read.
    if (notificationId != null) {
      context.read<AppBloc>().add(AppNotificationTapped(notificationId));
    }

    // Show a loading dialog that is resilient to context changes.
    final navigator = Navigator.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final headline = await context.read<DataRepository<Headline>>().read(
        id: headlineId,
      );
      if (context.mounted) {
        await handleHeadlineTap(context, headline);
      }
    } finally {
      if (navigator.canPop()) navigator.pop();
    }
  }
}
