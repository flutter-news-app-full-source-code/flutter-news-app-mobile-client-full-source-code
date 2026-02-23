import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/rewarded_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/rewards/bloc/rewards_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
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

    void handleWatchAd() {
      final adManager = context.read<RewardedAdManager>();
      var isRewardEarned = false;

      unawaited(
        context.read<AnalyticsService>().logEvent(
          AnalyticsEvent.rewardOfferClicked,
          payload: const RewardOfferClickedPayload(
            rewardType: RewardType.adFree,
          ),
        ),
      );

      rewardsBloc.add(RewardsAdRequested());

      adManager.showAd(
        rewardType: RewardType.adFree,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.rewardsAdFreePageTitle),
        centerTitle: true,
      ),
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
            final rewardName = l10n.rewardTypeAdFree;

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
          final adFreeDetails = rewardsConfig?.rewards[RewardType.adFree];
          final userRewards = appState.userRewards;

          if (adFreeDetails == null || !adFreeDetails.enabled) {
            return const SizedBox.shrink();
          }

          final isActive =
              userRewards?.isRewardActive(RewardType.adFree) ?? false;
          final isVerifying = state is RewardsVerifying;
          final isLoading = state is RewardsLoadingAd;
          final expiry = isActive
              ? userRewards?.activeRewards[RewardType.adFree]
              : null;

          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxDialogContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _RewardOfferCard(
                    durationDays: adFreeDetails.durationDays,
                    isActive: isActive,
                    isVerifying: isVerifying,
                    isLoading: isLoading,
                    expiry: expiry,
                    onTap: handleWatchAd,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RewardOfferCard extends StatelessWidget {
  const _RewardOfferCard({
    required this.durationDays,
    required this.isActive,
    required this.isVerifying,
    required this.isLoading,
    required this.onTap,
    this.expiry,
  });
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.card_giftcard_outlined,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: AppSpacing.xxl * 2,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isActive
              ? l10n.rewardsAdFreeActiveHeadline
              : l10n.rewardsAdFreeInactiveHeadline,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive ? colorScheme.primary : null,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        if (isActive && expiry != null) ...[
          Text(
            l10n.rewardsAdFreeActiveBody,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CountdownTimer(expiry: expiry!),
        ] else ...[
          Text(
            l10n.rewardsAdFreeInactiveBody(
              l10n.rewardsDurationDays(durationDays),
            ),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (isActive || isVerifying || isLoading) ? null : onTap,
              icon: (isVerifying || isLoading)
                  ? const SizedBox(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(
                isLoading
                    ? l10n.rewardsOfferLoadingButton
                    : isVerifying
                    ? l10n.rewardsOfferVerifyingButton
                    : l10n.rewardsOfferWatchButton,
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        if (isActive) const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({required this.expiry});

  final DateTime expiry;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(_updateRemaining);
      }
    });
  }

  void _updateRemaining() {
    _remaining = widget.expiry.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (days > 0) {
      return '$days d $hours h $minutes m $seconds s';
    } else if (duration.inHours > 0) {
      return '$hours h $minutes m $seconds s';
    } else if (duration.inMinutes > 0) {
      return '$minutes m $seconds s';
    } else {
      return '$seconds s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_remaining.isNegative || _remaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    return Text(
      l10n.rewardsOfferExpiresIn(_formatDuration(_remaining)),
      style: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}
