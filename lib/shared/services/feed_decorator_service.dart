import 'dart:math';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
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
  /// Creates a [FeedDecoratorService].
  ///
  /// Requires [DataRepository] instances for [Topic] and [Source] to fetch
  /// content for collection decorators, and an [AdService] to inject ads.
  FeedDecoratorService({
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Source> sourcesRepository,
    required AdService adService,
  }) : _topicsRepository = topicsRepository,
       _sourcesRepository = sourcesRepository,
       _adService = adService;

  final Uuid _uuid = const Uuid();
  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Source> _sourcesRepository;
  final AdService _adService;

  // The zero-based index in the feed where the decorator will be inserted.
  // A value of 3 places it after the third headline, which is a common
  // position for in-feed promotional content.
  // TODO(fulleni): Make this configurable throu the remote config.
  static const _decoratorInsertionIndex = 3;

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
    required List<String> followedTopicIds,
    required List<String> followedSourceIds,
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
      final decoratorConfig =
          remoteConfig.feedDecoratorConfig[dueDecoratorType];
      if (decoratorConfig != null) {
        // If a decorator is due, build the full FeedItem object.
        injectedDecorator = await _buildDecoratorItem(
          dueDecoratorType,
          decoratorConfig,
          followedTopicIds: followedTopicIds,
          followedSourceIds: followedSourceIds,
        );

        if (injectedDecorator != null) {
          // Inject the decorator at a fixed, predictable position.
          // We use `min` to handle cases where the headline list is very short.
          final safeIndex = min(
            _decoratorInsertionIndex,
            feedWithDecorators.length,
          );
          feedWithDecorators.insert(safeIndex, injectedDecorator);
        }
      }
    }

    // --- Step 2: Ad Injection ---
    // Inject ads into the list that may or may not already contain a decorator.
    final finalFeed = await _injectAds(
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
  Future<List<FeedItem>> injectAds({
    required List<FeedItem> feedItems,
    required User? user,
    required AdConfig adConfig,
    int processedContentItemCount = 0,
  }) async {
    return _injectAds(
      feedItems: feedItems,
      user: user,
      adConfig: adConfig,
      processedContentItemCount: processedContentItemCount,
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
    FeedDecoratorConfig decoratorConfig, {
    required List<String> followedTopicIds,
    required List<String> followedSourceIds,
  }) async {
    switch (decoratorConfig.category) {
      case FeedDecoratorCategory.callToAction:
        // TODO(fulleni): This is a temporary measure until the content is fully driven by
        // the RemoteConfig model. Using a map centralizes the placeholder
        // content for now.
        const ctaContent = {
          FeedDecoratorType.linkAccount: (
            title: 'Create an Account',
            description:
                'Save your preferences and followed items by creating a free account.',
            ctaText: 'Get Started',
            ctaUrl: '${Routes.authentication}/${Routes.accountLinking}',
          ),
          FeedDecoratorType.upgrade: (
            title: 'Upgrade to Premium',
            description: 'Unlock unlimited access to all features and content.',
            ctaText: 'Upgrade Now',
            ctaUrl: '/upgrade', // Placeholder URL
          ),
          FeedDecoratorType.rateApp: (
            title: 'Enjoying the App?',
            description: 'Let us know what you think by leaving a rating.',
            ctaText: 'Rate App',
            ctaUrl: '/rate-app', // Placeholder URL
          ),
          FeedDecoratorType.enableNotifications: (
            title: 'Stay Up to Date',
            description:
                'Enable notifications to get the latest headlines delivered to you.',
            ctaText: 'Enable',
            ctaUrl: '/enable-notifications', // Placeholder URL
          ),
        };

        final content = ctaContent[decoratorType];

        // If content for the decorator type is not defined, return null.
        if (content == null) {
          return null;
        }

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
          throw StateError('itemsToDisplay must be set for contentCollection.');
        }
        switch (decoratorType) {
          case FeedDecoratorType.suggestedTopics:
            final topics = await _topicsRepository.readAll(
              pagination: PaginationOptions(limit: itemsToDisplay),
              sort: [const SortOption('name', SortOrder.asc)],
              filter: {
                '_id': {r'$nin': followedTopicIds},
              },
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
              filter: {
                '_id': {r'$nin': followedSourceIds},
              },
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
          case FeedDecoratorType.linkAccount ||
              FeedDecoratorType.upgrade ||
              FeedDecoratorType.rateApp ||
              FeedDecoratorType.enableNotifications:
            throw StateError(
              'CallToAction decorator type '
              '$decoratorType used in ContentCollection category.',
            );
        }
    }
  }

  /// Injects ads into a list of [FeedItem]s based on frequency rules.
  ///
  /// This method ensures that ads are placed according to the `adPlacementInterval`
  /// (initial buffer before the first ad) and `adFrequency` (subsequent ad spacing).
  /// It correctly accounts for content items only, ignoring previously injected ads
  /// when calculating placement.
  ///
  /// [feedItems]: The list of feed items (headlines, decorators) to inject ads into.
  /// [user]: The current authenticated user, used to determine ad configuration.
  /// [adConfig]: The remote configuration for ad display rules.
  /// [processedContentItemCount]: The count of *content items* (non-ad, non-decorator)
  ///   that have already been processed in previous feed loads/pages. This is
  ///   crucial for maintaining correct ad placement across pagination.
  ///
  /// Returns a new list of [FeedItem] objects, interspersed with ads.
  Future<List<FeedItem>> _injectAds({
    required List<FeedItem> feedItems,
    required User? user,
    required AdConfig adConfig,
    int processedContentItemCount = 0,
  }) async {
    final userRole = user?.appRole ?? AppUserRole.guestUser;

    // Determine ad frequency rules based on user role.
    final (adFrequency, adPlacementInterval) = switch (userRole) {
      AppUserRole.guestUser => (
        adConfig.guestAdFrequency,
        adConfig.guestAdPlacementInterval,
      ),
      AppUserRole.standardUser => (
        adConfig.authenticatedAdFrequency,
        adConfig.authenticatedAdPlacementInterval,
      ),
      AppUserRole.premiumUser => (
        adConfig.premiumAdFrequency,
        adConfig.premiumAdPlacementInterval,
      ),
    };

    // If ad frequency is zero or less, no ads should be injected.
    if (adFrequency <= 0) {
      return feedItems;
    }

    final result = <FeedItem>[];
    // This counter tracks the absolute number of *content items* (headlines,
    // topics, sources, countries) processed so far, including those from
    // previous pages. This is key for accurate ad placement.
    var currentContentItemCount = processedContentItemCount;

    for (final item in feedItems) {
      result.add(item);

      // Only increment the content item counter if the current item is
      // a primary content type (not an ad or a decorator).
      // This ensures ad placement is based purely on content density.
      if (item is Headline ||
          item is Topic ||
          item is Source ||
          item is Country) {
        currentContentItemCount++;
      }

      // Check if an ad should be injected at the current position.
      // An ad is injected if:
      // 1. We have passed the initial placement interval.
      // 2. The number of content items *after* the initial interval is a
      //    multiple of the ad frequency.
      if (currentContentItemCount >= adPlacementInterval &&
          (currentContentItemCount - adPlacementInterval) % adFrequency == 0) {
        // Request an ad from the AdService.
        final adToInject = await _adService.getAd();
        if (adToInject != null) {
          result.add(adToInject);
        }
      }
    }
    return result;
  }
}
