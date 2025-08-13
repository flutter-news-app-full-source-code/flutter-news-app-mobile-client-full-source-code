import 'dart:math';

import 'package:core/core.dart';
import 'package:uuid/uuid.dart';

/// A result object returned by the [FeedDecoratorService].
///
/// This class encapsulates the results of the decoration process, providing
/// both the final, mixed list of feed items and a reference to the specific
/// decorator item that was injected during the process. This allows the calling
/// logic (e.g., a BLoC) to know which decorator was shown to the user and
/// trigger necessary side effects, such as updating the `lastShownAt`
/// timestamp.
class FeedDecoratorResult {
  /// Creates a [FeedDecoratorResult].
  const FeedDecoratorResult({
    required this.decoratedItems,
    this.injectedDecorator,
  });

  /// The final list of [FeedItem]s, including original content (like
  /// headlines) and any injected items (ads, decorators).
  final List<FeedItem> decoratedItems;

  /// The specific decorator [FeedItem] that was injected into the feed.
  ///
  /// This can be a [CallToActionItem] or a [ContentCollectionItem].
  /// It is `null` if no decorator was due or injected during this pass.
  final FeedItem? injectedDecorator;
}

/// A private helper class to represent a potential decorator candidate for
/// injection.
///
/// It pairs the [FeedDecoratorType] with a priority score, allowing for a clear
/// and maintainable way to rank and select the most important decorator to show
// to the user at any given time.
class _DecoratorCandidate {
  const _DecoratorCandidate(this.decoratorType, this.priority);

  /// The type of the feed decorator (e.g., `linkAccount`, `suggestedTopics`).
  final FeedDecoratorType decoratorType;

  /// The priority of the decorator. A lower number indicates a higher priority.
  final int priority;
}

/// A service responsible for decorating a primary list of feed content (e.g.,
/// headlines) with secondary items like in-feed calls-to-action and ads.
///
/// This service implements a multi-stage pipeline to ensure that the most
/// relevant and timely items are injected in a logical and non-intrusive way.
class FeedDecoratorService {
  final Uuid _uuid = const Uuid();

  // Defines the static priority for each feed decorator. A lower number is a
  // higher priority. This list determines which decorator is chosen when
  // multiple decorators are "due" at the same time.
  static const _decoratorPriorities = <FeedDecoratorType, int>{
    // Highest priority: encourage anonymous users to create an account.
    FeedDecoratorType.linkAccount: 1,
    // High priority: encourage standard users to upgrade.
    FeedDecoratorType.upgrade: 2,
    // Medium priority: encourage users to follow content to personalize feed.
    FeedDecoratorType.suggestedTopics: 3,
    FeedDecoratorType.suggestedSources: 4,
    // Lower priority: engagement actions.
    FeedDecoratorType.enableNotifications: 5,
    FeedDecoratorType.rateApp: 6,
  };

  /// Processes a list of [Headline] items and injects a single, high-priority
  /// [FeedAction] and multiple [Ad] items based on a robust set of rules.
  ///
  /// This method is designed to be called only on a "major" feed load (e.g.,
  /// initial load or pull-to-refresh) to ensure that a `FeedAction` is
  /// considered for injection only once per session.
  ///
  /// Returns a [FeedDecoratorResult] containing the decorated list and the
  /// action that was injected, if any.
  FeedDecoratorResult decorateFeed({
    required List<Headline> headlines,
    required User? user,
    required RemoteConfig remoteConfig,
  }) {
    // The final list of items to be returned.
    final feedWithActions = <FeedItem>[...headlines];
    FeedAction? injectedAction;

    // --- Step 1: FeedAction Injection ---
    // Determine the highest-priority, currently-due feed action.
    final dueActionType = _getHighestPriorityDueAction(
      user: user,
      remoteConfig: remoteConfig,
    );

    if (dueActionType != null) {
      // If an action is due, build the full FeedAction object.
      injectedAction = _buildFeedActionVariant(dueActionType);

      // Inject the action at a fixed, predictable position for consistency.
      // We use `min` to handle cases where the headline list is very short.
      const actionInsertionIndex = 3;
      final safeIndex = min(actionInsertionIndex, feedWithActions.length);
      feedWithActions.insert(safeIndex, injectedAction);
    }

    // --- Step 2: Ad Injection ---
    // Inject ads into the list that may or may not already contain a FeedAction.
    final finalFeed = _injectAds(
      feedItems: feedWithActions,
      user: user,
      adConfig: remoteConfig.adConfig,
    );

    // --- Step 3: Return the comprehensive result ---
    return FeedDecoratorResult(
      decoratedItems: finalFeed,
      injectedAction: injectedAction,
    );
  }

  /// Injects only [Ad] items into a list of [FeedItem]s.
  ///
  /// This method is designed for pagination, where new content is added to an
  /// existing feed without re-evaluating or injecting new `FeedAction`s.
  ///
  /// Returns a new list of [FeedItem] objects, interspersed with ads.
  List<FeedItem> injectAds({
    required List<FeedItem> feedItems,
    required User? user,
    required AdConfig adConfig,
    int currentFeedItemCount = 0,
  }) {
    return _injectAds(
      feedItems: feedItems,
      user: user,
      adConfig: adConfig,
      currentFeedItemCount: currentFeedItemCount,
    );
  }

  /// Determines the single highest-priority feed decorator that is currently
  /// due to be shown to the user.
  ///
  /// This method encapsulates the core business logic for decorator selection.
  FeedDecoratorType? _getHighestPriorityDueDecorator({
    required User? user,
    required RemoteConfig remoteConfig,
  }) {
    final userRole = user?.appRole ?? AppUserRole.guestUser;
    final dueCandidates = <_DecoratorCandidate>[];

    // Iterate through all configured decorators to find which ones are eligible.
    for (final entry in remoteConfig.feedDecoratorConfig.entries) {
      final decoratorType = entry.key;
      final decoratorConfig = entry.value;

      // RULE 1: The decorator must be globally enabled.
      if (!decoratorConfig.enabled) {
        continue;
      }

      // RULE 2: The decorator must be configured to be visible for the
      // current user's role.
      final roleConfig = decoratorConfig.visibleTo[userRole];
      if (roleConfig == null) {
        continue;
      }

      // Get the user's specific status for this decorator.
      final status = user?.feedDecoratorStatus[decoratorType];

      // RULE 3: The decorator must be eligible to be shown based on the
      // user's interaction history and the configured cooldown period.
      // The `canBeShown` method handles completion status and cooldown logic.
      if (status?.canBeShown(daysBetweenViews: roleConfig.daysBetweenViews) ??
          true) {
        final priority = _decoratorPriorities[decoratorType];
        if (priority != null) {
          dueCandidates.add(_DecoratorCandidate(decoratorType, priority));
        }
      }
    }

    // If no decorators are due, return null.
    if (dueCandidates.isEmpty) {
      return null;
    }

    // Sort candidates by priority (lower number is higher priority).
    dueCandidates.sort((a, b) => a.priority.compareTo(b.priority));

    // Return the type of the highest-priority candidate.
    return dueCandidates.first.decoratorType;
  }

  /// Injects ads into a list of feed items based on frequency rules.
  List<FeedItem> _injectAds({
    required List<FeedItem> feedItems,
    required User? user,
    required AdConfig adConfig,
    int currentFeedItemCount = 0,
  }) {
    final userRole = user?.appRole ?? AppUserRole.guestUser;

    // Determine ad frequency rules based on user role.
    final (adFrequency, adPlacementInterval) = switch (userRole) {
      AppUserRole.guestUser =>
        (adConfig.guestAdFrequency, adConfig.guestAdPlacementInterval),
      AppUserRole.standardUser => (
          adConfig.authenticatedAdFrequency,
          adConfig.authenticatedAdPlacementInterval
        ),
      AppUserRole.premiumUser =>
        (adConfig.premiumAdFrequency, adConfig.premiumAdPlacementInterval),
    };

    // If ad frequency is zero or less, no ads should be injected.
    if (adFrequency <= 0) {
      return feedItems;
    }

    final result = <FeedItem>[];
    var headlinesInBatch = 0;

    for (final item in feedItems) {
      result.add(item);
      headlinesInBatch++;

      // Calculate the total number of items processed so far, including
      // those from previous pages.
      final totalItemsSoFar = currentFeedItemCount + result.length;

      // Check if an ad should be injected.
      // The total number of items must be past the initial placement interval,
      // AND the number of content items in this batch must meet the frequency.
      if (totalItemsSoFar >= adPlacementInterval &&
          headlinesInBatch % adFrequency == 0) {
        final adToInject = _getAdToInject();
        if (adToInject != null) {
          result.add(adToInject);
        }
      }
    }
    return result;
  }

  /// Constructs a [FeedAction] object with predefined content.
  ///
  /// In a real-world app, this content might come from a remote source.
  FeedAction _buildFeedActionVariant(FeedActionType actionType) {
    final content = switch (actionType) {
      FeedActionType.linkAccount => (
          title: 'Unlock Your Full Potential!',
          description:
              'Link your account to enjoy expanded content access, keep your preferences synced, and experience a more streamlined ad display.',
          ctaText: 'Link Account & Explore',
          ctaUrl: '/authentication?context=linking'
        ),
      FeedActionType.upgrade => (
          title: 'Unlock Our Best Features!',
          description:
              'Go Premium to enjoy our most comprehensive content access, the best ad experience, and many more exclusive perks.',
          ctaText: 'Upgrade Now',
          ctaUrl: '/account/upgrade'
        ),
      FeedActionType.rateApp => (
          title: 'Enjoying the App?',
          description: 'A rating on the app store helps us grow.',
          ctaText: 'Rate Us',
          ctaUrl: '/app-store-rating'
        ),
      FeedActionType.enableNotifications => (
          title: 'Stay Updated!',
          description: 'Enable notifications to get the latest news instantly.',
          ctaText: 'Enable Notifications',
          ctaUrl: '/settings/notifications'
        ),
      FeedActionType.followTopics => (
          title: 'Personalize Your Feed',
          description: 'Follow topics to see more of what you love.',
          ctaText: 'Follow Topics',
          ctaUrl: '/account/manage-followed-items/topics'
        ),
      FeedActionType.followSources => (
          title: 'Discover Your Favorite Sources',
          description: 'Follow sources to get news from who you trust.',
          ctaText: 'Follow Sources',
          ctaUrl: '/account/manage-followed-items/sources'
        ),
    };

    return FeedAction(
      id: _uuid.v4(),
      title: content.title,
      description: content.description,
      feedActionType: actionType,
      callToActionText: content.ctaText,
      callToActionUrl: content.ctaUrl,
    );
  }

  /// Constructs a placeholder [Ad] object.
  ///
  /// In a real scenario, this would fetch from an ad network SDK.
  Ad? _getAdToInject() {
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
