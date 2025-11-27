import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template saved_headlines_page}
/// Displays the list of headlines saved by the user.
///
/// Allows users to view details of a saved headline or remove it
/// from their saved list.
/// {@endtemplate}
class SavedHeadlinesPage extends StatelessWidget {
  /// {@macro saved_headlines_page}
  const SavedHeadlinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          l10n.accountSavedHeadlinesTile,
          style: textTheme.titleLarge,
        ),
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          final userContentPreferences = appState.userContentPreferences;

          if (appState.status == AppLifeCycleStatus.loadingUserData ||
              userContentPreferences == null) {
            return LoadingStateWidget(
              icon: Icons.bookmarks_outlined,
              headline: l10n.savedHeadlinesLoadingHeadline,
              subheadline: l10n.savedHeadlinesLoadingSubheadline,
            );
          }

          if (appState.error != null) {
            return FailureStateWidget(
              exception: appState.error!,
              onRetry: () {
                context.read<AppBloc>().add(
                  const AppUserContentPreferencesRefreshed(),
                );
              },
            );
          }

          final savedHeadlines = userContentPreferences.savedHeadlines;

          if (savedHeadlines.isEmpty) {
            return InitialStateWidget(
              icon: Icons.bookmark_add_outlined,
              headline: l10n.savedHeadlinesEmptyHeadline,
              subheadline: l10n.savedHeadlinesEmptySubheadline,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.paddingSmall,
            ),
            itemCount: savedHeadlines.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: AppSpacing.paddingMedium,
              endIndent: AppSpacing.paddingMedium,
            ),
            itemBuilder: (context, index) {
              final headline = savedHeadlines[index];
              final imageStyle =
                  appState.settings?.feedSettings.feedItemImageStyle ??
                  FeedItemImageStyle.smallThumbnail;

              Widget tile;
              switch (imageStyle) {
                case FeedItemImageStyle.hidden:
                  tile = HeadlineTileTextOnly(
                    headline: headline,
                    onHeadlineTap: () =>
                        HeadlineTapHandler.handleHeadlineTap(context, headline),
                  );
                case FeedItemImageStyle.smallThumbnail:
                  tile = HeadlineTileImageStart(
                    headline: headline,
                    onHeadlineTap: () =>
                        HeadlineTapHandler.handleHeadlineTap(context, headline),
                  );
                case FeedItemImageStyle.largeThumbnail:
                  tile = HeadlineTileImageTop(
                    headline: headline,
                    onHeadlineTap: () =>
                        HeadlineTapHandler.handleHeadlineTap(context, headline),
                  );
              }
              return tile;
            },
          );
        },
      ),
    );
  }
}
