import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/available_sources_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template add_source_to_follow_page}
/// A page that allows users to browse and select sources to follow.
/// {@endtemplate}
class AddSourceToFollowPage extends StatelessWidget {
  /// {@macro add_source_to_follow_page}
  const AddSourceToFollowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return BlocProvider(
      create: (context) => AvailableSourcesBloc(
        sourcesRepository: context.read<DataRepository<Source>>(),
      )..add(const FetchAvailableSources()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.addSourcesPageTitle)),
        body: BlocBuilder<AvailableSourcesBloc, AvailableSourcesState>(
          builder: (context, sourcesState) {
            if (sourcesState.status == AvailableSourcesStatus.loading ||
                sourcesState.status == AvailableSourcesStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (sourcesState.status == AvailableSourcesStatus.failure) {
              return FailureStateWidget(
                exception: OperationFailedException(
                  sourcesState.error ?? l10n.sourceFilterError,
                ),
                onRetry: () => context.read<AvailableSourcesBloc>().add(
                  const FetchAvailableSources(),
                ),
              );
            }
            if (sourcesState.availableSources.isEmpty) {
              return InitialStateWidget(
                icon: Icons.source_outlined,
                headline: l10n.sourceFilterEmptyHeadline,
                subheadline: l10n.sourceFilterEmptySubheadline,
              );
            }

            return BlocBuilder<AppBloc, AppState>(
              buildWhen: (previous, current) =>
                  previous.userContentPreferences?.followedSources !=
                  current.userContentPreferences?.followedSources,
              builder: (context, appState) {
                final userContentPreferences = appState.userContentPreferences;
                final followedSources =
                    userContentPreferences?.followedSources ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: sourcesState.availableSources.length,
                  itemBuilder: (context, index) {
                    final source = sourcesState.availableSources[index];
                    final isFollowed = followedSources.any(
                      (fs) => fs.id == source.id,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            child: Image.network(
                              source.logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.source_outlined),
                            ),
                          ),
                        ),
                        title: Text(source.name),
                        trailing: IconButton(
                          icon: isFollowed
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : const Icon(Icons.add_circle_outline),
                          tooltip: isFollowed
                              ? l10n.unfollowSourceTooltip(source.name)
                              : l10n.followSourceTooltip(source.name),
                          onPressed: () {
                            // Ensure user preferences are available before
                            // proceeding.
                            if (userContentPreferences == null) return;

                            // Create a mutable copy of the followed sources list.
                            final updatedFollowedSources = List<Source>.from(
                              followedSources,
                            );

                            // If the user is unfollowing, always allow it.
                            if (isFollowed) {
                              updatedFollowedSources.removeWhere(
                                (s) => s.id == source.id,
                              );
                              final updatedPreferences = userContentPreferences
                                  .copyWith(
                                    followedSources: updatedFollowedSources,
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
                                ContentAction.followSource,
                              );

                              if (status == LimitationStatus.allowed) {
                                updatedFollowedSources.add(source);
                                final updatedPreferences =
                                    userContentPreferences.copyWith(
                                      followedSources: updatedFollowedSources,
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
