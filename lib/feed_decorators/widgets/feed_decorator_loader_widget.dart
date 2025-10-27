import 'dart:async';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/call_to_action_decorator_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/content_collection_decorator_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/decorator_dismissed_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';

/// The internal state of the [FeedDecoratorLoaderWidget].
enum _DecoratorState {
  /// The widget is currently determining which decorator to show and loading
  /// its data.
  loading,

  /// A decorator has been successfully loaded and is ready to be displayed.
  success,

  /// The user has dismissed the decorator.
  dismissed,

  /// No decorator is due to be shown, or loading failed. The widget should
  /// render nothing.
  none,
}

/// {@template feed_decorator_loader_widget}
/// A self-contained, stateful widget that manages the entire lifecycle of a
/// single non-ad feed decorator slot.
///
/// This widget is the cornerstone of the refactored decorator architecture.
/// It is rendered when a `DecoratorPlaceholder` is encountered in the feed.
/// Its responsibilities include:
///
/// 1.  **Reading Global State:** It inspects the `AppBloc` state to determine
///     the highest-priority decorator that is currently "due" to be shown to
///     the user, based on remote configuration and user interaction history.
///
/// 2.  **Data Fetching:** If a `ContentCollection` decorator is selected, this
///     widget fetches the required content (e.g., topics, sources) from the
///     appropriate `DataRepository`.
///
/// 3.  **State Management:** It manages its own internal state (`loading`,
///     `success`, `dismissed`, `none`) to gracefully handle the entire
///     decorator lifecycle.
///
/// 4.  **Rendering:** It renders the correct widget based on its state: a
///     loading indicator, the decorator itself, a dismissal confirmation, or
///     an empty box.
///
/// 5.  **Event Dispatching:** It notifies the `AppBloc` when a decorator is
///     shown or dismissed, allowing the global user state to be updated.
///
/// This architecture completely decouples the decorator's lifecycle from the
/// feed's cache, allowing decorators to appear or disappear dynamically
/// without requiring a full feed refresh.
/// {@endtemplate}
class FeedDecoratorLoaderWidget extends StatefulWidget {
  /// {@macro feed_decorator_loader_widget}
  const FeedDecoratorLoaderWidget({super.key});

  @override
  State<FeedDecoratorLoaderWidget> createState() =>
      _FeedDecoratorLoaderWidgetState();
}

class _FeedDecoratorLoaderWidgetState extends State<FeedDecoratorLoaderWidget> {
  _DecoratorState _state = _DecoratorState.loading;
  Widget? _decoratorWidget;
  final _logger = Logger('FeedDecoratorLoaderWidget');
  final _uuid = const Uuid();

  // Defines the static priority for each feed decorator. A lower number is a
  // higher priority.
  static const _decoratorPriorities = <FeedDecoratorType, int>{
    FeedDecoratorType.linkAccount: 1,
    FeedDecoratorType.upgrade: 2,
    FeedDecoratorType.suggestedTopics: 3,
    FeedDecoratorType.suggestedSources: 4,
    FeedDecoratorType.enableNotifications: 5,
    FeedDecoratorType.rateApp: 6,
  };

  @override
  void initState() {
    super.initState();
    _loadDecorator();
  }

  Future<void> _loadDecorator() async {
    final appState = context.read<AppBloc>().state;
    final user = appState.user;
    final remoteConfig = appState.remoteConfig;

    if (user == null || remoteConfig == null) {
      _logger.warning('User or RemoteConfig is null, cannot load decorator.');
      if (mounted) setState(() => _state = _DecoratorState.none);
      return;
    }

    final dueDecoratorType = _getHighestPriorityDueDecorator(
      user: user,
      remoteConfig: remoteConfig,
    );

    if (dueDecoratorType == null) {
      _logger.info('No decorator is due to be shown.');
      if (mounted) setState(() => _state = _DecoratorState.none);
      return;
    }

    final decoratorConfig = remoteConfig.feedDecoratorConfig[dueDecoratorType];
    if (decoratorConfig == null) {
      _logger.warning('Config not found for due decorator: $dueDecoratorType');
      if (mounted) setState(() => _state = _DecoratorState.none);
      return;
    }

    final decoratorItem = await _buildDecoratorItem(
      dueDecoratorType,
      decoratorConfig,
    );

    if (decoratorItem == null) {
      _logger.info('Decorator item could not be built for $dueDecoratorType.');
      if (mounted) setState(() => _state = _DecoratorState.none);
      return;
    }

    // Dispatch event to notify that the decorator has been shown.
    context.read<AppBloc>().add(
      AppUserFeedDecoratorShown(
        userId: user.id,
        feedDecoratorType: dueDecoratorType,
      ),
    );

    // Build the final widget and update the state to success.
    if (mounted) {
      setState(() {
        if (decoratorItem is CallToActionItem) {
          _decoratorWidget = CallToActionDecoratorWidget(
            item: decoratorItem,
            onCallToAction: (url) => context.read<HeadlinesFeedBloc>().add(
              CallToActionTapped(url: url),
            ),
            onDismiss: () => _onDismissed(dueDecoratorType),
          );
        } else if (decoratorItem is ContentCollectionItem) {
          _decoratorWidget = ContentCollectionDecoratorWidget(
            item: decoratorItem,
            // The follow/unfollow logic is handled by the AppBloc listener
            // in the ContentCollectionDecoratorWidget itself.
            onFollowToggle: (_) {},
            onDismiss: () => _onDismissed(dueDecoratorType),
          );
        }
        _state = _DecoratorState.success;
      });
    }
  }

  void _onDismissed(FeedDecoratorType decoratorType) {
    _logger.info('Decorator $decoratorType dismissed by user.');
    final userId = context.read<AppBloc>().state.user?.id;
    if (userId == null) return;

    // Notify AppBloc that the action is completed.
    context.read<AppBloc>().add(
      AppUserFeedDecoratorShown(
        userId: userId,
        feedDecoratorType: decoratorType,
        isCompleted: true,
      ),
    );

    // Update internal state to show the dismissed widget.
    if (mounted) {
      setState(() => _state = _DecoratorState.dismissed);
    }
  }

  FeedDecoratorType? _getHighestPriorityDueDecorator({
    required User user,
    required RemoteConfig remoteConfig,
  }) {
    final userRole = user.appRole;
    final dueCandidates = <({FeedDecoratorType type, int priority})>[];

    for (final entry in remoteConfig.feedDecoratorConfig.entries) {
      final decoratorType = entry.key;
      final decoratorConfig = entry.value;

      if (!decoratorConfig.enabled) continue;

      final roleConfig = decoratorConfig.visibleTo[userRole];
      if (roleConfig == null) continue;

      final status = user.feedDecoratorStatus[decoratorType];
      if (status?.canBeShown(daysBetweenViews: roleConfig.daysBetweenViews) ??
          true) {
        final priority = _decoratorPriorities[decoratorType];
        if (priority != null) {
          dueCandidates.add((type: decoratorType, priority: priority));
        }
      }
    }

    if (dueCandidates.isEmpty) return null;
    dueCandidates.sort((a, b) => a.priority.compareTo(b.priority));
    return dueCandidates.first.type;
  }

  Future<FeedItem?> _buildDecoratorItem(
    FeedDecoratorType decoratorType,
    FeedDecoratorConfig decoratorConfig,
  ) async {
    // This logic is a simplified version of the original service, as the
    // content for CTAs is defined statically.
    switch (decoratorConfig.category) {
      case FeedDecoratorCategory.callToAction:
        // A map of static content for different call-to-action types.
        // TODO(fulleni): random l10n selection for each type.
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
        if (content == null) return null;
        return CallToActionItem(
          id: _uuid.v4(),
          decoratorType: decoratorType,
          title: content.title,
          description: content.description,
          callToActionText: content.ctaText,
          callToActionUrl: content.ctaUrl,
        );

      case FeedDecoratorCategory.contentCollection:
        final itemsToDisplay = decoratorConfig.itemsToDisplay;
        if (itemsToDisplay == null) return null;

        final userPreferences = context
            .read<AppBloc>()
            .state
            .userContentPreferences;
        final followedTopicIds =
            userPreferences?.followedTopics.map((t) => t.id).toList() ?? [];
        final followedSourceIds =
            userPreferences?.followedSources.map((s) => s.id).toList() ?? [];

        switch (decoratorType) {
          case FeedDecoratorType.suggestedTopics:
            final topics = await context.read<DataRepository<Topic>>().readAll(
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
            final sources = await context
                .read<DataRepository<Source>>()
                .readAll(
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
          // ignore: no_default_cases
          default:
            _logger.warning(
              'Unhandled ContentCollection decorator type: $decoratorType',
            );
            return null;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _DecoratorState.loading => const Card(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      _DecoratorState.success => _decoratorWidget ?? const SizedBox.shrink(),
      _DecoratorState.dismissed => const DecoratorDismissedWidget(),
      _DecoratorState.none => const SizedBox.shrink(),
    };
  }
}
