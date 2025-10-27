import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/suggestion_item_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template content_collection_decorator_widget}
/// A widget to display a horizontally scrollable list of suggested content
/// (e.g., Topics or Sources).
///
/// This widget presents a title and a horizontal list of [SuggestionItemWidget]s.
/// It now includes a dismiss option in a popup menu.
/// {@endtemplate}
class ContentCollectionDecoratorWidget extends StatelessWidget {
  /// {@macro content_collection_decorator_widget}
  const ContentCollectionDecoratorWidget({
    required this.item,
    required this.onFollowToggle,
    this.onDismiss,
    super.key,
  });

  /// The [ContentCollectionItem] to display.
  final ContentCollectionItem item;

  /// Callback function when the follow/unfollow button on a suggestion item
  /// is pressed.
  final ValueSetter<FeedItem> onFollowToggle;

  /// An optional callback that is triggered when the user dismisses the
  /// decorator.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return _ContentCollectionView(
      item: item,
      onFollowToggle: onFollowToggle,
      onDismiss: onDismiss,
    );
  }
}

class _ContentCollectionView extends StatefulWidget {
  const _ContentCollectionView({
    required this.item,
    required this.onFollowToggle,
    this.onDismiss,
  });

  final ContentCollectionItem item;
  final ValueSetter<FeedItem> onFollowToggle;
  final VoidCallback? onDismiss;

  @override
  State<_ContentCollectionView> createState() => _ContentCollectionViewState();
}

class _ContentCollectionViewState extends State<_ContentCollectionView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    String getTitle() {
      switch (widget.item.decoratorType) {
        case FeedDecoratorType.suggestedTopics:
          return l10n.suggestedTopicsTitle;
        case FeedDecoratorType.suggestedSources:
          return l10n.suggestedSourcesTitle;
        // The following cases are for call-to-action types and should not
        // appear in a content collection, but we handle them gracefully.
        case FeedDecoratorType.linkAccount:
        case FeedDecoratorType.upgrade:
        case FeedDecoratorType.rateApp:
        case FeedDecoratorType.enableNotifications:
          return widget.item.title;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    getTitle(),
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onDismiss != null)
                  PopupMenuButton<void>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: l10n.decoratorDismissAction,
                    onSelected: (_) => widget.onDismiss!(),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<void>(
                        value: null,
                        child: Text(l10n.decoratorDismissAction),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Access AppBloc to get the user's content preferences,
                // which is the source of truth for followed items.
                final appState = context.watch<AppBloc>().state;
                final followedTopicIds =
                    appState.userContentPreferences?.followedTopics
                        .map((t) => t.id)
                        .toList() ??
                    [];
                final followedSourceIds =
                    appState.userContentPreferences?.followedSources
                        .map((s) => s.id)
                        .toList() ??
                    [];

                final listView = ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.item.items.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = widget.item.items[index];
                    final isFollowing =
                        (suggestion is Topic &&
                            followedTopicIds.contains(suggestion.id)) ||
                        (suggestion is Source &&
                            followedSourceIds.contains(suggestion.id));
                    return SuggestionItemWidget(
                      item: suggestion,
                      onFollowToggle: (toggledItem) {
                        final currentUserPreferences =
                            appState.userContentPreferences;
                        if (currentUserPreferences == null) return;

                        UserContentPreferences updatedPreferences;

                        if (toggledItem is Topic) {
                          updatedPreferences = currentUserPreferences
                              .toggleFollowedTopic(toggledItem);
                        } else if (toggledItem is Source) {
                          updatedPreferences = currentUserPreferences
                              .toggleFollowedSource(toggledItem);
                        } else {
                          return;
                        }

                        context.read<AppBloc>().add(
                          AppUserContentPreferencesChanged(
                            preferences: updatedPreferences,
                          ),
                        );
                      },
                      isFollowing: isFollowing,
                    );
                  },
                );

                var showStartFade = false;
                var showEndFade = false;
                if (_scrollController.hasClients &&
                    _scrollController.position.maxScrollExtent > 0) {
                  final pixels = _scrollController.position.pixels;
                  final minScroll = _scrollController.position.minScrollExtent;
                  final maxScroll = _scrollController.position.maxScrollExtent;

                  if (pixels > minScroll) {
                    showStartFade = true;
                  }
                  if (pixels < maxScroll) {
                    showEndFade = true;
                  }
                }

                final colors = <Color>[
                  if (showStartFade) Colors.transparent,
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor,
                  if (showEndFade) Colors.transparent,
                ];

                final stops = <double>[
                  if (showStartFade) 0.0,
                  if (showStartFade) 0.02 else 0.0,
                  if (showEndFade) 0.98 else 1.0,
                  if (showEndFade) 1.0,
                ];

                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: colors,
                    stops: stops,
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: listView,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
