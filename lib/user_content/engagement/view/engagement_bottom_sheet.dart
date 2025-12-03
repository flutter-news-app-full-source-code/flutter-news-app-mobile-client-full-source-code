import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/bloc/engagement_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/widgets/reaction_selector.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template engagement_bottom_sheet}
/// A bottom sheet that serves as the main hub for user engagement.
///
/// It displays a list of reactions, a list of comments, and an input field
/// for adding new comments.
/// {@endtemplate}
class EngagementBottomSheet extends StatelessWidget {
  /// {@macro engagement_bottom_sheet}
  const EngagementBottomSheet({required this.headline, super.key});

  /// The headline for which to display engagement.
  final Headline headline;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EngagementBloc(
        entityId: headline.id,
        entityType: EngageableType.headline,
        engagementRepository: context.read<DataRepository<Engagement>>(),
        appBloc: context.read<AppBloc>(),
      )..add(const EngagementStarted()),
      child: const _EngagementBottomSheetView(),
    );
  }
}

class _EngagementBottomSheetView extends StatelessWidget {
  const _EngagementBottomSheetView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final state = context.watch<EngagementBloc>().state;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          // Add padding for the keyboard.
          child: Column(
            children: [
              Text(
                l10n.commentsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              ReactionSelector(
                selectedReaction: state.userEngagement?.reaction.reactionType,
                onReactionSelected: (reaction) => context
                    .read<EngagementBloc>()
                    .add(EngagementReactionUpdated(reaction)),
              ),
              const Divider(height: AppSpacing.lg),
              Expanded(child: _buildContent(context, state, scrollController)),
              const _CommentInputField(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    EngagementState state,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizationsX(context).l10n;

    if (state.status == EngagementStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == EngagementStatus.failure) {
      return Center(child: Text(l10n.unknownError));
    }

    final comments = state.engagements.where((e) => e.comment != null).toList();

    if (comments.isEmpty && state.status != EngagementStatus.loading) {
      return Center(
        child: Text(
          l10n.noCommentsYet,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final engagement = comments[index];
        final comment = engagement.comment!;
        final currentLocale = context.watch<AppBloc>().state.locale;
        final formattedDate = timeago.format(
          engagement.updatedAt,
          locale: currentLocale.languageCode,
        );

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Row(
            children: [
              Text(
                'User ${engagement.userId.substring(0, 4)}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '• $formattedDate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          subtitle: Text(comment.content),
        );
      },
    );
  }
}

class _CommentInputField extends StatefulWidget {
  const _CommentInputField();

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final state = context.watch<EngagementBloc>().state;

    final hasReaction = state.userEngagement != null;
    final canPost = hasReaction && _controller.text.isNotEmpty;

    return Padding(
      // Add padding for the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: hasReaction
                    ? l10n.commentInputHint
                    : l10n.commentInputNoReactionHint,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              ),
              enabled: hasReaction,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.send),
            color: canPost ? theme.colorScheme.primary : null,
            onPressed: canPost
                ? () {
                    context.read<EngagementBloc>().add(
                      EngagementCommentPosted(_controller.text),
                    );
                    _controller.clear();
                    FocusScope.of(context).unfocus();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
