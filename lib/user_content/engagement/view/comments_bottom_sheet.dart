import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/user_avatar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/reporting/view/report_content_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template comments_bottom_sheet}
/// A bottom sheet that displays comments for a headline and allows users
/// to post new comments.
/// {@endtemplate}
class CommentsBottomSheet extends StatelessWidget {
  /// {@macro comments_bottom_sheet}
  const CommentsBottomSheet({required this.headlineId, super.key});

  /// The ID of the headline for which comments are being displayed.
  final String headlineId;

  @override
  Widget build(BuildContext context) {
    // Provide the HeadlinesFeedBloc to the view.
    return BlocProvider.value(
      value: context.read<HeadlinesFeedBloc>(),
      child: _CommentsBottomSheetView(headlineId: headlineId),
    );
  }
}

class _CommentsBottomSheetView extends StatefulWidget {
  const _CommentsBottomSheetView({required this.headlineId});
  // A key to manage the state of the input field, allowing parent widgets
  // to trigger actions like editing.
  static final _inputFieldKey = GlobalKey<__CommentInputFieldState>();

  final String headlineId;

  @override
  State<_CommentsBottomSheetView> createState() =>
      __CommentsBottomSheetViewState();
}

class __CommentsBottomSheetViewState extends State<_CommentsBottomSheetView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, sheetScrollController) {
        return Padding(
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
              Expanded(child: _buildContent(context, sheetScrollController)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _CommentInputField(
                  key: _CommentsBottomSheetView._inputFieldKey,
                  headlineId: widget.headlineId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context);

        final user = context.select((AppBloc bloc) => bloc.state.user);
        final currentLocale = context.watch<AppBloc>().state.locale;

        final engagements = state.engagementsMap[widget.headlineId] ?? [];
        final comments = engagements.where((e) => e.comment != null).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (state.status == HeadlinesFeedStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

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
            final formattedDate = timeago.format(
              engagement.updatedAt,
              locale: currentLocale.languageCode,
            );

            final isOwnComment = user != null && engagement.userId == user.id;

            return ListTile(
              leading: UserAvatar(user: user),
              title: Row(
                children: [
                  Text(
                    l10n.commenterName(engagement.userId.substring(0, 4)),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '• $formattedDate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwnComment)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        _CommentsBottomSheetView._inputFieldKey.currentState
                            ?.startEditing();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ReportContentBottomSheet(
                          entityId: engagement.id,
                          reportableEntity: ReportableEntity.comment,
                        ),
                      );
                    },
                  ),
                ],
              ),
              subtitle: Text(comment.content),
            );
          },
        );
      },
    );
  }
}

class _CommentInputField extends StatefulWidget {
  const _CommentInputField({required this.headlineId, super.key});

  final String headlineId;

  @override
  State<_CommentInputField> createState() => __CommentInputFieldState();
}

class __CommentInputFieldState extends State<_CommentInputField> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void startEditing() {
    final user = context.read<AppBloc>().state.user;
    if (user == null) return;

    final engagements =
        context
            .read<HeadlinesFeedBloc>()
            .state
            .engagementsMap[widget.headlineId] ??
        [];
    final userEngagement = engagements.firstWhereOrNull(
      (e) => e.userId == user.id,
    );
    final existingComment = userEngagement?.comment?.content;

    if (existingComment != null) {
      setState(() {
        _controller.text = existingComment;
        _isEditing = true;
      });
      _focusNode.requestFocus();
    }
  }

  void resetAfterSubmit() {
    _controller.clear();
    if (mounted) {
      setState(() => _isEditing = false);
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = context.select((AppBloc bloc) => bloc.state.user);
    final isGuest = user?.isAnonymous ?? true;

    return BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
      builder: (context, state) {
        final engagements = state.engagementsMap[widget.headlineId] ?? [];
        final userEngagement = engagements.firstWhereOrNull(
          (e) => e.userId == user?.id,
        );
        final hasExistingComment = userEngagement?.comment != null;
        final isEnabled = !isGuest && (!hasExistingComment || _isEditing);

        final canPost = _controller.text.isNotEmpty;

        return Row(
          children: [
            Expanded(
              child: TextFormField(
                focusNode: _focusNode,
                controller: _controller,
                enabled: isEnabled,
                decoration: InputDecoration(
                  hintText: isEnabled
                      ? (_isEditing
                            ? l10n.commentEditButtonLabel
                            : l10n.commentInputHint)
                      : (isGuest
                            ? l10n.commentInputDisabledHint
                            : l10n.commentInputExistingHint),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.send),
              color: canPost ? theme.colorScheme.primary : null,
              tooltip: _isEditing
                  ? l10n.commentEditButtonLabel
                  : l10n.commentPostButtonLabel,
              onPressed: canPost && isEnabled
                  ? () {
                      if (_isEditing) {
                        context.read<HeadlinesFeedBloc>().add(
                          HeadlinesFeedCommentUpdated(
                            widget.headlineId,
                            _controller.text,
                            context: context,
                          ),
                        );
                      } else {
                        context.read<HeadlinesFeedBloc>().add(
                          HeadlinesFeedCommentPosted(
                            widget.headlineId,
                            _controller.text,
                            context: context,
                          ),
                        );
                      }
                      resetAfterSubmit();
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}
