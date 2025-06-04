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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.accountSavedHeadlinesTile,
          style: textTheme.titleLarge, // Consistent AppBar title
        ),
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.status == AccountStatus.loading &&
              state.preferences == null) {
            return LoadingStateWidget(
              icon: Icons.bookmarks_outlined,
              headline: l10n.savedHeadlinesLoadingHeadline, // Use l10n
              subheadline: l10n.savedHeadlinesLoadingSubheadline, // Use l10n
            );
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              message:
                  state.errorMessage ??
                  l10n.savedHeadlinesErrorHeadline, // Use l10n
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                    AccountLoadUserPreferences(userId: state.user!.id),
                  );
                }
              },
            );
          }

          final savedHeadlines = state.preferences?.savedHeadlines ?? [];

          if (savedHeadlines.isEmpty) {
            return InitialStateWidget(
              icon: Icons.bookmark_add_outlined,
              headline: l10n.savedHeadlinesEmptyHeadline, // Use l10n
              subheadline: l10n.savedHeadlinesEmptySubheadline, // Use l10n
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.paddingSmall,
            ), // Add padding
            itemCount: savedHeadlines.length,
            separatorBuilder:
                (context, index) => const Divider(
                  height: 1,
                  indent: AppSpacing.paddingMedium, // Indent divider
                  endIndent: AppSpacing.paddingMedium,
                ),
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
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ), // Themed icon
                tooltip: l10n.headlineDetailsRemoveFromSavedTooltip,
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
              }
              return tile;
            },
          );
        },
      ),
    );
  }
}
