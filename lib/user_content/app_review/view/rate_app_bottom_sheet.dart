import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template rate_app_bottom_sheet}
/// A bottom sheet that serves as the initial prompt in the app review funnel.
///
/// It asks a simple "Yes/No" question to gauge user sentiment before
/// deciding whether to request a native store review.
/// {@endtemplate}
class RateAppBottomSheet extends StatelessWidget {
  /// {@macro rate_app_bottom_sheet}
  const RateAppBottomSheet({required this.onResponse, super.key});

  /// Callback function that is triggered when the user taps "Yes" or "No".
  /// The boolean parameter indicates if the response was positive.
  final ValueChanged<bool> onResponse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Determine which set of strings to use based on user's feedback history.
    final hasGivenNegativeFeedback =
        context
            .read<AppBloc>()
            .state
            .userContext
            ?.feedDecoratorStatus[FeedDecoratorType.rateApp]
            ?.lastShownAt !=
        null;

    final title = hasGivenNegativeFeedback
        ? l10n.rateAppNegativeFollowUpTitle_1
        : l10n.rateAppPromptTitle;
    final body = hasGivenNegativeFeedback
        ? l10n.rateAppNegativeFollowUpBody_1
        : l10n.rateAppPromptBody;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.maxDialogContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_half, size: 48, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                body,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onResponse(false);
                      },
                      child: Text(l10n.rateAppPromptNoButton),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onResponse(true);
                      },
                      child: Text(l10n.rateAppPromptYesButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
