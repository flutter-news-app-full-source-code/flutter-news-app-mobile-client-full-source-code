import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/widgets/widgets.dart';

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
          if (state.status == AccountStatus.loading &&
              state.preferences == null) {
            return const LoadingStateWidget(
              icon: Icons.bookmarks_outlined,
              headline: 'Loading Saved Headlines...', // Placeholder
              subheadline:
                  'Please wait while we fetch your saved articles.', // Placeholder
            );
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              message:
                  state.errorMessage ??
                  'Could not load saved headlines.', // Placeholder
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                    AccountLoadContentPreferencesRequested(
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
              headline: 'No Saved Headlines', // Placeholder
              subheadline:
                  "You haven't saved any articles yet. Start exploring!", // Placeholder
            );
          }

          return ListView.separated(
            itemCount: savedHeadlines.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final headline = savedHeadlines[index];
              return HeadlineItemWidget(
                headline: headline,
                targetRouteName: Routes.accountArticleDetailsName,
                trailing: IconButton(
                  // Changed from trailingWidget
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove from saved', // Placeholder
                  onPressed: () {
                    context.read<AccountBloc>().add(
                      AccountSaveHeadlineToggled(headline: headline),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
