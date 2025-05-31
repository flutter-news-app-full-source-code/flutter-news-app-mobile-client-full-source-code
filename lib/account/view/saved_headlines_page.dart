import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Added GoRouter
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // Added AppBloc
// HeadlineItemWidget import removed
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/shared.dart'; // Imports new headline tiles
import 'package:ht_shared/ht_shared.dart'
    show Headline, HeadlineImageStyle; // Added HeadlineImageStyle

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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSavedHeadlinesTile)),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          // Initial load or loading state for preferences
          if (state.status == AccountStatus.loading && state.preferences == null) {
            return const LoadingStateWidget(
              icon: Icons.bookmarks_outlined,
              headline: 'Loading Saved Headlines...', // Placeholder
              subheadline:
                  'Please wait while we fetch your saved articles.', // Placeholder
            );
          }

          // Failure to load preferences
          if (state.status == AccountStatus.failure && state.preferences == null) {
            return FailureStateWidget(
              message:
                  state.errorMessage ??
                  'Could not load saved headlines.', // Placeholder
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                        AccountLoadUserPreferences( // Corrected event name
                          userId: state.user!.id,
                        ),
                      );
                }
              },
            );
          }

          final savedHeadlines = state.preferences?.savedHeadlines ?? [];

          if (savedHeadlines.isEmpty) {
            return const InitialStateWidget( 
              icon: Icons.bookmark_add_outlined,
              headline: 'No Saved Headlines', // Placeholder - Reverted
              subheadline:
                  "You haven't saved any articles yet. Start exploring!", // Placeholder - Reverted
            );
          }

          return ListView.separated(
            itemCount: savedHeadlines.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final headline = savedHeadlines[index];
              final imageStyle =
                  context
                      .watch<AppBloc>()
                      .state
                      .settings
                      .feedPreferences
                      .headlineImageStyle;

              final trailingButton = IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.headlineDetailsRemoveFromSavedTooltip, // Use l10n
                onPressed: () {
                  context.read<AccountBloc>().add(
                    AccountSaveHeadlineToggled(headline: headline),
                  );
                },
              );

              Widget tile;
              switch (imageStyle) {
                case HeadlineImageStyle.hidden:
                  tile = HeadlineTileTextOnly(
                    headline: headline,
                    onHeadlineTap:
                        () => context.goNamed(
                          Routes.accountArticleDetailsName,
                          pathParameters: {'id': headline.id},
                          extra: headline,
                        ),
                    trailing: trailingButton,
                  );
                  break;
                case HeadlineImageStyle.smallThumbnail:
                  tile = HeadlineTileImageStart(
                    headline: headline,
                    onHeadlineTap:
                        () => context.goNamed(
                          Routes.accountArticleDetailsName,
                          pathParameters: {'id': headline.id},
                          extra: headline,
                        ),
                    trailing: trailingButton,
                  );
                  break;
                case HeadlineImageStyle.largeThumbnail:
                  tile = HeadlineTileImageTop(
                    headline: headline,
                    onHeadlineTap:
                        () => context.goNamed(
                          Routes.accountArticleDetailsName,
                          pathParameters: {'id': headline.id},
                          extra: headline,
                        ),
                    trailing: trailingButton,
                  );
                  break;
              }
              return tile;
            },
          );
        },
      ),
    );
  }
}
