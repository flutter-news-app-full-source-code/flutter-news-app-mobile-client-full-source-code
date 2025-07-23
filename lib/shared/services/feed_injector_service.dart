import 'package:core/core.dart';
import 'package:uuid/uuid.dart';

/// A service responsible for injecting various types of FeedItems (like Ads
/// and FeedActions) into a list of primary content items (e.g., Headlines).
class FeedInjectorService {
  final Uuid _uuid = const Uuid();

  /// Processes a list of [Headline] items and injects [Ad] and
  /// [FeedAction] items based on the provided configurations and user state.
  ///
  /// Parameters:
  /// - `headlines`: The list of original [Headline] items.
  /// - `user`: The current [User] object (nullable). This is used to determine
  ///   user role for ad frequency and feed action relevance.
  /// - `remoteConfig`: The application's remote configuration ([RemoteConfig]),
  ///   which contains [AdConfig] for ad injection rules and
  ///   [AccountActionConfig] for feed action rules.
  /// - `currentFeedItemCount`: The total number of items already present in the
  ///   feed before this batch of headlines is processed. This is crucial for
  ///   correctly applying ad frequency and placement intervals, especially
  ///   during pagination. Defaults to 0 for the first batch.
  ///
  /// Returns a new list of [FeedItem] objects, interspersed with ads and
  /// feed actions according to the defined logic.
  List<FeedItem> injectItems({
    required List<Headline> headlines,
    required User? user,
    required RemoteConfig remoteConfig,
    int currentFeedItemCount = 0,
  }) {
    final finalFeed = <FeedItem>[];
    var feedActionInjectedThisBatch = false;
    var headlinesInThisBatchCount = 0;
    final adConfig = remoteConfig.adConfig;
    final userRole = user?.appRole ?? AppUserRole.guestUser;

    int adFrequency;
    int adPlacementInterval;

    switch (userRole) {
      case AppUserRole.guestUser:
        adFrequency = adConfig.guestAdFrequency;
        adPlacementInterval = adConfig.guestAdPlacementInterval;
      case AppUserRole.standardUser:
        adFrequency = adConfig.authenticatedAdFrequency;
        adPlacementInterval = adConfig.authenticatedAdPlacementInterval;
      case AppUserRole.premiumUser:
        adFrequency = adConfig.premiumAdFrequency;
        adPlacementInterval = adConfig.premiumAdPlacementInterval;
    }

    // Determine if a FeedAction is due before iterating
    final feedActionToInject = _getDueFeedAction(
      user: user,
      remoteConfig: remoteConfig,
    );

    for (var i = 0; i < headlines.length; i++) {
      final headline = headlines[i];
      finalFeed.add(headline);
      headlinesInThisBatchCount++;

      final totalItemsSoFar = currentFeedItemCount + finalFeed.length;

      // 1. Inject FeedAction (if due and not already injected in this batch)
      //    Attempt to inject after the first headline of the current batch.
      if (i == 0 &&
          feedActionToInject != null &&
          !feedActionInjectedThisBatch) {
        finalFeed.add(feedActionToInject);
        feedActionInjectedThisBatch = true;
      }

      // 2. Inject Ad
      if (adFrequency > 0 && totalItemsSoFar >= adPlacementInterval) {
        if (headlinesInThisBatchCount % adFrequency == 0) {
          final adToInject = _getAdToInject();
          if (adToInject != null) {
            finalFeed.add(adToInject);
          }
        }
      }
    }
    return finalFeed;
  }

  FeedAction? _getDueFeedAction({
    required User? user,
    required RemoteConfig remoteConfig,
  }) {
    final userRole = user?.appRole ?? AppUserRole.guestUser;
    final now = DateTime.now();
    final actionConfig = remoteConfig.accountActionConfig;

    // Iterate through all possible action types to find one that is due.
    for (final actionType in FeedActionType.values) {
      final status = user?.feedActionStatus[actionType];

      // Skip if the action has already been completed.
      if (status?.isCompleted ?? false) {
        continue;
      }

      final daysBetweenActionsMap = (userRole == AppUserRole.guestUser)
          ? actionConfig.guestDaysBetweenActions
          : actionConfig.standardUserDaysBetweenActions;

      final daysThreshold = daysBetweenActionsMap[actionType];

      // Skip if there's no configuration for this action type for the user's role.
      if (daysThreshold == null) {
        continue;
      }

      final lastShown = status?.lastShownAt;

      // Check if the cooldown period has passed.
      if (lastShown == null ||
          now.difference(lastShown).inDays >= daysThreshold) {
        // Found a due action, build and return it.
        return _buildFeedActionVariant(actionType);
      }
    }

    // No actions are due at this time.
    return null;
  }

  FeedAction _buildFeedActionVariant(FeedActionType actionType) {
    String title;
    String description;
    String ctaText;
    String ctaUrl;

    // TODO(anyone): Use a random variant selection for more dynamic content.
    switch (actionType) {
      case FeedActionType.linkAccount:
        title = 'Unlock Your Full Potential!';
        description =
            'Link your account to enjoy expanded content access, keep your preferences synced, and experience a more streamlined ad display.';
        ctaText = 'Link Account & Explore';
        ctaUrl = '/authentication?context=linking';
      case FeedActionType.upgrade:
        title = 'Unlock Our Best Features!';
        description =
            'Go Premium to enjoy our most comprehensive content access, the best ad experience, and many more exclusive perks.';
        ctaText = 'Upgrade Now';
        ctaUrl = '/account/upgrade';
      case FeedActionType.rateApp:
        title = 'Enjoying the App?';
        description = 'A rating on the app store helps us grow.';
        ctaText = 'Rate Us';
        ctaUrl = '/app-store-rating'; // Placeholder
      case FeedActionType.enableNotifications:
        title = 'Stay Updated!';
        description = 'Enable notifications to get the latest news instantly.';
        ctaText = 'Enable Notifications';
        ctaUrl = '/settings/notifications';
      case FeedActionType.followTopics:
        title = 'Personalize Your Feed';
        description = 'Follow topics to see more of what you love.';
        ctaText = 'Follow Topics';
        ctaUrl = '/account/manage-followed-items/topics';
      case FeedActionType.followSources:
        title = 'Discover Your Favorite Sources';
        description = 'Follow sources to get news from who you trust.';
        ctaText = 'Follow Sources';
        ctaUrl = '/account/manage-followed-items/sources';
    }

    return FeedAction(
      id: _uuid.v4(),
      title: title,
      description: description,
      feedActionType: actionType,
      callToActionText: ctaText,
      callToActionUrl: ctaUrl,
    );
  }

  Ad? _getAdToInject() {
    // For now, return a placeholder Ad, always native.
    // In a real scenario, this would fetch from an ad network or predefined list.
    return Ad(
      id: _uuid.v4(),
      imageUrl:
          'https://via.placeholder.com/300x100.png/000000/FFFFFF?Text=Native+Placeholder+Ad',
      targetUrl: 'https://example.com/adtarget',
      adType: AdType.native,
      placement: AdPlacement.feedInlineNativeBanner,
    );
  }
}
