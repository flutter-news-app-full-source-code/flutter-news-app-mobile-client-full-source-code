import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart' hide UiKitLocalizations;

/// {@template content_limitation_bottom_sheet}
/// A bottom sheet that informs the user about content limitations and provides
/// relevant actions based on their status.
/// {@endtemplate}
class ContentLimitationBottomSheet extends StatefulWidget {
  /// {@macro content_limitation_bottom_sheet}
  const ContentLimitationBottomSheet({
    required this.title,
    required this.body,
    required this.buttonText,
    this.onButtonPressed,
    super.key,
  });

  /// The title of the bottom sheet.
  final String title;

  /// The body text of the bottom sheet.
  final String body;

  /// The text for the action button.
  final String buttonText;

  /// The callback executed when the action button is pressed.
  final VoidCallback? onButtonPressed;

  @override
  State<ContentLimitationBottomSheet> createState() =>
      _ContentLimitationBottomSheetState();
}

class _ContentLimitationBottomSheetState
    extends State<ContentLimitationBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.maxDialogContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: AppSpacing.xxl * 1.5,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.title,
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.body,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: widget.onButtonPressed,
                  child: Text(widget.buttonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A shared helper function to show the content limitation bottom sheet.
///
/// This function centralizes the logic for determining the sheet's content
/// based on the user's role and the specific limitation they have encountered.
void showContentLimitationBottomSheet({
  required BuildContext context,
  required LimitationStatus status,
  required ContentAction action,
}) {
  final l10n = AppLocalizations.of(context);
  final userTier = context.read<AppBloc>().state.user?.tier;
  final analyticsService = context.read<AnalyticsService>();

  final content = _getBottomSheetContent(
    context: context,
    l10n: l10n,
    status: status,
    userTier: userTier,
    action: action,
    analyticsService: analyticsService,
  );

  showModalBottomSheet<void>(
    context: context,
    builder: (_) => ContentLimitationBottomSheet(
      title: content.title,
      body: content.body,
      buttonText: content.buttonText,
      onButtonPressed: content.onPressed,
    ),
  );
}

/// Determines the content for the [ContentLimitationBottomSheet] based on
/// the user's tier and the limitation status.
({String title, String body, String buttonText, VoidCallback? onPressed})
_getBottomSheetContent({
  required BuildContext context,
  required AppLocalizations l10n,
  required LimitationStatus status,
  required AccessTier? userTier,
  required ContentAction action,
  required AnalyticsService analyticsService,
}) {
  switch (status) {
    case LimitationStatus.anonymousLimitReached:
      return (
        title: l10n.limitReachedGuestUserTitle,
        body: l10n.limitReachedGuestUserBody,
        buttonText: l10n.createAccountButton,
        onPressed: () {
          analyticsService.logEvent(
            AnalyticsEvent.limitExceededCtaClicked,
            payload: const LimitExceededCtaClickedPayload(
              ctaType: 'createAccount',
            ),
          );
          Navigator.of(context).pop();
          context.goNamed(Routes.accountLinkingName);
        },
      );
    case LimitationStatus.standardUserLimitReached:
      final body = switch (action) {
        ContentAction.bookmarkHeadline => l10n.limitReachedBodySave,
        ContentAction.followTopic ||
        ContentAction.followSource ||
        ContentAction.followCountry => l10n.limitReachedBodyFollow,
        ContentAction.postComment => l10n.limitReachedBodyComments,
        ContentAction.reactToContent => l10n.limitReachedBodyReactions,
        ContentAction.submitReport => l10n.limitReachedBodyReports,
        ContentAction.saveFilter => l10n.limitReachedBodySaveFilters,
        ContentAction.pinFilter => l10n.limitReachedBodyPinFilters,
        ContentAction.subscribeToSavedFilterNotifications =>
          l10n.limitReachedBodySubscribeToNotifications,
        // Add a default case for actions that don't have a specific message.
        ContentAction.editProfile => l10n.standardLimitBody,
      };

      final buttonText = l10n.unlockMoreButton;

      return (
        title: l10n.limitReachedTitle,
        body: body,
        buttonText: buttonText,
        onPressed: () {
          analyticsService.logEvent(
            AnalyticsEvent.limitExceededCtaClicked,
            payload: const LimitExceededCtaClickedPayload(
              ctaType: 'unlockRewards',
            ),
          );
          Navigator.of(context).pop();
          // Always direct to the rewards page as the primary way to
          // overcome limitations.
          context.pushNamed(Routes.rewardsName);
        },
      );
    case LimitationStatus.allowed:
      return (title: '', body: '', buttonText: '', onPressed: null);
  }
}
