import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headline_search_delegate.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/user_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template feed_sliver_app_bar}
/// A sliver app bar for the feed page that includes a custom search bar.
///
/// The search bar is a tappable widget that initiates a search via
/// [HeadlineSearchDelegate] and includes a user avatar that opens the
/// [AccountSheet].
/// {@endtemplate}
class FeedSliverAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// {@macro feed_sliver_app_bar}
  const FeedSliverAppBar({required this.bottom, super.key});

  /// This widget appears across the bottom of the app bar.
  final PreferredSizeWidget bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizationsX(context).l10n;

    return SliverAppBar(
      // The app bar will remain visible at the top when scrolling.
      pinned: false,
      // The app bar will become visible as soon as the user scrolls up.
      floating: true,
      // The app bar will snap into view when scrolling up, even if the user
      // stops scrolling partway. This works in conjunction with `floating` to
      // create the desired scrolling effect.
      snap: true,
      bottom: bottom,
      // The title is a custom search bar widget.
      title: GestureDetector(
        onTap: () {
          // When the search bar is tapped, show the search delegate.
          // A new instance of HeadlineSearchBloc is created and provided
          // specifically for the lifecycle of this search session.
          showSearch<void>(
            context: context,
            delegate: HeadlineSearchDelegate(
              headlineSearchBloc: HeadlineSearchBloc(
                headlinesRepository: context.read<DataRepository<Headline>>(),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: AppSpacing.lg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.feedSearchHint,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // The user avatar is also tappable to open the account sheet.
              GestureDetector(
                onTap: () {
                  context.pushNamed(Routes.accountName);
                },
                child: BlocSelector<AppBloc, AppState, User?>(
                  selector: (state) => state.user,
                  builder: (context, user) {
                    return UserAvatar(user: user);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom.preferredSize.height));
}
