import 'dart:async';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/extensions/feed_decorator_type_l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/call_to_action_decorator_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/content_collection_decorator_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
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

  /// Flag to ensure the decorator loading logic is dispatched only once
  /// during the initial widget lifecycle.
  bool _isDecoratorLoadDispatched = false;

  // Defines the static priority for each feed decorator. A lower number is a
  // higher priority.
  static const _decoratorPriorities = <FeedDecoratorType, int>{
    FeedDecoratorType.linkAccount: 1,
    FeedDecoratorType.upgrade: 2,
    // Suggested topics and sources are content collections, which are
    // generally lower priority than direct calls to action.
    FeedDecoratorType.suggestedTopics: 3,
    FeedDecoratorType.suggestedSources: 4,
    FeedDecoratorType.enableNotifications: 5,
    FeedDecoratorType.rateApp: 6,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load the decorator only once after dependencies are available.
    if (!_isDecoratorLoadDispatched) {
      _loadDecorator();
      _isDecoratorLoadDispatched = true;
    }
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

    final decoratorConfig =
        remoteConfig.features.feed.decorators[dueDecoratorType];
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
    // Guard the context access with a mounted check.
    if (mounted) {
      context.read<AppBloc>().add(
        AppUserFeedDecoratorShown(
          userId: user.id,
          feedDecoratorType: dueDecoratorType,
        ),
      );
    }
    // Build the final widget and update the state to success.
    if (mounted) {
      setState(() {
        if (decoratorItem is CallToActionItem) {
          _decoratorWidget = CallToActionDecoratorWidget(
            item: decoratorItem,
            onCallToAction: (url) {
              // Only dispatch the event if the URL is not the placeholder '#',
              // effectively disabling the button for unimplemented features.
              if (url != '#') {
                context.read<HeadlinesFeedBloc>().add(
                  CallToActionTapped(url: url),
                );
              }
              // TODO(fulleni): Implement navigation for upgrade, rateApp, etc.
            },
            onDismiss: () => _onDismissed(dueDecoratorType),
          );
        } else if (decoratorItem is ContentCollectionItem) {
          _decoratorWidget = ContentCollectionDecoratorWidget(
            item: decoratorItem,
            // The onFollowToggle callback is handled by this widget, which
            // then dispatches an event to the AppBloc to update user preferences.
            onFollowToggle: _onFollowToggle,
            onDismiss: () => _onDismissed(dueDecoratorType),
          );
        }
        _state = _DecoratorState.success;
      });
    }
  }

  /// Handles the toggling of follow/unfollow status for a [FeedItem]
  /// (either [Topic] or [Source]) within a content collection decorator.
  ///
  /// This method updates the [UserContentPreferences] in the [AppBloc]
  /// by creating a new preferences object with the modified followed list
  /// and dispatching an [AppUserContentPreferencesChanged] event.
  ///
  /// The logic here ensures that the UI layer (this widget) constructs the
  /// desired new state, and the [AppBloc] is responsible for persisting it,
  /// maintaining consistency with the `AppSettingsChanged` pattern.
  Future<void> _onFollowToggle(FeedItem item) async {
    _logger.fine(
      '[FeedDecoratorLoaderWidget] _onFollowToggle called for item of type: ${item.runtimeType}',
    );

    final appBlocState = context.read<AppBloc>().state;
    final userContentPreferences = appBlocState.userContentPreferences;

    // Guard against null preferences. This should ideally not happen if
    // initialization is complete, but it's a safeguard.
    if (userContentPreferences == null) {
      _logger.warning(
        '[FeedDecoratorLoaderWidget] Cannot toggle follow status: '
        'UserContentPreferences are null.',
      );
      return;
    }

    final l10n = AppLocalizationsX(context).l10n;

    try {
      if (item is Topic) {
        final topic = item;
        final currentFollowedTopics = List<Topic>.from(
          userContentPreferences.followedTopics,
        );
        final isFollowing = currentFollowedTopics.any((t) => t.id == topic.id);

        if (isFollowing) {
          currentFollowedTopics.removeWhere((t) => t.id == topic.id);
        } else {
          final limitationService = context.read<ContentLimitationService>();
          final status = await limitationService.checkAction(
            ContentAction.followTopic,
          );
          if (status != LimitationStatus.allowed) {
            if (mounted) {
              await showModalBottomSheet<void>(
                context: context,
                builder: (_) => ContentLimitationBottomSheet(
                  title: l10n.limitReachedTitle,
                  body: l10n.limitReachedBodyFollow,
                  buttonText: l10n.manageMyContentButton,
                ),
              );
            }
            return;
          }
          currentFollowedTopics.add(topic);
        }
        context.read<AppBloc>().add(
          AppUserContentPreferencesChanged(
            preferences: userContentPreferences.copyWith(
              followedTopics: currentFollowedTopics,
            ),
          ),
        );
      } else if (item is Source) {
        final source = item;
        final currentFollowedSources = List<Source>.from(
          userContentPreferences.followedSources,
        );
        final isFollowing = currentFollowedSources.any(
          (s) => s.id == source.id,
        );

        if (isFollowing) {
          currentFollowedSources.removeWhere((s) => s.id == source.id);
        } else {
          final limitationService = context.read<ContentLimitationService>();
          final status = await limitationService.checkAction(
            ContentAction.followSource,
          );
          if (status != LimitationStatus.allowed) {
            if (mounted) {
              await showModalBottomSheet<void>(
                context: context,
                builder: (_) => ContentLimitationBottomSheet(
                  title: l10n.limitReachedTitle,
                  body: l10n.limitReachedBodyFollow,
                  buttonText: l10n.manageMyContentButton,
                ),
              );
            }
            return;
          }
          currentFollowedSources.add(source);
        }
        context.read<AppBloc>().add(
          AppUserContentPreferencesChanged(
            preferences: userContentPreferences.copyWith(
              followedSources: currentFollowedSources,
            ),
          ),
        );
      } else {
        _logger.warning(
          '[FeedDecoratorLoaderWidget] Unsupported FeedItem type for follow toggle: ${item.runtimeType}',
        );
      }
    } on ForbiddenException catch (e) {
      if (mounted) {
        await showModalBottomSheet<void>(
          context: context,
          builder: (_) => ContentLimitationBottomSheet(
            title: l10n.limitReachedTitle,
            body: e.message,
            buttonText: l10n.gotItButton,
          ),
        );
      }
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

    // Update internal state to hide the widget completely.
    if (mounted) {
      setState(() => _state = _DecoratorState.none);
    }
  }

  FeedDecoratorType? _getHighestPriorityDueDecorator({
    required User user,
    required RemoteConfig remoteConfig,
  }) {
    final userRole = user.appRole;
    final dueCandidates = <({FeedDecoratorType type, int priority})>[];

    for (final entry in remoteConfig.features.feed.decorators.entries) {
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
    // Access localization strings for dynamic text.
    final l10n = AppLocalizationsX(context).l10n;

    // This logic is a simplified version of the original service, as the
    // content for CTAs is defined statically.
    switch (decoratorConfig.category) {
      case FeedDecoratorCategory.callToAction:
        // Determine the fixed CTA URL based on the decorator type.
        // This is a route and not a localized string.
        String ctaUrl;
        switch (decoratorType) {
          case FeedDecoratorType.linkAccount:
            ctaUrl = Routes.accountLinking;
          // Set a placeholder URL for unimplemented features. The button will be
          // disabled in the UI, so this URL will not be used.
          case FeedDecoratorType.upgrade:
          case FeedDecoratorType.rateApp:
          case FeedDecoratorType.enableNotifications:
            ctaUrl = '#';
          case FeedDecoratorType.suggestedTopics:
          case FeedDecoratorType.suggestedSources:
            throw UnsupportedError('only CTA decorators are supported.');
        }

        // Construct the CallToActionItem using randomized localized strings
        // from the extension and the determined CTA URL.
        return CallToActionItem(
          id: _uuid.v4(),
          decoratorType: decoratorType,
          title: decoratorType.getRandomTitle(l10n),
          description: decoratorType.getRandomDescription(l10n),
          callToActionText: decoratorType.getRandomCtaText(l10n),
          callToActionUrl: ctaUrl,
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
              title: decoratorType.getRandomTitle(l10n),
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
              title: decoratorType.getRandomTitle(l10n),
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
      _DecoratorState.none => const SizedBox.shrink(),
    };
  }
}
