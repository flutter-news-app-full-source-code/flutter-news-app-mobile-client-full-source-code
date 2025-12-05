import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/headline_actions_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/bloc/engagement_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/view/engagement_bottom_sheet.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_actions_row}
/// A widget that displays a row of action icons for a headline feed tile.
///
/// This includes actions like like/dislike, comment, bookmark, share, and more.
/// {@endtemplate}
class HeadlineActionsRow extends StatelessWidget {
  /// {@macro headline_actions_row}
  const HeadlineActionsRow({required this.headline, super.key});

  /// The headline for which to display actions.
  final Headline headline;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EngagementBloc(
        entityId: headline.id,
        entityType: EngageableType.headline,
        engagementRepository: context.read<DataRepository<Engagement>>(),
        appBloc: context.read<AppBloc>(),
        contentLimitationService: context.read<ContentLimitationService>(),
      )..add(const EngagementStarted()),
      child: _HeadlineActionsRowView(headline: headline),
    );
  }
}

class _HeadlineActionsRowView extends StatelessWidget {
  const _HeadlineActionsRowView({required this.headline});

  final Headline headline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    final engagementState = context.watch<EngagementBloc>().state;
    final userReaction = engagementState.userEngagement?.reaction?.reactionType;
    final commentCount = engagementState.engagements
        .where((e) => e.comment != null)
        .length;
    final remoteConfig = context.select(
      (AppBloc bloc) => bloc.state.remoteConfig,
    );
    final communityConfig = remoteConfig?.features.community;

    final isCommentingEnabled =
        communityConfig?.enabled == true &&
        communityConfig?.engagement.engagementMode ==
            EngagementMode.reactionsAndComments;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _ActionButton(
                icon: userReaction == ReactionType.like
                    ? Icons.thumb_up
                    : Icons.thumb_up_outlined,
                tooltip: l10n.likeActionLabel,
                onPressed: () => context.read<EngagementBloc>().add(
                  const EngagementQuickReactionToggled(ReactionType.like),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _ActionButton(
                icon: userReaction == ReactionType.skeptical
                    ? Icons.thumb_down
                    : Icons.thumb_down_outlined,
                tooltip: l10n.dislikeActionLabel,
                onPressed: () => context.read<EngagementBloc>().add(
                  const EngagementQuickReactionToggled(ReactionType.skeptical),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (isCommentingEnabled)
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  tooltip: l10n.commentActionLabel,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => EngagementBottomSheet(headline: headline),
                  ),
                  count: commentCount,
                ),
            ],
          ),
          Row(
            children: [
              _ActionButton(
                icon: Icons.more_horiz,
                tooltip: l10n.moreActionLabel,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      HeadlineActionsBottomSheet(headline: headline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.count,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant;

    final button = IconButton(
      icon: Icon(icon, color: iconColor),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );

    if (count != null && count! > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return button;
  }
}
