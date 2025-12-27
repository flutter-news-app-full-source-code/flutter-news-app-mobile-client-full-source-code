import 'package:core/core.dart' hide SubscriptionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/bloc/subscription_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
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
      create: (context) => SubscriptionBloc(
        subscriptionService: context.read<SubscriptionServiceInterface>(),
        appBloc: context.read<AppBloc>(),
        remoteConfig: context.read<AppBloc>().state.remoteConfig!,
        logger: context.read<Logger>(),
      )..add(const SubscriptionStarted()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.subscriptionDetailsPageTitle)),
        body: const _SubscriptionDetailsView(),
      ),
    );
  }
}

class _SubscriptionDetailsView extends StatelessWidget {
  const _SubscriptionDetailsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    // Read subscription directly from AppBloc
    final subscription = context.select(
      (AppBloc bloc) => bloc.state.userSubscription,
    )!;

    final dateFormat = DateFormat.yMMMMd(l10n.localeName);
    final validUntil = dateFormat.format(subscription.validUntil);

    return Padding(
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
          // Show upgrade/downgrade options if available
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
    );
  }

  Widget _buildUpgradeOptions(
    BuildContext context,
    UserSubscription subscription,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state.status == SubscriptionStatus.loadingProducts) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final isMonthly = subscription.originalTransactionId.contains(
          'monthly',
        );
        final targetPlan = isMonthly ? state.annualPlan : state.monthlyPlan;

        if (targetPlan == null) return const SizedBox.shrink();

        return ListTile(
          title: Text(
            isMonthly
                ? l10n.subscriptionUpgradeTitle
                : l10n.subscriptionDowngradeTitle,
          ),
          subtitle: Text(
            isMonthly
                ? l10n.subscriptionUpgradeDescription
                : l10n.subscriptionDowngradeDescription,
          ),
          trailing: ElevatedButton(
            onPressed: () {
              // TODO: handle teh current palceholder
              //
              // Trigger purchase flow with oldPurchaseDetails for proration
              // We need to construct a PurchaseDetails object from the
              // UserSubscription data to pass to the service.
              // Note: In a real app, we might need to fetch the actual
              // PurchaseDetails from the store using restorePurchases first
              // if we don't have it cached, or rely on the service to handle
              // the token.
              // For now, we rely on the BLoC's restore logic or pass null
              // if the service can handle it via ID.
              //
              // Ideally, we should trigger a restore in the background when
              // this page loads to get the valid PurchaseDetails object
              // required by Google Play's billing client.
              context.read<SubscriptionBloc>().add(
                SubscriptionPurchaseRequested(
                  product: targetPlan,
                  // We pass the active details if available from the
                  // BLoC's state (populated via restore).
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
