import 'package:collection/collection.dart';
import 'package:core/core.dart' hide SubscriptionStatus;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/bloc/subscription_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return BlocProvider(
      create: (context) =>
          SubscriptionBloc(
              subscriptionService: context.read<SubscriptionServiceInterface>(),
              appBloc: context.read<AppBloc>(),
              remoteConfig: context.read<AppBloc>().state.remoteConfig!,
              logger: context.read<Logger>(),
            )
            ..add(const SubscriptionStarted())
            // Silently restore purchases to get the latest PurchaseDetails
            // object required for upgrades/downgrades on Android.
            ..add(const SubscriptionRestoreRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.subscriptionDetailsPageTitle)),
        body: const SubscriptionDetailsView(),
      ),
    );
  }
}

class SubscriptionDetailsView extends StatelessWidget {
  const SubscriptionDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    // Read subscription directly from AppBloc
    final subscription = context.select(
      (AppBloc bloc) => bloc.state.userSubscription,
    )!;

    final dateFormat = DateFormat.yMMMMd(l10n.localeName);
    final validUntil = dateFormat.format(subscription.validUntil);

    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.status == SubscriptionStatus.success) {
          // On successful purchase (upgrade/downgrade), show a confirmation
          // and navigate back to the account page.
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Plan changed successfully!')),
            );
          context.goNamed(Routes.accountName);
        }
        if (state.status == SubscriptionStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.error?.toString() ?? l10n.unknownError),
              ),
            );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(l10n.subscriptionDetailsCurrentPlan),
              subtitle: Text(
                subscription.tier == AccessTier.premium
                    ? l10n.accountRolePremium
                    : subscription.tier.name,
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                subscription.willAutoRenew
                    ? l10n.subscriptionDetailsRenewsOn(validUntil)
                    : l10n.subscriptionDetailsExpiresOn(validUntil),
              ),
              subtitle: !subscription.willAutoRenew
                  ? Text(l10n.subscriptionDetailsWillNotRenew)
                  : null,
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.subscriptionDetailsProvider),
              subtitle: Text(
                subscription.provider == StoreProvider.apple
                    ? 'Apple App Store'
                    : 'Google Play Store',
              ),
            ),
            const Divider(),
            _buildUpgradeOptions(context, subscription, l10n),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final url = switch (subscription.provider) {
                    StoreProvider.apple => Uri.parse(
                      'https://apps.apple.com/account/subscriptions',
                    ),
                    StoreProvider.google => Uri.parse(
                      'https://play.google.com/store/account/subscriptions',
                    ),
                  };
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: Text(l10n.subscriptionDetailsManageButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeOptions(
    BuildContext context,
    UserSubscription subscription,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state.status == SubscriptionStatus.loadingProducts ||
            state.status == SubscriptionStatus.restoring) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // 1. Get RemoteConfig to identify plan IDs
        final remoteConfig = context.read<AppBloc>().state.remoteConfig;
        if (remoteConfig == null) return const SizedBox.shrink();

        final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
        final subConfig = remoteConfig.features.subscription;

        final monthlyId = isIOS
            ? subConfig.monthlyPlan.appleProductId
            : subConfig.monthlyPlan.googleProductId;
        final annualId = isIOS
            ? subConfig.annualPlan.appleProductId
            : subConfig.annualPlan.googleProductId;

        // 2. Determine current plan from activePurchaseDetails (restored)
        final currentProductId = state.activePurchaseDetails?.productID;

        // If we don't know the current product ID (e.g. restore failed),
        // we can't safely offer a switch.
        if (currentProductId == null) {
          return const SizedBox.shrink();
        }

        final isCurrentlyMonthly = currentProductId == monthlyId;
        final isCurrentlyAnnual = currentProductId == annualId;

        // If the current product doesn't match our config, hide options.
        if (!isCurrentlyMonthly && !isCurrentlyAnnual) {
          return const SizedBox.shrink();
        }

        // 3. Determine target plan
        final targetPlanId = isCurrentlyMonthly ? annualId : monthlyId;
        if (targetPlanId == null) return const SizedBox.shrink();

        final targetProduct = state.products.firstWhereOrNull(
          (p) => p.id == targetPlanId,
        );

        if (targetProduct == null) return const SizedBox.shrink();

        return ListTile(
          title: Text(
            isCurrentlyMonthly
                ? l10n.subscriptionUpgradeTitle
                : l10n.subscriptionDowngradeTitle,
          ),
          subtitle: Text(
            isCurrentlyMonthly
                ? l10n.subscriptionUpgradeDescription
                : l10n.subscriptionDowngradeDescription,
          ),
          trailing: ElevatedButton(
            onPressed: () {
              context.read<SubscriptionBloc>().add(
                SubscriptionPurchaseRequested(
                  product: targetProduct,
                  oldPurchaseDetails: state.activePurchaseDetails,
                ),
              );
            },
            child: Text(l10n.subscriptionSwitchButton),
          ),
        );
      },
    );
  }
}
