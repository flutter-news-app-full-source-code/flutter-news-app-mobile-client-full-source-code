import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/bloc/engagement_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/view/comments_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/widgets/inline_reaction_selector.dart';
import 'package:go_router/go_router.dart';
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

class _HeadlineActionsRowView extends StatefulWidget {
  const _HeadlineActionsRowView({required this.headline});

  final Headline headline;

  @override
  State<_HeadlineActionsRowView> createState() =>
      _HeadlineActionsRowViewState();
}

class _HeadlineActionsRowViewState extends State<_HeadlineActionsRowView> {
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

    return BlocListener<EngagementBloc, EngagementState>(
      listener: (context, state) {
        if (state.limitationStatus != LimitationStatus.allowed) {
          final l10n = AppLocalizations.of(context);
          final userRole = context.read<AppBloc>().state.user?.appRole;
          final content = _getBottomSheetContent(
            context: context,
            l10n: l10n,
            status: state.limitationStatus,
            userRole: userRole,
            action: ContentAction.reactToContent, // This is for reactions
          );

          showModalBottomSheet<void>(
            context: context,
            builder: (_) => ContentLimitationBottomSheet(
              title: content.title,
              body: content.body,
              buttonText: content.buttonText,
              onButtonPressed: content.onPressed,
            ),
          );
        }
      },
      child: BlocBuilder<EngagementBloc, EngagementState>(
        builder: (context, state) {
          final userReaction = state.userEngagement?.reaction?.reactionType;
          final commentCount = state.engagements
              .where((e) => e.comment != null)
              .length;

          final theme = Theme.of(context);
          final mutedColor = theme.colorScheme.onSurfaceVariant.withOpacity(
            0.6,
          );

          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
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
                      // Share the existing EngagementBloc instance with the
                      // bottom sheet.
                      builder: (_) => BlocProvider.value(
                        value: context.read<EngagementBloc>(),
                        child: const CommentsBottomSheet(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onReactionSelected(BuildContext context, ReactionType? reaction) {
    final user = context.read<AppBloc>().state.user;
    if (user?.appRole == AppUserRole.guestUser) {
      _showContentLimitationBottomSheet(
        context: context,
        status: LimitationStatus.anonymousLimitReached,
        action: ContentAction.reactToContent,
      );
    } else {
      context.read<EngagementBloc>().add(
        EngagementReactionUpdated(reaction, context: context),
      );
    }
  }

  void _showContentLimitationBottomSheet({
    required BuildContext context,
    required LimitationStatus status,
    required ContentAction action,
  }) {
    final l10n = AppLocalizations.of(context);
    final userRole = context.read<AppBloc>().state.user?.appRole;

    final content = _getBottomSheetContent(
      context: context,
      l10n: l10n,
      status: status,
      userRole: userRole,
      action: action,
    );

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ContentLimitationBottomSheet(
        title: content.title,
        body: content.body,
        buttonText: content.buttonText,
        onButtonPressed: content.onPressed,
      ),
    );
  }

  ({String title, String body, String buttonText, VoidCallback? onPressed})
  _getBottomSheetContent({
    required BuildContext context,
    required AppLocalizations l10n,
    required LimitationStatus status,
    required AppUserRole? userRole,
    required ContentAction action,
  }) {
    switch (status) {
      case LimitationStatus.anonymousLimitReached:
        return (
          title: l10n.limitReachedGuestUserTitle,
          body: l10n.limitReachedGuestUserBody,
          buttonText: l10n.anonymousLimitButton,
          onPressed: () {
            Navigator.of(context).pop();
            context.pushNamed(Routes.accountLinkingName);
          },
        );
      case LimitationStatus.standardUserLimitReached:
        return (
          title: l10n.standardLimitTitle,
          body: l10n.standardLimitBody,
          buttonText: l10n.standardLimitButton,
          onPressed: () => Navigator.of(context).pop(),
        );
      case LimitationStatus.premiumUserLimitReached:
        return (
          title: l10n.premiumLimitTitle,
          body: l10n.premiumLimitBody,
          buttonText: l10n.premiumLimitButton,
          onPressed: () => Navigator.of(context).pop(),
        );
      case LimitationStatus.allowed:
        return (title: '', body: '', buttonText: '', onPressed: null);
    }
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
