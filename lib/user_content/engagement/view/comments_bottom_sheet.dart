import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/bloc/engagement_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template comments_bottom_sheet}
/// A bottom sheet that displays comments for a headline and allows users
/// to post new comments.
/// {@endtemplate}
class CommentsBottomSheet extends StatelessWidget {
  /// {@macro comments_bottom_sheet}
  const CommentsBottomSheet({required this.headline, super.key});

  /// The headline for which to display comments.
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
      child: const _CommentsBottomSheetView(),
    );
  }
}

class _CommentsBottomSheetView extends StatelessWidget {
  const _CommentsBottomSheetView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          // Add padding for the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.commentsPageTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<EngagementBloc, EngagementState>(
                  builder: (context, state) {
                    return _buildContent(context, state, scrollController);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: _CommentInputField(),
              ),
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
      return FailureStateWidget(
        onRetry: () =>
            context.read<EngagementBloc>().add(const EngagementStarted()),
        exception: state.error!,
      );
    }

    final comments = state.engagements.where((e) => e.comment != null).toList();

    if (comments.isEmpty) {
      return Center(
        child: Text(
          l10n.noCommentsYet,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: comments.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
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
  State<_CommentInputField> createState() => __CommentInputFieldState();
}

class __CommentInputFieldState extends State<_CommentInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    // A user can post a comment if they have entered text.
    final canPost = _controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: l10n.commentInputHint,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
            ),
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
    );
  }
}
