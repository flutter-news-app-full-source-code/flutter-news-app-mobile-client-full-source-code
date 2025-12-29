import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionStatusBanner extends StatelessWidget {
  const SubscriptionStatusBanner({required this.subscription, super.key});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (subscription.status != SubscriptionStatus.gracePeriod &&
        subscription.status != SubscriptionStatus.billingIssue) {
      return const SizedBox.shrink();
    }

    final isGracePeriod = subscription.status == SubscriptionStatus.gracePeriod;
    final backgroundColor = isGracePeriod
        ? colorScheme.surfaceContainerHigh
        : colorScheme.errorContainer;
    final onBackgroundColor = isGracePeriod
        ? colorScheme.onSurface
        : colorScheme.onErrorContainer;
    final iconColor = isGracePeriod ? Colors.orange : colorScheme.error;
    final message = isGracePeriod
        ? l10n.subscriptionStatusGracePeriod
        : l10n.subscriptionStatusBillingIssue;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: iconColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onBackgroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => _manageSubscription(subscription.provider),
                  child: Text(
                    l10n.subscriptionDetailsManageButton,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onBackgroundColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _manageSubscription(StoreProvider provider) {
    final url = switch (provider) {
      StoreProvider.apple => Uri.parse(
        'https://apps.apple.com/account/subscriptions',
      ),
      StoreProvider.google => Uri.parse(
        'https://play.google.com/store/account/subscriptions',
      ),
    };
    launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
