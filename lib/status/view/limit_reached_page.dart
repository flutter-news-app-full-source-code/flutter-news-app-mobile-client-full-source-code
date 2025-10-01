import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Determine content based on limit type and user role
    String headline;
    String subheadline;
    List<Widget> actions = [];

    final isGuest = args.userRole == AppUserRole.guestUser;
    final isStandard = args.userRole == AppUserRole.standardUser;
    final isPremium = args.userRole == AppUserRole.premiumUser;

    switch (args.limitType) {
      case LimitType.followedTopics:
      case LimitType.followedSources:
      case LimitType.followedCountries:
        if (isGuest) {
          headline = l10n.followedItemsLimitGuestHeadline;
          subheadline = l10n.followedItemsLimitGuestSubheadline;
          actions = [
            ElevatedButton(
              onPressed: () {
                context.goNamed(
                  Routes.authenticationName,
                  queryParameters: {'context': 'linking'},
                );
              },
              child: Text(l10n.followedItemsLimitSignInButton),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () {
                // TODO(fulleni): Implement navigation to upgrade page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.upgradeToPremiumMessage)),
                );
              },
              child: Text(l10n.followedItemsLimitUpgradeButton),
            ),
          ];
        } else if (isStandard) {
          headline = l10n.followedItemsLimitStandardHeadline;
          subheadline = l10n.followedItemsLimitStandardSubheadline;
          actions = [
            ElevatedButton(
              onPressed: () {
                // TODO(fulleni): Implement navigation to upgrade page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.upgradeToPremiumMessage)),
                );
              },
              child: Text(l10n.followedItemsLimitUpgradeButton),
            ),
          ];
        } else if (isPremium) {
          headline = l10n.followedItemsLimitPremiumHeadline;
          subheadline = l10n.followedItemsLimitPremiumSubheadline;
          // No actions for premium users, as they are at the highest tier
        } else {
          headline = l10n.limitReachedGenericHeadline;
          subheadline = l10n.limitReachedGenericSubheadline;
        }
        break;
      case LimitType.savedHeadlines:
        if (isGuest) {
          headline = l10n.savedHeadlinesLimitGuestHeadline;
          subheadline = l10n.savedHeadlinesLimitGuestSubheadline;
          actions = [
            ElevatedButton(
              onPressed: () {
                context.goNamed(
                  Routes.authenticationName,
                  queryParameters: {'context': 'linking'},
                );
              },
              child: Text(l10n.savedHeadlinesLimitSignInButton),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () {
                // TODO(fulleni): Implement navigation to upgrade page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.upgradeToPremiumMessage)),
                );
              },
              child: Text(l10n.savedHeadlinesLimitUpgradeButton),
            ),
          ];
        } else if (isStandard) {
          headline = l10n.savedHeadlinesLimitStandardHeadline;
          subheadline = l10n.savedHeadlinesLimitStandardSubheadline;
          actions = [
            ElevatedButton(
              onPressed: () {
                // TODO(fulleni): Implement navigation to upgrade page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.upgradeToPremiumMessage)),
                );
              },
              child: Text(l10n.savedHeadlinesLimitUpgradeButton),
            ),
          ];
        } else if (isPremium) {
          headline = l10n.savedHeadlinesLimitPremiumHeadline;
          subheadline = l10n.savedHeadlinesLimitPremiumSubheadline;
          // No actions for premium users
        } else {
          headline = l10n.limitReachedGenericHeadline;
          subheadline = l10n.limitReachedGenericSubheadline;
        }
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.limitReachedPageTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () {
            context.pop();
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
                  Icons.lock_outline,
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
                const SizedBox(height: AppSpacing.xxl),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
