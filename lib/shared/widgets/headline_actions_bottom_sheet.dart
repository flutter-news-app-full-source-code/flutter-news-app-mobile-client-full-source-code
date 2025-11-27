import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_actions_bottom_sheet}
/// A modal bottom sheet that displays actions for a given headline, such as
/// sharing and bookmarking.
/// {@endtemplate}
class HeadlineActionsBottomSheet extends StatelessWidget {
  /// {@macro headline_actions_bottom_sheet}
  const HeadlineActionsBottomSheet({required this.headline, super.key});

  /// The headline for which to display actions.
  final Headline headline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final isBookmarked =
            state.userContentPreferences?.savedHeadlines.any(
              (saved) => saved.id == headline.id,
            ) ??
            false;

        return Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.headlineActionsModalTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.shareActionLabel),
              onTap: () {
                Navigator.of(context).pop();
                Share.share(headline.url);
              },
            ),
            ListTile(
              leading: Icon(
                isBookmarked
                    ? Icons.bookmark_added
                    : Icons.bookmark_add_outlined,
              ),
              title: Text(
                isBookmarked
                    ? l10n.removeBookmarkActionLabel
                    : l10n.bookmarkActionLabel,
              ),
              onTap: () {
                final userContentPreferences = state.userContentPreferences;
                if (userContentPreferences == null) return;

                final currentSaved = List<Headline>.from(
                  userContentPreferences.savedHeadlines,
                );

                if (isBookmarked) {
                  currentSaved.removeWhere((h) => h.id == headline.id);
                } else {
                  currentSaved.insert(0, headline);
                }

                context.read<AppBloc>().add(
                  AppUserContentPreferencesChanged(
                    preferences: userContentPreferences.copyWith(
                      savedHeadlines: currentSaved,
                    ),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
