import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/models/limit_reached_arguments.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template limit_reached_page}
/// A page displayed to the user when they have reached a content limit
/// (e.g., maximum followed topics, saved headlines).
///
/// This page provides context-aware messaging and calls to action
/// (e.g., sign in, upgrade to premium) based on the [LimitReachedArguments].
/// {@endtemplate}
class LimitReachedPage extends StatelessWidget {
  /// {@macro limit_reached_page}
  const LimitReachedPage({required this.args, super.key});

  /// The arguments providing context about the limit that was reached.
  final LimitReachedArguments args;

  /// Returns the appropriate icon for the given [LimitType].
  IconData _getIconForLimitType(LimitType limitType) {
    switch (limitType) {
      case LimitType.followedTopics:
        return Icons.topic_outlined;
      case LimitType.followedSources:
        return Icons.source_outlined;
      case LimitType.followedCountries:
        return Icons.flag_outlined;
      case LimitType.savedHeadlines:
        return Icons.bookmark_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    String headline;
    String subheadline;
    Widget? actionButton;

    final isGuest = args.userRole == AppUserRole.guestUser;
    final isStandard = args.userRole == AppUserRole.standardUser;
    final isPremium = args.userRole == AppUserRole.premiumUser;

    final isFollowLimit =
        args.limitType == LimitType.followedTopics ||
        args.limitType == LimitType.followedSources ||
        args.limitType == LimitType.followedCountries;

    if (isGuest) {
      headline = isFollowLimit
          ? l10n.followedItemsLimitGuestHeadline
          : l10n.savedHeadlinesLimitGuestHeadline;
      subheadline = isFollowLimit
          ? l10n.followedItemsLimitGuestSubheadline
          : l10n.savedHeadlinesLimitGuestSubheadline;
      actionButton = ElevatedButton(
        onPressed: () {
          // Navigate to the authentication page, passing the redirect path
          // and a specific auth context for limit enforcement.
          context.goNamed(
            Routes.authenticationName,
            queryParameters: {
              'authContext': 'limit_reached',
              if (args.redirectPath != null) 'redirectPath': args.redirectPath,
            },
          );
        },
        child: Text(
          isFollowLimit
              ? l10n.followedItemsLimitSignInButton
              : l10n.savedHeadlinesLimitSignInButton,
        ),
      );
    } else if (isStandard) {
      headline = isFollowLimit
          ? l10n.followedItemsLimitStandardHeadline
          : l10n.savedHeadlinesLimitStandardHeadline;
      subheadline = isFollowLimit
          ? l10n.followedItemsLimitStandardSubheadline
          : l10n.savedHeadlinesLimitStandardSubheadline;
      actionButton = ElevatedButton(
        onPressed: () {
          // TODO(fulleni): Implement navigation to upgrade page
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.upgradeToPremiumMessage)));
        },
        child: Text(
          isFollowLimit
              ? l10n.followedItemsLimitUpgradeButton
              : l10n.savedHeadlinesLimitUpgradeButton,
        ),
      );
    } else if (isPremium) {
      headline = isFollowLimit
          ? l10n.followedItemsLimitPremiumHeadline
          : l10n.savedHeadlinesLimitPremiumHeadline;
      subheadline = isFollowLimit
          ? l10n.followedItemsLimitPremiumSubheadline
          : l10n.savedHeadlinesLimitPremiumSubheadline;
    } else {
      headline = l10n.limitReachedGenericHeadline;
      subheadline = l10n.limitReachedGenericSubheadline;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.limitReachedPageTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () {
            // Navigate back to the redirectPath or default to the feed.
            context.go(args.redirectPath ?? Routes.feed);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingLarge),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  _getIconForLimitType(args.limitType),
                  size: AppSpacing.xxl * 2,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  headline,
                  style: textTheme.headlineMedium?.copyWith(
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
                if (actionButton != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(width: double.infinity, child: actionButton),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
