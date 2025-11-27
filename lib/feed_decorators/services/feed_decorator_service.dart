import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/models/decorator_placeholder.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

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
}
