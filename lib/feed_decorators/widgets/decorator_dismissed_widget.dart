import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template decorator_dismissed_widget}
/// A widget displayed in place of a feed decorator after it has been
/// dismissed by the user.
/// {@endtemplate}
class DecoratorDismissedWidget extends StatelessWidget {
  /// {@macro decorator_dismissed_widget}
  const DecoratorDismissedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizationsX(context).l10n;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // TODO(fulleni): size must reflect the hight of the selected headlines feed tile widget.
      child: SizedBox(
        // This height is an approximation of the CallToActionDecoratorWidget's
        // height to ensure minimal layout shift upon dismissal.
        height: 140,
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
