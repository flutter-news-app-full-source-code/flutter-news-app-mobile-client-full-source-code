import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/view/comments_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/widgets/inline_reaction_selector.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_actions_row}
/// A widget that displays a row of engagement actions for a headline tile.
/// This includes the inline reaction selector and a button to view comments.
/// {@endtemplate}
class HeadlineActionsRow extends StatelessWidget {
  /// {@macro headline_actions_row}
  const HeadlineActionsRow({
    required this.headline,
    required this.engagements,
    super.key,
  });

  /// The headline for which to display actions.
  final Headline headline;

  /// The list of engagements for this headline.
  final List<Engagement> engagements;

  @override
  Widget build(BuildContext context) {
    return _HeadlineActionsRowView(
      headline: headline,
      engagements: engagements,
    );
  }
}

class _HeadlineActionsRowView extends StatelessWidget {
  const _HeadlineActionsRowView({
    required this.headline,
    required this.engagements,
  });

  final Headline headline;
  final List<Engagement> engagements;

  @override
  Widget build(BuildContext context) {
    final remoteConfig = context.select(
      (AppBloc bloc) => bloc.state.remoteConfig,
    );
    final communityConfig = remoteConfig?.features.community;

    // If the community feature is disabled, show nothing.
    if (communityConfig?.enabled != true) {
      return const SizedBox.shrink();
    }

    final isCommentingEnabled =
        communityConfig!.engagement.engagementMode ==
        EngagementMode.reactionsAndComments;

    final userId = context.select((AppBloc bloc) => bloc.state.user?.id);
    final userEngagement = engagements.firstWhereOrNull(
      (e) => e.userId == userId,
    );
    final userReaction = userEngagement?.reaction?.reactionType;
    final commentCount = engagements.where((e) => e.comment != null).length;

    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: InlineReactionSelector(
            unselectedColor: mutedColor,
            selectedReaction: userReaction,
            onReactionSelected: (reaction) =>
                _onReactionSelected(context, reaction),
          ),
        ),
        if (isCommentingEnabled)
          _CommentsButton(
            commentCount: commentCount,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => CommentsBottomSheet(headlineId: headline.id),
            ),
          ),
      ],
    );
  }

  void _onReactionSelected(BuildContext context, ReactionType? reaction) {
    context.read<HeadlinesFeedBloc>().add(
      HeadlinesFeedReactionUpdated(headline.id, reaction, context: context),
    );
  }
}

class _CommentsButton extends StatelessWidget {
  const _CommentsButton({required this.commentCount, this.onPressed});

  final int commentCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final mutedTextStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
    );

    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.chat_bubble_outline, size: 16),
      label: Text(
        commentCount > 0
            ? l10n.commentsCount(commentCount)
            : l10n.commentActionLabel,
      ),
      style: TextButton.styleFrom(
        // Apply the muted color to both the icon and the text.
        foregroundColor: mutedTextStyle?.color,
        // Apply the text style for font size and weight.
        textStyle: mutedTextStyle,
      ),
    );
  }
}
