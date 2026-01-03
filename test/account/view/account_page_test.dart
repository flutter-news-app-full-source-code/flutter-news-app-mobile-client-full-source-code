import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/account_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/widgets/subscription_status_banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late AppBloc mockAppBloc;
  late MockNavigatorObserver mockNavigatorObserver;

  final standardUser = User(
    id: 'user1',
    email: 'test@test.com',
    role: UserRole.user,
    tier: AccessTier.standard,
    createdAt: DateTime.now(),
  );

  final premiumUser = standardUser.copyWith(tier: AccessTier.premium);

  final activeSubscription = UserSubscription(
    id: 'sub1',
    userId: 'user1',
    tier: AccessTier.premium,
    status: SubscriptionStatus.active,
    provider: StoreProviders.google,
    validUntil: DateTime.now().add(const Duration(days: 30)),
    willAutoRenew: true,
    originalTransactionId: 'gpa.1234',
  );

  final gracePeriodSubscription = activeSubscription.copyWith(
    status: SubscriptionStatus.gracePeriod,
  );

  final billingIssueSubscription = activeSubscription.copyWith(
    status: SubscriptionStatus.billingIssue,
  );

  setUp(() {
    mockAppBloc = MockAppBloc();
    mockNavigatorObserver = MockNavigatorObserver();
    registerFallbackValue(
      MaterialPageRoute<dynamic>(builder: (_) => const SizedBox()),
    );
  });

  Widget buildTestWidget(AppState appState) {
    when(() => mockAppBloc.state).thenReturn(appState);

    final router = GoRouter(
      initialLocation: '/account',
      observers: [mockNavigatorObserver],
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountPage(),
        ),
        GoRoute(
          path: '/settings',
          name: Routes.settingsName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/paywall',
          name: Routes.paywallName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/subscription-details',
          name: Routes.subscriptionDetailsName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/manage-followed-items',
          name: Routes.manageFollowedItemsName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/saved-headlines',
          name: Routes.accountSavedHeadlinesName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/notifications-center',
          name: Routes.notificationsCenterName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/account-linking',
          name: Routes.accountLinkingName,
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    return BlocProvider.value(
      value: mockAppBloc,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('AccountPage', () {
    testWidgets('renders user header for standard user', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
          ),
        ),
      );

      expect(find.text(standardUser.email), findsOneWidget);
      expect(find.text('Standard User'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Upgrade'), findsOneWidget);
    });

    testWidgets('renders user header for premium user without upgrade button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: premiumUser,
            userSubscription: activeSubscription,
          ),
        ),
      );

      expect(find.text(premiumUser.email), findsOneWidget);
      expect(find.text('Premium User'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Upgrade'), findsNothing);
    });

    testWidgets('does not show banner for active subscription', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: premiumUser,
            userSubscription: activeSubscription,
          ),
        ),
      );

      expect(find.byType(SubscriptionStatusBanner), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('shows banner for grace period subscription', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: premiumUser,
            userSubscription: gracePeriodSubscription,
          ),
        ),
      );

      expect(find.byType(SubscriptionStatusBanner), findsOneWidget);
      expect(find.textContaining('grace period'), findsOneWidget);
    });

    testWidgets('shows banner for billing issue subscription', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: premiumUser,
            userSubscription: billingIssueSubscription,
          ),
        ),
      );

      expect(find.byType(SubscriptionStatusBanner), findsOneWidget);
      expect(find.textContaining('billing issue'), findsOneWidget);
    });

    testWidgets('dispatches AppLogoutRequested on sign out tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      verify(() => mockAppBloc.add(const AppLogoutRequested())).called(1);
    });

    testWidgets('navigates to settings on settings icon tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      verify(
        () => mockNavigatorObserver.didPush(
          any(
            that: isA<Route<dynamic>>().having(
              (r) => r.settings.name,
              'name',
              Routes.settingsName,
            ),
          ),
          any(),
        ),
      ).called(1);
    });
  });
}
