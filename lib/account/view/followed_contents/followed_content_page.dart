import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/shared.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/entity_list_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template followed_content_page}
/// A unified page that displays all content types followed by the user,
/// organized into tabs.
/// {@endtemplate}
class FollowedContentPage extends StatelessWidget {
  /// {@macro followed_content_page}
  const FollowedContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.followedContentPageTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.followedContentTopicsTab),
              Tab(text: l10n.followedContentSourcesTab),
              Tab(text: l10n.headlinesFeedFilterCountryLabel),
            ],
          ),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    final tabIndex = DefaultTabController.of(context).index;
                    _navigateToAddPage(context, tabIndex);
                  },
                );
              },
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxDialogContentWidth,
            ),
            child: TabBarView(
              children: [
                _FollowedList<Topic>(
                  items: context.select(
                    (AppBloc bloc) =>
                        bloc.state.userContentPreferences?.followedTopics ?? [],
                  ),
                ),
                _FollowedList<Source>(
                  items: context.select(
                    (AppBloc bloc) =>
                        bloc.state.userContentPreferences?.followedSources ??
                        [],
                  ),
                ),
                _FollowedList<Country>(
                  items: context.select(
                    (AppBloc bloc) =>
                        bloc.state.userContentPreferences?.followedCountries ??
                        [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddPage(BuildContext context, int tabIndex) async {
    final l10n = AppLocalizationsX(context).l10n;
    final appBloc = context.read<AppBloc>();
    final preferences = appBloc.state.userContentPreferences;

    if (preferences == null) return;

    final Widget page;
    final void Function(Set<FeedItem>?) onSave;

    switch (tabIndex) {
      case 0:
        page = MultiSelectSearchPage<Topic>(
          title: l10n.addTopicsPageTitle,
          repository: context.read<DataRepository<Topic>>(),
          initialSelectedItems: preferences.followedTopics.toSet(),
          itemBuilder: (Topic topic) => topic.name,
        );
        onSave = (newItems) {
          if (newItems == null) return;
          final updatedPreferences = preferences.copyWith(
            followedTopics: newItems.whereType<Topic>().toList(),
          );
          appBloc.add(
            AppUserContentPreferencesChanged(preferences: updatedPreferences),
          );
        };
      case 1:
        page = MultiSelectSearchPage<Source>(
          title: l10n.addSourcesPageTitle,
          repository: context.read<DataRepository<Source>>(),
          initialSelectedItems: preferences.followedSources.toSet(),
          itemBuilder: (Source source) => source.name,
        );
        onSave = (newItems) {
          if (newItems == null) return;
          final updatedPreferences = preferences.copyWith(
            followedSources: newItems.whereType<Source>().toList(),
          );
          appBloc.add(
            AppUserContentPreferencesChanged(preferences: updatedPreferences),
          );
        };
      case 2:
        page = MultiSelectSearchPage<Country>(
          title: l10n.addCountriesPageTitle,
          repository: context.read<DataRepository<Country>>(),
          initialSelectedItems: preferences.followedCountries.toSet(),
          itemBuilder: (Country country) => country.name,
        );
        onSave = (newItems) {
          if (newItems == null) return;
          final updatedPreferences = preferences.copyWith(
            followedCountries: newItems.whereType<Country>().toList(),
          );
          appBloc.add(
            AppUserContentPreferencesChanged(preferences: updatedPreferences),
          );
        };
      default:
        return;
    }

    final selectedItems = await Navigator.of(
      context,
    ).push<Set<FeedItem>>(MaterialPageRoute(builder: (_) => page));

    if (selectedItems != null) {
      onSave(selectedItems);
    }
  }
}

class _FollowedList<T extends FeedItem> extends StatelessWidget {
  const _FollowedList({required this.items});

  final List<FeedItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    if (items.isEmpty) {
      return Center(
        child: InitialStateWidget(
          icon: Icons.check_circle_outline,
          headline: l10n.followedContentEmpty,
          subheadline: l10n.followedContentEmptySubheadline,
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => context.pushNamed(
            Routes.entityDetailsName,
            pathParameters: {
              'type': item.type,
              'id': (item as dynamic).id as String,
            },
          ),
          child: EntityListTile(item: item),
        );
      },
    );
  }
}
