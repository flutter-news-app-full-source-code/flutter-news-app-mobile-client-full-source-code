import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/rewarded_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/rewards/bloc/rewards_bloc.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template rewards_page}
/// A page that displays available rewards and offers to the user.
///
/// Allows users to watch ads to unlock features like 'Ad-Free' or 'Daily Digest'.
/// Handles the ad presentation flow and displays the status of active rewards.
/// {@endtemplate}
class RewardsPage extends StatelessWidget {
  /// {@macro rewards_page}
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RewardsBloc(
        appBloc: context.read<AppBloc>(),
        analyticsService: context.read<AnalyticsService>(),
      )..add(RewardsStarted()),
      child: const _RewardsPageView(),
    );
  }
}

class _RewardsPageView extends StatelessWidget {
  const _RewardsPageView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rewardsBloc = context.read<RewardsBloc>();

    void handleWatchAd(RewardType type) {
      final adManager = context.read<RewardedAdManager>();
      var isRewardEarned = false;

      unawaited(
        context.read<AnalyticsService>().logEvent(
          AnalyticsEvent.rewardOfferClicked,
          payload: RewardOfferClickedPayload(rewardType: type),
        ),
      );

      rewardsBloc.add(RewardsAdRequested(type: type));

      adManager.showAd(
        rewardType: type,
        onAdShowed: () {
          // Ad is showing, BLoC state is already RewardsLoadingAd.
        },
        onAdDismissed: () {
          // This is called when the user closes the ad.
          // If the reward was not earned, then it was a premature dismissal.
          if (!isRewardEarned) {
            rewardsBloc.add(RewardsAdDismissed());
          }
        },
        onAdFailedToShow: (error) {
          rewardsBloc.add(RewardsAdFailed());
        },
        onRewardEarned: (earnedType) {
          // This is the success signal.
          isRewardEarned = true;
          rewardsBloc.add(RewardsAdWatched());
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rewardsPageTitle)),
      body: BlocConsumer<RewardsBloc, RewardsState>(
        listenWhen: (previous, current) =>
            current.snackbarMessage != null ||
            (previous is! RewardsSuccess && current is RewardsSuccess),
        listener: (context, state) {
          if (state.snackbarMessage != null) {
            final message = state.snackbarMessage == 'rewardsSnackbarFailure'
                ? l10n.rewardsSnackbarFailure
                : l10n.rewardsAdDismissedSnackbar;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            rewardsBloc.add(SnackbarShown());
          } else if (state is RewardsSuccess) {
            final rewardName = state.activeRewardType == RewardType.adFree
                ? l10n.rewardTypeAdFree
                : l10n.rewardTypeDailyDigest;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.rewardsSnackbarSuccess(rewardName)),
                ),
              );
          }
        },
        builder: (context, state) {
          // We need to watch AppBloc for the actual rewards data configuration
          final appState = context.watch<AppBloc>().state;
          final rewardsConfig = appState.remoteConfig?.features.rewards;
          final userRewards = appState.userRewards;

          final availableRewards =
              rewardsConfig?.rewards.entries
                  .where((e) => e.value.enabled)
                  .toList() ??
              [];

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: availableRewards.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final entry = availableRewards[index];
              final type = entry.key;
              final details = entry.value;
              final isActive = userRewards?.isRewardActive(type) ?? false;

              final isVerifying =
                  state is RewardsVerifying && state.activeRewardType == type;
              final isLoading =
                  state is RewardsLoadingAd && state.activeRewardType == type;

              // Calculate expiration if active
              DateTime? expiry;
              if (isActive) {
                expiry = userRewards?.activeRewards[type];
              }

              return _RewardOfferCard(
                type: type,
                durationDays: details.durationDays,
                isActive: isActive,
                isVerifying: isVerifying,
                isLoading: isLoading,
                expiry: expiry,
                onTap: () => handleWatchAd(type),
              );
            },
          );
        },
      ),
    );
  }
}

class _RewardOfferCard extends StatelessWidget {
  const _RewardOfferCard({
    required this.type,
    required this.durationDays,
    required this.isActive,
    required this.isVerifying,
    required this.isLoading,
    required this.onTap,
    this.expiry,
  });

  final RewardType type;
  final int durationDays;
  final bool isActive;
  final bool isVerifying;
  final bool isLoading;
  final VoidCallback onTap;
  final DateTime? expiry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final rewardName = type == RewardType.adFree
        ? l10n
              .rewardTypeAdFree // Simple name for active state
        : l10n.rewardTypeDailyDigest;

    final durationString = l10n.rewardsDurationDays(durationDays);

    final title = isActive
        ? l10n.rewardsOfferActiveTitle(rewardName)
        : (type == RewardType.adFree
              ? l10n.rewardsAdFreeTitle
              : l10n.rewardsDailyDigestTitle);

    final description = type == RewardType.adFree
        ? l10n.rewardsAdFreeDescription(durationString)
        : l10n.rewardsDailyDigestDescription(durationString);

    return Card(
      elevation: 0,
      color: isActive
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: BorderSide(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.stars,
                  color: isActive ? colorScheme.primary : colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (isActive && expiry != null)
              _CountdownTimer(expiry: expiry!)
            else
              Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (isActive || isVerifying || isLoading)
                    ? null
                    : onTap,
                child: (isVerifying || isLoading)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isLoading
                                ? l10n.rewardsOfferLoadingButton
                                : l10n.rewardsOfferVerifyingButton,
                          ),
                        ],
                      )
                    : Text(
                        isActive
                            ? l10n.rewardsOfferActiveButton
                            : l10n.rewardsOfferWatchButton,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownTimer extends StatelessWidget {
  const _CountdownTimer({required this.expiry});

  final DateTime expiry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: Stream<int>.periodic(const Duration(minutes: 1), (x) => x),
      builder: (context, snapshot) {
        final now = DateTime.now();
        if (now.isAfter(expiry)) {
          return const SizedBox.shrink();
        }
        final difference = expiry.difference(now);
        final hours = difference.inHours;
        final minutes = difference.inMinutes.remainder(60);

        return Text(
          l10n.rewardsOfferExpiresIn('${hours}h ${minutes}m'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
