import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/available_topics_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:ui_kit/ui_kit.dart';

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
                        trailing: IconButton(
                          icon: isFollowed
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : Icon(
                                  Icons.add_circle_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          tooltip: isFollowed
                              ? l10n.unfollowTopicTooltip(topic.name)
                              : l10n.followTopicTooltip(topic.name),
                          onPressed: () {
                            // Ensure user preferences are available before
                            // proceeding.
                            if (userContentPreferences == null) return;

                            // Create a mutable copy of the followed topics list.
                            final updatedFollowedTopics = List<Topic>.from(
                              followedTopics,
                            );

                            // If the user is unfollowing, always allow it.
                            if (isFollowed) {
                              updatedFollowedTopics.removeWhere(
                                (t) => t.id == topic.id,
                              );
                              final updatedPreferences = userContentPreferences
                                  .copyWith(
                                    followedTopics: updatedFollowedTopics,
                                  );

                              context.read<AppBloc>().add(
                                AppUserContentPreferencesChanged(
                                  preferences: updatedPreferences,
                                ),
                              );
                            } else {
                              // If the user is following, check the limit first.
                              final limitationService = context
                                  .read<ContentLimitationService>();
                              final status = limitationService.checkAction(
                                ContentAction.followTopic,
                              );

                              if (status == LimitationStatus.allowed) {
                                updatedFollowedTopics.add(topic);
                                final updatedPreferences =
                                    userContentPreferences.copyWith(
                                      followedTopics: updatedFollowedTopics,
                                    );

                                context.read<AppBloc>().add(
                                  AppUserContentPreferencesChanged(
                                    preferences: updatedPreferences,
                                  ),
                                );
                              } else {
                                // If the limit is reached, show the bottom sheet.
                                showModalBottomSheet<void>(
                                  context: context,
                                  builder: (_) => ContentLimitationBottomSheet(
                                    status: status,
                                  ),
                                );
                              }
                            }
                          },
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
