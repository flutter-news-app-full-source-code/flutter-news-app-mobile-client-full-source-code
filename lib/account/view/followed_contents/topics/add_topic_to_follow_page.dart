import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/available_topics_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.topic, required this.isFollowed});

  final Topic topic;
  final bool isFollowed;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isLoading = false;

  Future<void> _onFollowToggled() async {
    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context);
    final appBloc = context.read<AppBloc>();
    final userContentPreferences = appBloc.state.userContentPreferences;

    if (userContentPreferences == null) {
      setState(() => _isLoading = false);
      return;
    }

    final updatedFollowedTopics = List<Topic>.from(
      userContentPreferences.followedTopics,
    );

    try {
      if (widget.isFollowed) {
        updatedFollowedTopics.removeWhere((t) => t.id == widget.topic.id);
      } else {
        final limitationService = context.read<ContentLimitationService>();
        final status = await limitationService.checkAction(
          ContentAction.followTopic,
        );

        if (status != LimitationStatus.allowed) {
          if (mounted) {
            final userRole = context.read<AppBloc>().state.user?.appRole;
            final content = _getBottomSheetContent(
              context: context,
              l10n: l10n,
              status: status,
              userRole: userRole,
              defaultBody: l10n.limitReachedBodyFollow,
            );

            await showModalBottomSheet<void>(
              context: context,
              builder: (_) => ContentLimitationBottomSheet(
                title: content.title,
                body: content.body,
                buttonText: content.buttonText,
                onButtonPressed: content.onPressed,
              ),
            );
          }
          return;
        }
        updatedFollowedTopics.add(widget.topic);
      }

      final updatedPreferences = userContentPreferences.copyWith(
        followedTopics: updatedFollowedTopics,
      );

      appBloc.add(
        AppUserContentPreferencesChanged(preferences: updatedPreferences),
      );
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: widget.isFollowed
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(Icons.add_circle_outline, color: colorScheme.onSurfaceVariant),
      tooltip: widget.isFollowed
          ? l10n.unfollowTopicTooltip(widget.topic.name)
          : l10n.followTopicTooltip(widget.topic.name),
      onPressed: _onFollowToggled,
    );
  }
}

/// Determines the content for the [ContentLimitationBottomSheet] based on
/// the user's role and the limitation status.
({String title, String body, String buttonText, VoidCallback? onPressed})
_getBottomSheetContent({
  required BuildContext context,
  required AppLocalizations l10n,
  required LimitationStatus status,
  required AppUserRole? userRole,
  required String defaultBody,
}) {
  switch (status) {
    case LimitationStatus.anonymousLimitReached:
      return (
        title: l10n.anonymousLimitTitle,
        body: l10n.anonymousLimitBody,
        buttonText: l10n.anonymousLimitButton,
        onPressed: () {
          Navigator.of(context).pop();
          context.pushNamed(Routes.accountLinkingName);
        },
      );
    case LimitationStatus.standardUserLimitReached:
      // TODO(flutter-news-app): Implement upgrade flow.
      return (
        title: l10n.standardLimitTitle,
        body: l10n.standardLimitBody,
        buttonText: l10n.standardLimitButton,
        onPressed: () => Navigator.of(context).pop(),
      );
    case LimitationStatus.premiumUserLimitReached:
      return (
        title: l10n.premiumLimitTitle,
        body: defaultBody,
        buttonText: l10n.premiumLimitButton,
        onPressed: () {
          Navigator.of(context).pop();
          context.goNamed(Routes.manageFollowedItemsName);
        },
      );
    case LimitationStatus.allowed:
      return (title: '', body: '', buttonText: '', onPressed: null);
  }
}

/// {@template add_topic_to_follow_page}
/// A page that allows users to browse and select topics to follow.
/// {@endtemplate}
class AddTopicToFollowPage extends StatelessWidget {
  /// {@macro add_topic_to_follow_page}
  const AddTopicToFollowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return BlocProvider(
      create: (context) => AvailableTopicsBloc(
        topicsRepository: context.read<DataRepository<Topic>>(),
      )..add(const FetchAvailableTopics()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addTopicsPageTitle, style: textTheme.titleLarge),
        ),
        body: BlocBuilder<AvailableTopicsBloc, AvailableTopicsState>(
          builder: (context, topicsState) {
            if (topicsState.status == AvailableTopicsStatus.loading) {
              return LoadingStateWidget(
                icon: Icons.topic_outlined,
                headline: l10n.topicFilterLoadingHeadline,
                subheadline: l10n.pleaseWait,
              );
            }
            if (topicsState.status == AvailableTopicsStatus.failure) {
              return FailureStateWidget(
                exception: OperationFailedException(
                  topicsState.error ?? l10n.topicFilterError,
                ),
                onRetry: () => context.read<AvailableTopicsBloc>().add(
                  const FetchAvailableTopics(),
                ),
              );
            }
            if (topicsState.availableTopics.isEmpty) {
              return InitialStateWidget(
                icon: Icons.search_off_outlined,
                headline: l10n.topicFilterEmptyHeadline,
                subheadline: l10n.topicFilterEmptySubheadline,
              );
            }

            final topics = topicsState.availableTopics;

            return BlocBuilder<AppBloc, AppState>(
              buildWhen: (previous, current) =>
                  previous.userContentPreferences?.followedTopics !=
                  current.userContentPreferences?.followedTopics,
              builder: (context, appState) {
                final userContentPreferences = appState.userContentPreferences;
                final followedTopics =
                    userContentPreferences?.followedTopics ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingMedium,
                    vertical: AppSpacing.paddingSmall,
                  ).copyWith(bottom: AppSpacing.xxl),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final isFollowed = followedTopics.any(
                      (ft) => ft.id == topic.id,
                    );
                    final colorScheme = Theme.of(context).colorScheme;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: AppSpacing.xl + AppSpacing.xs,
                          height: AppSpacing.xl + AppSpacing.xs,
                          child: Uri.tryParse(topic.iconUrl)?.isAbsolute == true
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.xs,
                                  ),
                                  child: Image.network(
                                    topic.iconUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.topic_outlined,
                                          color: colorScheme.onSurfaceVariant,
                                          size: AppSpacing.lg,
                                        ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                  ),
                                )
                              : Icon(
                                  Icons.topic_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: AppSpacing.lg,
                                ),
                        ),
                        title: Text(topic.name, style: textTheme.titleMedium),
                        trailing: _FollowButton(
                          topic: topic,
                          isFollowed: isFollowed,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingMedium,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
