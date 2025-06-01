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
    // final prefs = appConfig.userPreferenceLimits; // Not using specific numbers
    // final ads = appConfig.adConfig; // Not using specific numbers
    final variant = _random.nextInt(3);

    String title;
    String description;
    String ctaText = 'Learn More'; 

    switch (variant) {
      case 0:
        title = 'Unlock Your Full Potential!';
        description =
            'Link your account to enjoy expanded content access, keep your preferences synced, and experience a more streamlined ad display.';
        ctaText = 'Link Account & Explore';
        break;
      case 1:
        title = 'Personalize Your Experience!';
        description =
            'Secure your settings and reading history across all your devices by linking your account. Enjoy a tailored news journey!';
        ctaText = 'Secure My Preferences';
        break;
      default: // case 2
        title = 'Get More From Your News!';
        description =
            'Link your account for enhanced content limits, better ad experiences, and ensure your preferences are always with you.';
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
    // final prefs = appConfig.userPreferenceLimits; // Not using specific numbers
    // final ads = appConfig.adConfig; // Not using specific numbers
    final variant = _random.nextInt(3);

    String title;
    String description;
    String ctaText = 'Explore Premium'; 

    switch (variant) {
      case 0:
        title = 'Unlock Our Best Features!';
        description =
            'Go Premium to enjoy our most comprehensive content access, the best ad experience, and many more exclusive perks.';
        ctaText = 'Upgrade Now';
        break;
      case 1:
        title = 'Elevate Your News Consumption!';
        description =
            'With Premium, your content limits are greatly expanded and you will enjoy our most favorable ad settings. Discover the difference!';
        ctaText = 'Discover Premium Benefits';
        break;
      default: // case 2
        title = 'Want More Control & Fewer Interruptions?';
        description =
            'Upgrade to Premium for a superior ad experience, massively increased content limits, and a more focused news journey.';
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
    // For now, return a placeholder Ad, always native.
    // In a real scenario, this would fetch from an ad network or predefined list.
    // final adPlacements = AdPlacement.values; // Can still use for variety if needed

    return Ad(
      // id is generated by model if not provided
      imageUrl: 'https://via.placeholder.com/300x100.png/000000/FFFFFF?Text=Native+Placeholder+Ad', // Adjusted placeholder
      targetUrl: 'https://example.com/adtarget',
      adType: AdType.native, // Always native
      // Default placement or random from native-compatible placements
      placement: AdPlacement.feedInlineNativeBanner, 
    );
  }
}
