import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/rewarded_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template rewards_page}
/// A page that displays available rewards and offers to the user.
///
/// Allows users to watch ads to unlock features like 'Ad-Free' or 'Daily Digest'.
/// Handles the ad presentation flow and displays the status of active rewards.
/// {@endtemplate}
class RewardsPage extends StatefulWidget {
  /// {@macro rewards_page}
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  // Tracks which reward is currently being verified to show a loading state.
  RewardType? _verifyingReward;

  void _handleWatchAd(RewardType type) {
    final adManager = context.read<RewardedAdManager>();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    adManager.showAd(
      rewardType: type,
      onAdShowed: () {
        // Ad is showing, no specific UI update needed here.
      },
      onAdDismissed: () {
        // If we were verifying, we keep the verifying state until the
        // AppBloc updates or a timeout occurs.
      },
      onAdFailedToShow: (error) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.rewardsSnackbarFailure)),
        );
        setState(() {
          _verifyingReward = null;
        });
      },
      onRewardEarned: (earnedType) {
        setState(() {
          _verifyingReward = earnedType;
        });
        // Trigger the refresh in AppBloc. The UI will update automatically
        // when the new state with the active reward is emitted.
        context.read<AppBloc>().add(const UserRewardsRefreshed());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rewardsPageTitle),
      ),
      body: BlocConsumer<AppBloc, AppState>(
        listener: (context, state) {
          // If the reward we were verifying is now active, clear the loading state
          // and show success message.
          if (_verifyingReward != null) {
            final isNowActive =
                state.userRewards?.isRewardActive(_verifyingReward!) ?? false;
            if (isNowActive) {
              final rewardName = _verifyingReward == RewardType.adFree
                  ? l10n.rewardTypeAdFree
                  : l10n.rewardTypeDailyDigest;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.rewardsSnackbarSuccess.replaceFirst(
                      '{rewardName}',
                      rewardName,
                    ),
                  ),
                ),
              );
              setState(() {
                _verifyingReward = null;
              });
            }
          }
        },
        builder: (context, state) {
          final rewardsConfig = state.remoteConfig?.features.rewards;
          final userRewards = state.userRewards;

          if (rewardsConfig == null || !rewardsConfig.enabled) {
            return Center(
              child: EmptyStateMessage(
                title: l10n.maintenanceHeadline,
                subtitle: l10n.maintenanceSubheadline,
              ),
            );
          }

          final availableRewards = rewardsConfig.rewards.entries
              .where((e) => e.value.enabled)
              .toList();

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
              final isVerifying = _verifyingReward == type;

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
                expiry: expiry,
                onTap: () => _handleWatchAd(type),
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
    required this.onTap,
    this.expiry,
  });

  final RewardType type;
  final int durationDays;
  final bool isActive;
  final bool isVerifying;
  final VoidCallback onTap;
  final DateTime? expiry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final rewardName = type == RewardType.adFree
        ? l10n.rewardTypeAdFree
        : l10n.rewardTypeDailyDigest;

    final durationString = '$durationDays ${durationDays == 1 ? "Day" : "Days"}'; // Simple pluralization, ideally localized

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
                    isActive
                        ? l10n.rewardsOfferActiveTitle.replaceFirst(
                            '{rewardName}',
                            rewardName,
                          )
                        : l10n.rewardsOfferTitle(rewardName, durationString),
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
              Text(
                type == RewardType.adFree
                    ? l10n.decoratorUnlockRewardsDescription
                    : 'Unlock daily digests for $durationString.', // Fallback description
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (isActive || isVerifying) ? null : onTap,
                child: isVerifying
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.rewardsOfferVerifyingButton),
                        ],
                      )
                    : Text(
                        isActive
                            ? l10n.rewardsOfferActiveTitle.replaceFirst('{rewardName}', '') // Just "Active" roughly
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
      stream: Stream.periodic(const Duration(minutes: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        if (now.isAfter(expiry)) {
          return const SizedBox.shrink();
        }
        final difference = expiry.difference(now);
        final hours = difference.inHours;
        final minutes = difference.inMinutes.remainder(60);

        return Text(
          l10n.rewardsOfferExpiresIn.replaceFirst(
            '{countdown}',
            '${hours}h ${minutes}m',
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
