import 'dart:math';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:logging/logging.dart';
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
/// to the user at any given time.
class _DecoratorCandidate {
  const _DecoratorCandidate(this.decoratorType, this.priority);

  /// The type of the feed decorator (e.g., `linkAccount`, `suggestedTopics`).
  final FeedDecoratorType decoratorType;

  /// The priority of the decorator. A lower number indicates a higher priority.
  final int priority;
}

/// A service responsible for decorating a primary list of feed content (e.g.,
/// headlines) with secondary items like in-feed calls-to-action and ad placeholders.
///
/// This service implements a multi-stage pipeline to ensure that the most
/// relevant and timely items are injected in a logical and non-intrusive way.
///
/// ### Ad Injection Architecture Explained
///
/// To solve lifecycle-related crashes and improve performance, the responsibility
/// for loading and managing native ads is completely decoupled from this service
/// and the BLoC layer. The architecture follows this robust, multi-step flow:
///
/// 1.  **`FeedDecoratorService` (This Class):**
///     Instead of loading and injecting fully-loaded, stateful native ad
///     objects, this service's only role is to inject simple, stateless
///     `AdPlaceholder` markers into the feed list at appropriate intervals.
///     This keeps the BLoC's state clean and lightweight. This service
///     specifically handles *inline* ad placeholders (native and banner),
///     while interstitial ads are managed separately, typically triggered
///     on route changes.
///
/// 2.  **`HeadlinesFeedPage` (UI Layer):**
///     The `ListView` in the UI receives the mixed list of content and
///     placeholders from the BLoC. When it encounters an `AdPlaceholder`, it
///     renders an `AdLoaderWidget`.
///
/// 3.  **`AdLoaderWidget` (The Ad Loader):**
///     This stateful widget is responsible for the entire lifecycle of a single
///     ad slot. It first checks the `AdCacheService` for a valid, pre-loaded
///     ad. If not found, it requests a new one from the `AdService`.
///
/// 4.  **`AdFeedItemWidget` (The Dispatcher):**
///     Once the `AdLoaderWidget` has a successfully loaded `NativeAd` object,
///     it passes this ad to the `AdFeedItemWidget`. This widget acts as a
///     dispatcher, inspecting the ad's provider type (`admob`, `local`,
///     etc.) and selecting the correct rendering widget.
///
/// 5.  **`AdmobNativeAdWidget` (The Renderer):**
///     This is the final widget in the chain, responsible for rendering the
///     actual AdMob native ad. Crucially, it no longer contains any disposal
///     logic. Its lifecycle is now entirely managed by the `AdCacheService`,
///     which prevents the ad from being disposed of when it scrolls out of
///     view, thus fixing the crash.
///
/// This architecture ensures a clean separation of concerns, improves stability,
/// and makes the ad system more maintainable and extensible.
class FeedDecoratorService {
  /// Creates a [FeedDecoratorService].
  ///
  /// Requires [DataRepository] instances for [Topic] and [Source] to fetch
  /// content for collection decorators.
  FeedDecoratorService({
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Source> sourcesRepository,
    Logger? logger,
  }) : _topicsRepository = topicsRepository,
       _sourcesRepository = sourcesRepository,
       _logger = logger ?? Logger('FeedDecoratorService');

  final Uuid _uuid = const Uuid();
  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Source> _sourcesRepository;
  final Logger _logger;

  /// The zero-based index in the feed where the decorator will be inserted.
  /// A value of 3 places it after the third headline, which is a common
  /// position for in-feed promotional content.
  /// TODO(fulleni): Make this configurable through the remote config.
  static const _decoratorInsertionIndex = 3;

  /// Defines the static priority for each feed decorator. A lower number is a
  /// higher priority. This list determines which decorator is chosen when
  /// multiple decorators are "due" at the same time.
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
  /// [FeedItem] decorator and multiple [AdPlaceholder] items based on a robust
  /// set of rules.
  ///
  /// This method is designed to be called only on a "major" feed load (e.g.,
  /// initial load or pull-to-refresh) to ensure that a decorator is
  /// considered for injection only once per session. It specifically handles
  /// the injection of *inline* ad placeholders (native and banner),
  /// while interstitial ads are managed separately.
  ///
  /// Returns a [FeedDecoratorResult] containing the decorated list and the
  /// decorator that was injected, if any.
  Future<FeedDecoratorResult> decorateFeed({
    required List<Headline> headlines,
    required User? user,
    required RemoteConfig remoteConfig,
    required List<String> followedTopicIds,
    required List<String> followedSourceIds,
    required HeadlineImageStyle imageStyle,
    required AdThemeStyle adThemeStyle,
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

    // --- Step 2: Ad Placeholder Injection ---
    // Only inject ad placeholders if ads are globally enabled and feed ads
    // are specifically enabled in the RemoteConfig.
    if (remoteConfig.adConfig.enabled &&
        remoteConfig.adConfig.feedAdConfiguration.enabled) {
      final finalFeed = await injectAdPlaceholders(
        feedItems: feedWithDecorators,
        user: user,
        adConfig: remoteConfig.adConfig,
        imageStyle: imageStyle,
        adThemeStyle: adThemeStyle,
      );
      // Replace the feedWithDecorators with the finalFeed that includes ads.
      feedWithDecorators
        ..clear()
        ..addAll(finalFeed);
    }

    // --- Step 3: Return the comprehensive result ---
    return FeedDecoratorResult(
      decoratedItems: feedWithDecorators,
      injectedDecorator: injectedDecorator,
    );
  }

  /// Determines the single highest-priority feed decorator that is currently
  /// due to be shown to the user.
  ///
  /// This method encapsulates the core business logic for decorator selection.
  /// It considers global enablement, user role visibility, and cooldown periods.
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
            ctaUrl: Routes.accountLinking,
          ),
          FeedDecoratorType.upgrade: (
            title: 'Upgrade to Premium',
            description: 'Unlock unlimited access to all features and content.',
            ctaText: 'Upgrade Now',
            ctaUrl: '/upgrade',
          ),
          FeedDecoratorType.rateApp: (
            title: 'Enjoying the App?',
            description: 'Let us know what you think by leaving a rating.',
            ctaText: 'Rate App',
            ctaUrl: '/rate-app',
          ),
          FeedDecoratorType.enableNotifications: (
            title: 'Stay Up to Date',
            description:
                'Enable notifications to get the latest headlines delivered to you.',
            ctaText: 'Enable',
            ctaUrl: '/enable-notifications',
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
                'status': ContentStatus.active.name,
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
                'status': ContentStatus.active.name,
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

  /// Injects stateless [AdPlaceholder] markers into a list of [FeedItem]s
  /// based on configured ad frequency rules.
  ///
  /// This method ensures that ad placeholders for *inline* ads (native and banner)
  /// are placed according to the `adPlacementInterval` (initial buffer before
  /// the first ad) and `adFrequency` (subsequent ad spacing). It correctly
  /// accounts for content items and decorators, ignoring previously injected
  /// ad placeholders when calculating placement.
  ///
  /// [feedItems]: The list of feed items (headlines, other decorators)
  ///   to inject ad placeholders into.
  /// [user]: The current authenticated user, used to determine ad configuration.
  /// [adConfig]: The remote configuration for ad display rules.
  /// [imageStyle]: The desired image style for the ad, used to determine
  ///   the placeholder's template type.
  /// [adThemeStyle]: The current theme style for ads, passed through to the
  ///   AdLoaderWidget for consistent styling.
  /// [processedContentItemCount]: The count of *content items* (non-ad,
  ///   non-decorator) that have already been processed in previous feed
  ///   loads/pages. This is crucial for maintaining correct ad placement
  ///   across pagination.
  ///
  /// Returns a new list of [FeedItem] objects, interspersed with ad placeholders.
  Future<List<FeedItem>> injectAdPlaceholders({
    required List<FeedItem> feedItems,
    required User? user,
    required AdConfig adConfig,
    required HeadlineImageStyle imageStyle,
    required AdThemeStyle adThemeStyle,
    int processedContentItemCount = 0,
  }) async {
    // If feed ads are not enabled in the remote config, return the original list.
    // This check is redundant here as it's already done in decorateFeed,
    // but kept for clarity and defensive programming.
    if (!adConfig.feedAdConfiguration.enabled) {
      return feedItems;
    }

    final userRole = user?.appRole ?? AppUserRole.guestUser;

    // Determine ad frequency rules based on user role.
    // Retrieve FeedAdFrequencyConfig from the visibleTo map.
    final feedAdFrequencyConfig =
        adConfig.feedAdConfiguration.visibleTo[userRole];

    // Default to 0 for adFrequency and adPlacementInterval if no config is found
    // for the user role, effectively disabling ads for that role.
    final adFrequency = feedAdFrequencyConfig?.adFrequency ?? 0;
    final adPlacementInterval = feedAdFrequencyConfig?.adPlacementInterval ?? 0;

    // If ad frequency is zero or less, no ads should be injected.
    if (adFrequency <= 0) {
      return feedItems;
    }

    final result = <FeedItem>[];
    // This counter tracks the absolute number of *content items* (headlines,
    // topics, sources, countries, and decorators) processed so far, including
    // those from previous pages. This is key for accurate ad placement.
    var currentContentItemCount = processedContentItemCount;

    // Get the primary ad platform and its identifiers
    final primaryAdPlatform = adConfig.primaryAdPlatform;
    final platformAdIdentifiers =
        adConfig.platformAdIdentifiers[primaryAdPlatform];
    if (platformAdIdentifiers == null) {
      _logger.warning(
        'No AdPlatformIdentifiers found for primary platform: $primaryAdPlatform. '
        'Cannot inject ad placeholders.',
      );
      return feedItems;
    }

    // Get the ad type for feed ads (native or banner)
    final feedAdType = adConfig.feedAdConfiguration.adType;

    for (final item in feedItems) {
      result.add(item);

      // Only increment the content item counter if the current item is
      // a primary content type or a decorator (not an ad placeholder).
      // This ensures ad placement is based purely on content/decorator density.
      if (item is! AdPlaceholder) {
        currentContentItemCount++;
      }

      // Check if an ad should be injected at the current position.
      // An ad is injected if:
      // 1. We have passed the initial placement interval.
      // 2. The number of content items *after* the initial interval is a
      //    multiple of the ad frequency.
      if (currentContentItemCount >= adPlacementInterval &&
          (currentContentItemCount - adPlacementInterval) % adFrequency == 0) {
        String? adIdentifier;

        // Determine the specific ad ID based on the feed ad type.
        switch (feedAdType) {
          case AdType.native:
            adIdentifier = platformAdIdentifiers.feedNativeAdId;
          case AdType.banner:
            adIdentifier = platformAdIdentifiers.feedBannerAdId;
          case AdType.interstitial:
          case AdType.video:
            // Interstitial and video ads are not injected into the feed.
            _logger.warning(
              'Attempted to inject $feedAdType ad into feed. This is not supported.',
            );
            adIdentifier = null;
        }

        if (adIdentifier != null) {
          // Instead of injecting a fully loaded ad, inject an AdPlaceholder.
          // This is a crucial change: the FeedDecoratorService no longer loads
          // the actual ad. It only marks a spot for an ad.
          //
          // The actual ad loading will be handled by a dedicated `AdLoaderWidget`
          // in the UI layer when this placeholder scrolls into view. This
          // decouples ad loading from the BLoC's state and allows for efficient
          // caching and disposal of native ad resources.
          result.add(
            AdPlaceholder(
              id: _uuid.v4(),
              adPlatformType: primaryAdPlatform,
              adType: feedAdType,
              adId: adIdentifier,
            ),
          );
        } else {
          _logger.warning(
            'No valid ad ID found for platform $primaryAdPlatform and type '
            '$feedAdType. Ad placeholder not injected.',
          );
        }
      }
    }
    return result;
  }
}
