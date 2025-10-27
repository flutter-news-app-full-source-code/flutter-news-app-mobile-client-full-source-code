import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template decorator_dismissed_widget}
/// A widget displayed in place of a feed decorator after it has been
/// dismissed by the user.
///
/// This widget's height dynamically adjusts to match the user's selected
/// headline tile style to prevent layout shifts in the feed.
/// {@endtemplate}
class DecoratorDismissedWidget extends StatelessWidget {
  /// {@macro decorator_dismissed_widget}
  const DecoratorDismissedWidget({super.key});

  /// Determines the height of the widget based on the user's feed preference.
  ///
  /// This ensures that when a decorator is dismissed, the placeholder that
  /// replaces it has a similar height to the surrounding headline tiles,
  /// preventing a jarring layout shift.
  double _getDynamicHeight(HeadlineImageStyle imageStyle) {
    return switch (imageStyle) {
      // Approximate height for a text-only list tile.
      HeadlineImageStyle.hidden => 80,
      // Approximate height for a list tile with a leading image.
      HeadlineImageStyle.smallThumbnail => 100,
      // Approximate height for a card with an image on top.
      HeadlineImageStyle.largeThumbnail => 280,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizationsX(context).l10n;
    final headlineImageStyle = context
        .watch<AppBloc>()
        .state
        .headlineImageStyle;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SizedBox(
        // The height is dynamically set to match the current headline tile
        // style, ensuring a smooth visual transition upon dismissal.
        height: _getDynamicHeight(headlineImageStyle),
        child: Center(
          child: Text(
            l10n.decoratorDismissedConfirmation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
