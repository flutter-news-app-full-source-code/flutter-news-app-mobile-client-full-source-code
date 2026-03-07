import 'dart:math';

import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:verity_mobile/feed_decorators/extensions/feed_decorator_type_l10n.dart';
import 'package:verity_mobile/feed_decorators/models/decorator_placeholder.dart';
import 'package:verity_mobile/l10n/app_localizations.dart';
import 'package:verity_mobile/router/routes.dart';

/// {@template feed_decorator_service}
/// A service responsible for injecting a placeholder for non-ad decorators
/// into a feed.
///
/// This service is part of the new, self-contained `feed_decorators` feature.
/// Its sole responsibility is to insert a single, stateless `DecoratorPlaceholder`
/// into a list of feed items at a predefined position.
///
/// It does NOT handle the logic for selecting, loading, or rendering the actual
/// decorator widget. That complex logic is fully encapsulated within the
/// `FeedDecoratorLoaderWidget`, which is rendered by the UI when it encounters
/// the placeholder injected by this service.
///
/// This approach decouples the decorator's lifecycle from the feed's cache
/// and simplifies the responsibilities of the BLoC layer.
/// {@endtemplate}
class FeedDecoratorService {
  /// {@macro feed_decorator_service}
  FeedDecoratorService({Logger? logger})
    : _logger = logger ?? Logger('FeedDecoratorService');

  final Uuid _uuid = const Uuid();
  final Logger _logger;

  /// The zero-based index in the feed where the decorator placeholder will be
  /// inserted. A value of 3 places it after the third headline.
  static const _decoratorInsertionIndex = 3;

  /// Injects a [DecoratorPlaceholder] into a list of [FeedItem]s if any
  /// decorators are enabled in the provided [remoteConfig].
  ///
  /// [feedItems]: The initial list of feed items (e.g., headlines).
  /// [remoteConfig]: The application's remote configuration, used to check if
  ///   decorators are enabled.
  ///
  /// Returns a new list of [FeedItem]s containing the original items plus the
  /// injected placeholder, if applicable.
  List<FeedItem> decorateFeed({
    required List<FeedItem> feedItems,
    required RemoteConfig remoteConfig,
  }) {
    final decoratedFeed = List<FeedItem>.from(feedItems);

    final areDecoratorsEnabled = remoteConfig.features.feed.decorators.values
        .any((config) => config.enabled);

    if (areDecoratorsEnabled) {
      _logger.info('Feed decorators enabled. Injecting placeholder.');
      final safeIndex = min(_decoratorInsertionIndex, decoratedFeed.length);
      decoratedFeed.insert(safeIndex, DecoratorPlaceholder(id: _uuid.v4()));
    } else {
      _logger.info('All feed decorators disabled. Skipping injection.');
    }

    return decoratedFeed;
  }

  /// Constructs a fully hydrated [FeedItem] for a specific decorator type.
  ///
  /// This method handles the logic for both 'callToAction' and 'contentCollection'
  /// decorators, including fetching necessary data from repositories and
  /// generating localized strings.
  Future<FeedItem?> buildDecoratorItem({
    required FeedDecoratorType decoratorType,
    required FeedDecoratorConfig decoratorConfig,
    required AppLocalizations l10n,
    required RemoteConfig remoteConfig,
    required DataRepository<Topic> topicRepository,
    required DataRepository<Source> sourceRepository,
    required UserContentPreferences? userPreferences,
  }) async {
    // Get duration for rewards if applicable
    String? rewardDuration;
    if (decoratorType == FeedDecoratorType.unlockRewards) {
      final adFreeReward =
          remoteConfig.features.rewards.rewards[RewardType.adFree];
      if (adFreeReward != null) {
        rewardDuration = l10n.rewardsDurationDays(adFreeReward.durationDays);
      }
    }

    switch (decoratorConfig.category) {
      case FeedDecoratorCategory.callToAction:
        // Determine the fixed CTA URL based on the decorator type.
        String ctaUrl;
        switch (decoratorType) {
          case FeedDecoratorType.linkAccount:
            ctaUrl = Routes.accountLinking;
          case FeedDecoratorType.unlockRewards:
            ctaUrl = '/${Routes.account}/${Routes.rewards}';
          case FeedDecoratorType.rateApp:
            ctaUrl = '#';
          case FeedDecoratorType.suggestedTopics:
          case FeedDecoratorType.suggestedSources:
            throw UnsupportedError('only CTA decorators are supported.');
        }

        return CallToActionItem(
          id: _uuid.v4(),
          decoratorType: decoratorType,
          title: decoratorType.getLocalizedTitleMap(l10n),
          description: decoratorType.getLocalizedDescriptionMap(
            l10n,
            duration: rewardDuration,
          ),
          callToActionText: decoratorType.getLocalizedCtaMap(l10n),
          callToActionUrl: ctaUrl,
        );

      case FeedDecoratorCategory.contentCollection:
        final itemsToDisplay = decoratorConfig.itemsToDisplay;
        if (itemsToDisplay == null) return null;

        final followedTopicIds =
            userPreferences?.followedTopics.map((t) => t.id).toList() ?? [];
        final followedSourceIds =
            userPreferences?.followedSources.map((s) => s.id).toList() ?? [];

        switch (decoratorType) {
          case FeedDecoratorType.suggestedTopics:
            final topics = await topicRepository.readAll(
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
              title: decoratorType.getLocalizedTitleMap(l10n),
              items: topics.items,
            );
          case FeedDecoratorType.suggestedSources:
            final sources = await sourceRepository.readAll(
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
              title: decoratorType.getLocalizedTitleMap(l10n),
              items: sources.items,
            );
          case FeedDecoratorType.linkAccount:
          case FeedDecoratorType.unlockRewards:
          case FeedDecoratorType.rateApp:
            throw UnsupportedError(
              'These decorators are not supported as ContentCollections.',
            );
        }
    }
  }
}
