import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/status/bloc/user_limit/user_limit_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template limit_exceeded_page}
/// A modal bottom sheet page displayed when a user exceeds a content preference limit.
///
/// This page provides contextual information and actions based on the user's
/// role (anonymous, standard) and the specific limit that was hit.
/// {@endtemplate}
class LimitExceededPage extends StatelessWidget {
  /// {@macro limit_exceeded_page}
  const LimitExceededPage({
    required this.limitType,
    required this.userRole,
    required this.action,
    super.key,
  });

  /// The type of limit that was exceeded.
  final LimitType limitType;

  /// The role of the user who exceeded the limit.
  final AppUserRole userRole;

  /// The recommended action for the user to take.
  final LimitAction action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    String headline;
    String subheadline;
    String buttonText = '';
    VoidCallback? onButtonPressed;
    IconData icon = Icons.info_outline;

    switch (limitType) {
      case LimitType.followedTopics:
      case LimitType.followedSources:
      case LimitType.followedCountries:
        headline = l10n.limitExceededFollowedItemsHeadline;
        subheadline = userRole == AppUserRole.guestUser
            ? l10n.limitExceededFollowedItemsSubheadlineAnonymous
            : l10n.limitExceededFollowedItemsSubheadlineStandard;
        icon = Icons.person_add_alt_outlined;
        break;
      case LimitType.savedHeadlines:
        headline = l10n.limitExceededSavedHeadlinesHeadline;
        subheadline = userRole == AppUserRole.guestUser
            ? l10n.limitExceededSavedHeadlinesSubheadlineAnonymous
            : l10n.limitExceededSavedHeadlinesSubheadlineStandard;
        icon = Icons.bookmark_add_outlined;
        break;
    }

    switch (action) {
      case LimitAction.linkAccount:
        buttonText = l10n.linkAccountButton;
        onButtonPressed = () {
          context.pop(); // Dismiss the current modal
          context.pushNamed(Routes.accountLinkingPageName); // Navigate to linking page
          context.read<UserLimitBloc>().add(const LimitActionTaken());
        };
        break;
      case LimitAction.upgradeToPremium:
        buttonText = l10n.upgradeToPremiumButton;
        onButtonPressed = () {
          context.pop(); // Dismiss the current modal
          // TODO(fulleni): Navigate to a dedicated upgrade page
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.upgradeToPremiumSnackbar),
                backgroundColor: colorScheme.primary,
              ),
            );
          context.read<UserLimitBloc>().add(const LimitActionTaken());
        };
        break;
      case LimitAction.none:
        // This case should ideally not be reached if a limit is exceeded for premium users.
        // If it is, it means premium users have no practical limit, or an error occurred.
        buttonText = l10n.okButtonLabel;
        onButtonPressed = () {
          context.pop();
          context.read<UserLimitBloc>().add(const LimitActionTaken());
        };
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.limitExceededPageTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () {
            context.pop();
            context.read<UserLimitBloc>().add(const LimitActionTaken());
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    icon,
                    size: AppSpacing.xxl * 2,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    headline,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    subheadline,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (onButtonPressed != null)
                    ElevatedButton(
                      onPressed: onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        textStyle: textTheme.labelLarge,
                      ),
                      child: Text(buttonText),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
