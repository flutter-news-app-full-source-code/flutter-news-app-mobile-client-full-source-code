import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template topic_filter_page}
/// A page dedicated to selecting news topics for filtering headlines.
///
/// This page now interacts with the centralized [HeadlinesFilterBloc]
/// to manage the list of available topics and the user's selections.
/// {@endtemplate}
class TopicFilterPage extends StatelessWidget {
  /// {@macro topic_filter_page}
  ///
  /// Requires the [filterBloc] instance passed from the parent route.
  const TopicFilterPage({required this.filterBloc, super.key});

  /// The instance of [HeadlinesFilterBloc] provided by the parent route.
  final HeadlinesFilterBloc filterBloc;

  @override
  Widget build(BuildContext context) {
    // Provide the existing filterBloc to this subtree.
    return BlocProvider.value(
      value: filterBloc,
      child: const _TopicFilterView(),
    );
  }
}

class _TopicFilterView extends StatelessWidget {
  const _TopicFilterView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedFilterTopicLabel,
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          // Apply Filters Button (now just pops, as state is managed centrally)
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              // The selections are already managed by HeadlinesFilterBloc.
              // Just pop the page.
              context.pop();
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
        builder: (context, filterState) {
          // Determine overall loading status for the main list
          final isLoadingMainList =
              filterState.status == HeadlinesFilterStatus.loading;

          if (isLoadingMainList) {
            return LoadingStateWidget(
              icon: Icons.category_outlined,
              headline: l10n.topicFilterLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (filterState.status == HeadlinesFilterStatus.failure &&
              filterState.allTopics.isEmpty) {
            return Center(
              child: FailureStateWidget(
                exception:
                    filterState.error ??
                    const UnknownException(
                      'An unknown error occurred while fetching topics.',
                    ),
                onRetry: () => context.read<HeadlinesFilterBloc>().add(
                  FilterDataLoaded(
                    initialSelectedTopics: filterState.selectedTopics.toList(),
                    initialSelectedSources: filterState.selectedSources
                        .toList(),
                    initialSelectedCountries: filterState.selectedCountries
                        .toList(),
                  ),
                ),
              ),
            );
          }

          if (filterState.allTopics.isEmpty) {
            return InitialStateWidget(
              icon: Icons.category_outlined,
              headline: l10n.topicFilterEmptyHeadline,
              subheadline: l10n.topicFilterEmptySubheadline,
            );
          }

          return ListView.builder(
            itemCount: filterState.allTopics.length,
            itemBuilder: (context, index) {
              final topic = filterState.allTopics[index];
              final isSelected = filterState.selectedTopics.contains(topic);
              return CheckboxListTile(
                title: Text(topic.name),
                value: isSelected,
                onChanged: (bool? value) {
                  if (value != null) {
                    context.read<HeadlinesFilterBloc>().add(
                      FilterTopicToggled(topic: topic, isSelected: value),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
