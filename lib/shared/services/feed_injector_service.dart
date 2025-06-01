import 'dart:math';

import 'package:ht_shared/ht_shared.dart';

/// A service responsible for injecting various types of FeedItems (like Ads
/// and AccountActions) into a list of primary content items (e.g., Headlines).
class FeedInjectorService {
  final Random _random = Random();

  /// Processes a list of [Headline] items and injects [Ad] and
  /// [AccountAction] items based on the provided configurations and user state.
  ///
  /// Parameters:
  /// - `headlines`: The list of original [Headline] items.
  /// - `user`: The current [User] object (nullable). This is used to determine
  ///   user role for ad frequency and account action relevance.
  /// - `appConfig`: The application's configuration ([AppConfig]), which contains
  ///   [AdConfig] for ad injection rules and [AccountActionConfig] for
  ///   account action rules.
  /// - `currentFeedItemCount`: The total number of items already present in the
  ///   feed before this batch of headlines is processed. This is crucial for
  ///   correctly applying ad frequency and placement intervals, especially
  ///   during pagination. Defaults to 0 for the first batch.
  ///
  /// Returns a new list of [FeedItem] objects, interspersed with ads and
  /// account actions according to the defined logic.
  List<FeedItem> injectItems({
    required List<Headline> headlines,
    required User? user,
    required AppConfig appConfig,
    int currentFeedItemCount = 0,
  }) {
    final List<FeedItem> finalFeed = [];
    bool accountActionInjectedThisBatch = false;
    int headlinesInThisBatchCount = 0;
    final adConfig = appConfig.adConfig;
    final userRole = user?.role ?? UserRole.guestUser;

    int adFrequency;
    int adPlacementInterval;

    switch (userRole) {
      case UserRole.guestUser:
        adFrequency = adConfig.guestAdFrequency;
        adPlacementInterval = adConfig.guestAdPlacementInterval;
        break;
      case UserRole.standardUser: // Assuming 'authenticated' maps to standard
        adFrequency = adConfig.authenticatedAdFrequency;
        adPlacementInterval = adConfig.authenticatedAdPlacementInterval;
        break;
      case UserRole.premiumUser:
        adFrequency = adConfig.premiumAdFrequency;
        adPlacementInterval = adConfig.premiumAdPlacementInterval;
        break;
      default: // For any other roles, or if UserRole enum expands
        adFrequency = adConfig.guestAdFrequency; // Default to guest ads
        adPlacementInterval = adConfig.guestAdPlacementInterval;
        break;
    }

    // Determine if an AccountAction is due before iterating
    final accountActionToInject = _getDueAccountActionDetails(
      user: user,
      appConfig: appConfig,
    );

    for (int i = 0; i < headlines.length; i++) {
      final headline = headlines[i];
      finalFeed.add(headline);
      headlinesInThisBatchCount++;
      
      final totalItemsSoFar = currentFeedItemCount + finalFeed.length;

      // 1. Inject AccountAction (if due and not already injected in this batch)
      //    Attempt to inject after the first headline of the current batch.
      if (i == 0 &&
          accountActionToInject != null &&
          !accountActionInjectedThisBatch) {
        finalFeed.add(accountActionToInject);
        accountActionInjectedThisBatch = true;
        // Note: AccountAction also counts as an item for ad placement interval
      }

      // 2. Inject Ad
      if (adFrequency > 0 && totalItemsSoFar >= adPlacementInterval) {
        // Check frequency against headlines processed *in this batch* after interval met
        // This is a simplified local frequency. A global counter might be needed for strict global frequency.
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

  AccountAction? _getDueAccountActionDetails({
    required User? user,
    required AppConfig appConfig,
  }) {
    final userRole = user?.role ?? UserRole.guestUser; // Default to guest if user is null
    final now = DateTime.now();
    final lastActionShown = user?.lastAccountActionShownAt;
    final daysBetweenActionsConfig = appConfig.accountActionConfig;

    int daysThreshold;
    AccountActionType? actionType;

    if (userRole == UserRole.guestUser) {
      daysThreshold = daysBetweenActionsConfig.guestDaysBetweenAccountActions;
      actionType = AccountActionType.linkAccount;
    } else if (userRole == UserRole.standardUser) {
      // Assuming standardUser is the target for upgrade prompts
      daysThreshold = daysBetweenActionsConfig.standardUserDaysBetweenAccountActions;
      actionType = AccountActionType.upgrade;
    } else {
      // No account actions for premium users or other roles for now
      return null;
    }

    if (lastActionShown == null ||
        now.difference(lastActionShown).inDays >= daysThreshold) {
      if (actionType == AccountActionType.linkAccount) {
        return _buildLinkAccountActionVariant(appConfig);
      } else if (actionType == AccountActionType.upgrade) {
        return _buildUpgradeAccountActionVariant(appConfig);
      }
    }
    return null;
  }

  AccountAction _buildLinkAccountActionVariant(AppConfig appConfig) {
    final prefs = appConfig.userPreferenceLimits;
    final ads = appConfig.adConfig;
    final variant = _random.nextInt(3);

    String title;
    String description;
    String ctaText = 'Learn More'; // Generic CTA

    switch (variant) {
      case 0:
        title = 'Unlock More Features!';
        description =
            'Link your account to save up to ${prefs.authenticatedSavedHeadlinesLimit} headlines and follow ${prefs.authenticatedFollowedItemsLimit} topics. Plus, enjoy a less frequent ad experience!';
        ctaText = 'Link Account & Explore';
        break;
      case 1:
        title = 'Keep Your Preferences Safe!';
        description =
            'By linking your account, your followed items (up to ${prefs.authenticatedFollowedItemsLimit}) and saved articles (up to ${prefs.authenticatedSavedHeadlinesLimit}) are synced across devices.';
        ctaText = 'Secure My Preferences';
        break;
      default: // case 2
        title = 'Enhance Your News Journey!';
        description =
            'Get more out of your feed. Link your account for higher content limits (save ${prefs.authenticatedSavedHeadlinesLimit}, follow ${prefs.authenticatedFollowedItemsLimit}) and see ads less often (currently every ${ads.guestAdFrequency} items, improves with linking).';
        ctaText = 'Get Started';
        break;
    }

    return AccountAction(
      title: title,
      description: description,
      accountActionType: AccountActionType.linkAccount,
      callToActionText: ctaText,
      // The actual navigation for linking is typically handled by the UI
      // when this action item is tapped. The URL can be a deep link or a route.
      callToActionUrl: '/authentication?context=linking',
    );
  }

  AccountAction _buildUpgradeAccountActionVariant(AppConfig appConfig) {
    final prefs = appConfig.userPreferenceLimits;
    final ads = appConfig.adConfig;
    final variant = _random.nextInt(3);

    String title;
    String description;
    String ctaText = 'Explore Premium'; // Generic CTA

    switch (variant) {
      case 0:
        title = 'Go Premium for the Ultimate Experience!';
        description =
            'Upgrade to enjoy an ad-free feed (or significantly fewer ads: ${ads.premiumAdFrequency} vs ${ads.authenticatedAdFrequency} items), save up to ${prefs.premiumSavedHeadlinesLimit} headlines, and follow ${prefs.premiumFollowedItemsLimit} interests!';
        ctaText = 'Upgrade Now';
        break;
      case 1:
        title = 'Maximize Your Content Access!';
        description =
            'With Premium, your limits expand! Follow ${prefs.premiumFollowedItemsLimit} sources/categories and save ${prefs.premiumSavedHeadlinesLimit} articles. Experience our best ad settings.';
        ctaText = 'Discover Premium Benefits';
        break;
      default: // case 2
        title = 'Tired of Ads? Want More Saves?';
        description =
            'Upgrade to Premium for a superior ad experience (frequency: ${ads.premiumAdFrequency}) and massively increased limits: save ${prefs.premiumSavedHeadlinesLimit} headlines & follow ${prefs.premiumFollowedItemsLimit} items.';
        ctaText = 'Yes, Upgrade Me!';
        break;
    }
    return AccountAction(
      title: title,
      description: description,
      accountActionType: AccountActionType.upgrade,
      callToActionText: ctaText,
      // URL could point to a subscription page/flow
      callToActionUrl: '/account/upgrade', // Placeholder route
    );
  }

  // Placeholder for _getAdToInject
  Ad? _getAdToInject() {
    // For now, return a placeholder Ad.
    // In a real scenario, this would fetch from an ad network or predefined list.
    final adTypes = AdType.values;
    final adPlacements = AdPlacement.values;

    return Ad(
      // id is generated by model if not provided
      imageUrl: 'https://via.placeholder.com/300x250.png/000000/FFFFFF?Text=Placeholder+Ad',
      targetUrl: 'https://example.com/adtarget',
      adType: adTypes[_random.nextInt(adTypes.length)],
      placement: adPlacements[_random.nextInt(adPlacements.length)],
    );
  }
}
