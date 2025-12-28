import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/bloc/subscription_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionBloc(
        subscriptionService: context.read<SubscriptionServiceInterface>(),
        appBloc: context.read<AppBloc>(),
        remoteConfig: context.read<AppBloc>().state.remoteConfig!,
        logger: context.read<Logger>(),
      )..add(const SubscriptionStarted()),
      child: const _PaywallView(),
    );
  }
}

class _PaywallView extends StatelessWidget {
  const _PaywallView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.status == SubscriptionStatus.success) {
          // Show success dialog and then pop
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(l10n.paywallSuccessTitle),
              content: Text(l10n.paywallSuccessBody),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    context.pop(); // Close paywall
                  },
                  child: Text(l10n.gotItButton),
                ),
              ],
            ),
          );
        } else if (state.status == SubscriptionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.paywallErrorTitle}: ${state.error}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        } else if (state.status == SubscriptionStatus.restorationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.paywallRestoreSuccess),
            ),
          );
        } else if (state.status == SubscriptionStatus.restorationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.paywallRestoreFailure),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        final isLoading =
            state.status == SubscriptionStatus.loadingProducts ||
            state.status == SubscriptionStatus.purchasing ||
            state.status == SubscriptionStatus.restoring;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            title: Text(l10n.paywallTitle),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, l10n),
                    const SizedBox(height: AppSpacing.lg),
                    _buildFeaturesList(context, l10n),
                    const SizedBox(height: AppSpacing.xxl),
                    if (state.products.isNotEmpty)
                      _buildPlans(context, state, l10n)
                    else if (state.status == SubscriptionStatus.loadingProducts)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Center(child: Text(l10n.unknownError)),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildFooter(context, l10n),
                  ],
                ),
              ),
              if (isLoading)
                ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.paywallLoading,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: state.products.isNotEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ElevatedButton(
                      onPressed: isLoading || state.selectedProduct == null
                          ? null
                          : () {
                              final product = state.selectedProduct!;
                              final currentSubId = context
                                  .read<AppBloc>()
                                  .state
                                  .userSubscription
                                  ?.originalTransactionId;
                              context.read<SubscriptionBloc>().add(
                                SubscriptionPurchaseRequested(
                                  product: product,
                                  oldPurchaseDetails: currentSubId != null
                                      ? state.activePurchaseDetails
                                      : null,
                                ),
                              );
                            },
                      child: Text(
                        l10n.paywallSubscribeButton(
                          state.selectedProduct?.price ?? '',
                          '', // Period is hard to extract generically, leaving empty for now or needs logic
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    ));
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          Icons.workspace_premium,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.paywallTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.paywallSubtitle,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context, AppLocalizations l10n) {
    final features = [
      l10n.paywallFeatureFollowMore,
      l10n.paywallFeatureSaveMore,
      l10n.paywallFeatureAdvancedFilters,
      l10n.paywallFeatureUnlimitedHistory,
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlans(
    BuildContext context,
    SubscriptionState state,
    AppLocalizations l10n,
  ) {
    final monthly = state.monthlyPlan;
    final annual = state.annualPlan;

    return Column(
      children: [
        if (annual != null)
          _buildPlanCard(
            context,
            annual,
            l10n: l10n,
            isRecommended: true,
            isSelected: state.selectedProduct?.id == annual.id,
            isCurrent: false, // Acquisition only
            onTap: () => context.read<SubscriptionBloc>().add(
              SubscriptionPlanSelected(annual),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (monthly != null)
          _buildPlanCard(
            context,
            monthly,
            l10n: l10n,
            isRecommended: false,
            isSelected: state.selectedProduct?.id == monthly.id,
            isCurrent: false, // Acquisition only
            onTap: () => context.read<SubscriptionBloc>().add(
              SubscriptionPlanSelected(monthly),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    ProductDetails product, {
    required AppLocalizations l10n,
    required bool isRecommended,
    required bool isSelected,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: isCurrent ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Radio<String>(
                value: product.id,
                groupValue: isSelected ? product.id : null,
                onChanged: isCurrent ? null : (_) => onTap(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Localize demo products if keys match
                    Text(
                      product.title == 'demoAnnualPlanTitle'
                          ? l10n.demoAnnualPlanTitle
                          : (product.title == 'demoMonthlyPlanTitle'
                                ? l10n.demoMonthlyPlanTitle
                                : (isRecommended
                                      ? l10n.paywallAnnualPlan
                                      : l10n.paywallMonthlyPlan)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(product.price, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
              if (isCurrent)
                Text(
                  l10n.subscriptionCurrentPlan,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              if (isRecommended && !isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    l10n.paywallBestValue,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      children: [
        TextButton(
          onPressed: () => context.read<SubscriptionBloc>().add(
            const SubscriptionRestoreRequested(),
          ),
          child: Text(l10n.paywallRestorePurchases),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.paywallDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLink(
              context,
              l10n.paywallTermsOfService,
              context
                  .read<AppBloc>()
                  .state
                  .remoteConfig!
                  .app
                  .general
                  .termsOfServiceUrl,
            ),
            const Text(' • '),
            _buildLink(
              context,
              l10n.paywallPrivacyPolicy,
              context
                  .read<AppBloc>()
                  .state
                  .remoteConfig!
                  .app
                  .general
                  .privacyPolicyUrl,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLink(BuildContext context, String text, String url) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(decoration: TextDecoration.underline),
      ),
    );
  }
}
