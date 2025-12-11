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
import 'package:go_router/go_router.dart';
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

class _CommentsBottomSheetView extends StatefulWidget {
  const _CommentsBottomSheetView();

  @override
  State<_CommentsBottomSheetView> createState() =>
      __CommentsBottomSheetViewState();
}

class __CommentsBottomSheetViewState extends State<_CommentsBottomSheetView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<EngagementBloc, EngagementState>(
      listener: (context, state) {
        if (state.limitationStatus != LimitationStatus.allowed) {
          _showContentLimitationBottomSheet(
            context: context,
            status: state.limitationStatus,
            action: ContentAction.postComment,
          );
        } else if (state.status == EngagementStatus.failure &&
            state.error != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.commentPostFailureSnackbar)),
            );
        }
      },
      child: DraggableScrollableSheet(
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
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EngagementState state,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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

class _CommentInputField extends StatefulWidget {
  const _CommentInputField();

  @override
  State<_CommentInputField> createState() => __CommentInputFieldState();
}

class __CommentInputFieldState extends State<_CommentInputField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the input field if the user has an existing comment.
    final existingComment =
        context.read<EngagementBloc>().state.userEngagement?.comment?.content;
    if (existingComment != null) {
      _controller.text = existingComment;
    }
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEditing =>
      context.read<EngagementBloc>().state.userEngagement?.comment != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isGuest =
        context.select((AppBloc bloc) => bloc.state.user?.appRole) ==
            AppUserRole.guestUser;

    // A user can post a comment if they have entered text.
    final canPost = _controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: BlocBuilder<EngagementBloc, EngagementState>(
            builder: (context, state) {
              final isActionInProgress =
                  state.status == EngagementStatus.actionInProgress;
              return TextFormField(
                controller: _controller,
                enabled: !isGuest && !isActionInProgress,
                decoration: InputDecoration(
                  hintText: isGuest
                      ? l10n.commentInputDisabledHint
                      : l10n.commentInputHint,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        BlocBuilder<EngagementBloc, EngagementState>(
          builder: (context, state) {
            final isActionInProgress =
                state.status == EngagementStatus.actionInProgress;
            return isActionInProgress
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(_isEditing ? Icons.check : Icons.send),
                    color: canPost ? theme.colorScheme.primary : null,
                    tooltip: _isEditing
                        ? l10n.commentEditButtonLabel
                        : l10n.commentPostButtonLabel,
                    onPressed: canPost && !isGuest
                        ? () {
                            if (_isEditing) {
                              context.read<EngagementBloc>().add(
                                    EngagementCommentUpdated(
                                      _controller.text,
                                      context: context,
                                    ),
                                  );
                            } else {
                              context.read<EngagementBloc>().add(
                                    EngagementCommentPosted(
                                      _controller.text,
                                      context: context,
                                    ),
                                  );
                            }
                            FocusScope.of(context).unfocus();
                          }
                        : null,
                  );
          },
        ),
      ],
    );
  }
}
