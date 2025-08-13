import 'dart:math';

import 'package:core/core.dart';
import 'package:uuid/uuid.dart';
import 'package:data_repository/data_repository.dart';

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
  /// Creates a [FeedDecoratorService].
  ///
  /// Requires [DataRepository] instances for [Topic] and [Source] to fetch
  /// content for collection decorators.
  FeedDecoratorService({
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Source> sourcesRepository,
  })  : _topicsRepository = topicsRepository,
        _sourcesRepository = sourcesRepository;

  final Uuid _uuid = const Uuid();
  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Source> _sourcesRepository;

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
  /// [FeedItem] decorator and multiple [Ad] items based on a robust set of rules.
  ///
  /// This method is designed to be called only on a "major" feed load (e.g.,
  /// initial load or pull-to-refresh) to ensure that a decorator is
  /// considered for injection only once per session.
  ///
  /// Returns a [FeedDecoratorResult] containing the decorated list and the
  /// decorator that was injected, if any.
  Future<FeedDecoratorResult> decorateFeed({
    required List<Headline> headlines,
    required User? user,
    required RemoteConfig remoteConfig,
  }) async {
    // The final list of items to be returned.
    final feedWithDecorators = <FeedItem>[...headlines];
    FeedItem? injectedDecorator;

    // --- Step 1: Feed Decorator Injection ---
    // Determine the highest-priority, currently-due feed decorator.
    final dueDecoratorType = _getHighestPriorityDueDecorator(
      user: user,
      remoteConfig: remoteConfig,
    );

    if (dueDecoratorType != null) {
      final decoratorConfig = remoteConfig.feedDecoratorConfig[dueDecoratorType];
      if (decoratorConfig != null) {
        // If a decorator is due, build the full FeedItem object.
        injectedDecorator = await _buildDecoratorItem(
          dueDecoratorType,
          decoratorConfig,
        );

        if (injectedDecorator != null) {
          // Inject the decorator at a fixed, predictable position.
          // We use `min` to handle cases where the headline list is very short.
          const decoratorInsertionIndex = 3;
          final safeIndex = min(decoratorInsertionIndex, feedWithDecorators.length);
          feedWithDecorators.insert(safeIndex, injectedDecorator);
        }
      }
    }

    // --- Step 2: Ad Injection ---
    // Inject ads into the list that may or may not already contain a decorator.
    final finalFeed = _injectAds(
      feedItems: feedWithDecorators,
      user: user,
      adConfig: remoteConfig.adConfig,
    );

    // --- Step 3: Return the comprehensive result ---
    return FeedDecoratorResult(
      decoratedItems: finalFeed,
      injectedDecorator: injectedDecorator,
    );
  }

  /// Injects only [Ad] items into a list of [FeedItem]s.
  ///
  /// This method is designed for pagination, where new content is added to an
  /// existing feed without re-evaluating or injecting new decorators.
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

  /// Constructs a [FeedItem] (either a [CallToActionItem] or a
  /// [ContentCollectionItem]) based on the provided decorator type
  /// and its configuration.
  ///
  /// For content collection types, this method fetches the necessary
  /// items (topics or sources) from the respective repositories.
  /// Returns `null` if a content collection cannot be populated
  /// (e.g., no items found).
  Future<FeedItem?> _buildDecoratorItem(
    FeedDecoratorType decoratorType,
    FeedDecoratorConfig decoratorConfig,
  ) async {
    switch (decoratorConfig.category) {
      case FeedDecoratorCategory.callToAction:
        final content = switch (decoratorType) {
          FeedDecoratorType.linkAccount => (
              title: 'Unlock Your Full Potential!',
              description:
                  'Link your account to enjoy expanded content access, '
                  'keep your preferences synced, and experience a more '
                  'streamlined ad display.',
              ctaText: 'Link Account & Explore',
              ctaUrl: '/authentication?context=linking'
            ),
          FeedDecoratorType.upgrade => (
              title: 'Unlock Our Best Features!',
              description:
                  'Go Premium to enjoy our most comprehensive content '
                  'access, the best ad experience, and many more '
                  'exclusive perks.',
              ctaText: 'Upgrade Now',
              ctaUrl: '/account/upgrade'
            ),
          FeedDecoratorType.rateApp => (
              title: 'Enjoying the App?',
              description: 'A rating on the app store helps us grow.',
              ctaText: 'Rate Us',
              ctaUrl: '/app-store-rating'
            ),
          FeedDecoratorType.enableNotifications => (
              title: 'Stay Updated!',
              description:
                  'Enable notifications to get the latest news instantly.',
              ctaText: 'Enable Notifications',
              ctaUrl: '/settings/notifications'
            ),
          // These types are handled by ContentCollection, but must be
          // present in the switch for exhaustiveness.
          FeedDecoratorType.suggestedTopics:
          case FeedDecoratorType.suggestedSources:
            throw StateError(
              'ContentCollection decorator type '
              '$decoratorType used in CallToAction category.',
            );
        };
        return CallToActionItem(
          id: _uuid.v4(),
          title: content.title,
          description: content.description,
          decoratorType: decoratorType,
          callToActionText: content.ctaText,
          callToActionUrl: content.ctaUrl,
        );
      case FeedDecoratorCategory.contentCollection:
        final itemsToDisplay = decoratorConfig.itemsToDisplay;
        if (itemsToDisplay == null) {
          throw StateError(
            'itemsToDisplay must be set for contentCollection.',
          );
        }
        switch (decoratorType) {
          case FeedDecoratorType.suggestedTopics:
            final topics = await _topicsRepository.readAll(
              pagination: PaginationOptions(limit: itemsToDisplay),
              sort: [const SortOption('name', SortOrder.asc)],
            );
            if (topics.items.isEmpty) return null;
            return ContentCollectionItem<Topic>(
              id: _uuid.v4(),
              decoratorType: decoratorType,
              title: 'Suggested Topics',
              items: topics.items,
            );
          case FeedDecoratorType.suggestedSources:
            final sources = await _sourcesRepository.readAll(
              pagination: PaginationOptions(limit: itemsToDisplay),
              sort: [const SortOption('name', SortOrder.asc)],
            );
            if (sources.items.isEmpty) return null;
            return ContentCollectionItem<Source>(
              id: _uuid.v4(),
              decoratorType: decoratorType,
              title: 'Suggested Sources',
              items: sources.items,
            );
          // These types are handled by CallToAction, but must be
          // present in the switch for exhaustiveness.
          case FeedDecoratorType.linkAccount:
          case FeedDecoratorType.upgrade:
          case FeedDecoratorType.rateApp:
          case FeedDecoratorType.enableNotifications:
            throw StateError(
              'CallToAction decorator type '
              '$decoratorType used in ContentCollection category.',
            );
        }
    }
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
