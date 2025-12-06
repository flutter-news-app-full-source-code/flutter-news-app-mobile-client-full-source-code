import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/bloc/engagement_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/view/comments_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/widgets/inline_reaction_selector.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_actions_row}
/// A widget that displays a row of engagement actions for a headline tile.
/// This includes the inline reaction selector and a button to view comments.
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

    return BlocBuilder<EngagementBloc, EngagementState>(
      builder: (context, state) {
        final userReaction = state.userEngagement?.reaction?.reactionType;
        final commentCount = state.engagements
            .where((e) => e.comment != null)
            .length;
        
        final theme = Theme.of(context);
        final mutedColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InlineReactionSelector(
                  unselectedColor: mutedColor,
                  selectedReaction: userReaction,
                  onReactionSelected: (reaction) => context
                      .read<EngagementBloc>()
                      .add(EngagementReactionUpdated(reaction)),
                ),
              ),
              if (isCommentingEnabled)
                _CommentsButton(
                  commentCount: commentCount,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    // Provide all necessary dependencies to the new route's context.
                    builder: (_) => MultiRepositoryProvider(
                      providers: [
                        // Provide the Engagement repository.
                        RepositoryProvider.value(
                          value: context.read<DataRepository<Engagement>>(),
                        ),
                        // Provide the ContentLimitationService.
                        RepositoryProvider.value(
                          value: context.read<ContentLimitationService>(),
                        ),
                      ],
                      // Also provide the AppBloc.
                      child: BlocProvider.value(
                        value: context.read<AppBloc>(),
                        child: CommentsBottomSheet(headline: headline),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentsButton extends StatelessWidget {
  const _CommentsButton({required this.commentCount, this.onPressed});

  final int commentCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
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
