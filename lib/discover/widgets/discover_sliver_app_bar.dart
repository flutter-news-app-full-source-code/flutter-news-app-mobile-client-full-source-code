import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/search/bloc/source_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/view/source_search_delegate.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/user_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template discover_sliver_app_bar}
/// A sliver app bar for the discover page that includes a custom search bar.
///
/// This app bar is visually consistent with the feed's app bar but is
/// adapted for searching sources instead of headlines.
/// {@endtemplate}
class DiscoverSliverAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// {@macro discover_sliver_app_bar}
  const DiscoverSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizationsX(context).l10n;

    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      // The title is a custom search bar widget.
      title: GestureDetector(
        onTap: () {
          // When the search bar is tapped, show the source search delegate.
          // A new instance of SourceSearchBloc is created and provided
          // specifically for the lifecycle of this search session.
          showSearch<void>(
            context: context,
            delegate: SourceSearchDelegate(
              sourceSearchBloc: SourceSearchBloc(
                sourcesRepository: context.read<DataRepository<Source>>(),
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
                  l10n.discoverSearchHint,
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
