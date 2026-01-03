import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/widgets/subscription_status_banner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget(UserSubscription subscription) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SubscriptionStatusBanner(subscription: subscription),
      ),
    );
  }

  group('SubscriptionStatusBanner', () {
    testWidgets('does not render for active subscription', (tester) async {
      final subscription = UserSubscription(
        id: 'sub1',
        userId: 'user1',
        tier: AccessTier.premium,
        status: SubscriptionStatus.active,
        provider: StoreProviders.google,
        validUntil: DateTime.now(),
        willAutoRenew: true,
        originalTransactionId: '123',
      );

      await tester.pumpWidget(buildTestWidget(subscription));

      expect(find.byType(SubscriptionStatusBanner), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders correctly for gracePeriod status', (tester) async {
      final subscription = UserSubscription(
        id: 'sub1',
        userId: 'user1',
        tier: AccessTier.premium,
        status: SubscriptionStatus.gracePeriod,
        provider: StoreProviders.google,
        validUntil: DateTime.now(),
        willAutoRenew: true,
        originalTransactionId: '123',
      );

      await tester.pumpWidget(buildTestWidget(subscription));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.text(
          'Your subscription is in a grace period. Please update your payment method to retain access.',
        ),
        findsOneWidget,
      );
      expect(find.text('Manage in App Store'), findsOneWidget);
    });

    testWidgets('renders correctly for billingIssue status', (tester) async {
      final subscription = UserSubscription(
        id: 'sub1',
        userId: 'user1',
        tier: AccessTier.premium,
        status: SubscriptionStatus.billingIssue,
        provider: StoreProviders.apple,
        validUntil: DateTime.now(),
        willAutoRenew: true,
        originalTransactionId: '123',
      );

      await tester.pumpWidget(buildTestWidget(subscription));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.text(
          'Your subscription is on hold due to a billing issue. Please update your payment method.',
        ),
        findsOneWidget,
      );
      expect(find.text('Manage in App Store'), findsOneWidget);
    });
  });
}
