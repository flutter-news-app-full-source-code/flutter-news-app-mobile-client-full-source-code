import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide SubscriptionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/bloc/subscription_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/view/paywall_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockSubscriptionBloc
    extends MockBloc<SubscriptionEvent, SubscriptionState>
    implements SubscriptionBloc {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockSubscriptionService extends Mock
    implements SubscriptionServiceInterface {}

class MockLogger extends Mock implements Logger {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late SubscriptionBloc mockSubscriptionBloc;
  late AppBloc mockAppBloc;
  late SubscriptionServiceInterface mockSubscriptionService;
  late Logger mockLogger;
  late MockNavigatorObserver mockNavigatorObserver;

  final testMonthlyProduct = ProductDetails(
    id: 'monthly_plan_id',
    title: 'Monthly Premium (Demo)',
    description: 'A demo subscription plan.',
    price: r'$9.99',
    rawPrice: 9.99,
    currencyCode: 'USD',
  );

  final testAnnualProduct = ProductDetails(
    id: 'annual_plan_id',
    title: 'Annual Premium (Demo)',
    description: 'A demo subscription plan.',
    price: '.99',
    rawPrice: 99.99,
    currencyCode: 'USD',
  );

  final mockRemoteConfig = RemoteConfig(
    id: 'config',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    app: const AppConfig(
      maintenance: MaintenanceConfig(isUnderMaintenance: false),
      update: UpdateConfig(
        latestAppVersion: '1.0.0',
        isLatestVersionOnly: false,
        iosUpdateUrl: '',
        androidUpdateUrl: '',
      ),
      general: GeneralAppConfig(
        termsOfServiceUrl: 'https://example.com/terms',
        privacyPolicyUrl: 'https://example.com/privacy',
      ),
    ),
    features: FeaturesConfig(
      analytics: const AnalyticsConfig(
        enabled: true,
        activeProvider: AnalyticsProvider.demo,
        disabledEvents: {},
        eventSamplingRates: {},
      ),
      ads: const AdConfig(
        enabled: false,
        primaryAdPlatform: AdPlatformType.demo,
        platformAdIdentifiers: {},
        feedAdConfiguration: FeedAdConfiguration(
          enabled: false,
          adType: AdType.native,
          visibleTo: {},
        ),
        navigationAdConfiguration: NavigationAdConfiguration(
          enabled: false,
          visibleTo: {},
        ),
      ),
      pushNotifications: const PushNotificationConfig(
        enabled: false,
        primaryProvider: PushNotificationProvider.firebase,
        deliveryConfigs: {},
      ),
      feed: const FeedConfig(
        itemClickBehavior: FeedItemClickBehavior.defaultBehavior,
        decorators: {},
      ),
      community: const CommunityConfig(
        enabled: true,
        engagement: EngagementConfig(
          enabled: true,
          engagementMode: EngagementMode.reactionsAndComments,
        ),
        reporting: ReportingConfig(
          enabled: true,
          headlineReportingEnabled: true,
          sourceReportingEnabled: true,
          commentReportingEnabled: true,
        ),
        appReview: AppReviewConfig(
          enabled: false,
          interactionCycleThreshold: 10,
          initialPromptCooldownDays: 30,
          eligiblePositiveInteractions: [],
          isNegativeFeedbackFollowUpEnabled: false,
          isPositiveFeedbackFollowUpEnabled: false,
        ),
      ),
      subscription: SubscriptionConfig(
        enabled: true,
        monthlyPlan: PlanDetails(
          enabled: true,
          isRecommended: false,
          googleProductId: testMonthlyProduct.id,
        ),
        annualPlan: PlanDetails(
          enabled: true,
          isRecommended: true,
          googleProductId: testAnnualProduct.id,
        ),
      ),
    ),
    user: const UserConfig(
      limits: UserLimitsConfig(
        followedItems: {},
        savedHeadlines: {},
        savedHeadlineFilters: {},
        savedSourceFilters: {},
        commentsPerDay: {},
        reactionsPerDay: {},
        reportsPerDay: {},
      ),
    ),
  );

  setUpAll(() {
    registerFallbackValue(
      SubscriptionPlanSelected(
        ProductDetails(
          id: '',
          title: '',
          description: '',
          price: '',
          rawPrice: 0,
          currencyCode: '',
        ),
      ),
    );
    registerFallbackValue(
      SubscriptionPurchaseRequested(
        product: ProductDetails(
          id: '',
          title: '',
          description: '',
          price: '',
          rawPrice: 0,
          currencyCode: '',
        ),
      ),
    );
    registerFallbackValue(const SubscriptionRestoreRequested());
  });

  setUp(() {
    mockSubscriptionBloc = MockSubscriptionBloc();
    mockAppBloc = MockAppBloc();
    mockSubscriptionService = MockSubscriptionService();
    mockLogger = MockLogger();
    mockNavigatorObserver = MockNavigatorObserver();
    registerFallbackValue(
      MaterialPageRoute<dynamic>(builder: (_) => const SizedBox()),
    );

    when(() => mockAppBloc.state).thenReturn(
      AppState(
        status: AppLifeCycleStatus.authenticated,
        remoteConfig: mockRemoteConfig,
        user: User(
          id: 'user-123',
          email: 'test@test.com',
          role: UserRole.user,
          tier: AccessTier.standard,
          createdAt: DateTime.now(),
        ),
      ),
    );

    when(
      () => mockSubscriptionBloc.state,
    ).thenReturn(const SubscriptionState());
  });

  Widget buildTestWidget() {
    final router = GoRouter(
      observers: [mockNavigatorObserver],
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/paywall'),
              child: const Text('Go to Paywall'),
            ),
          ),
        ),
        GoRoute(
          path: '/paywall',
          builder: (context, state) => BlocProvider.value(
            value: mockSubscriptionBloc,
            child: const PaywallView(),
          ),
        ),
      ],
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: mockSubscriptionService),
        RepositoryProvider.value(value: mockLogger),
      ],
      child: BlocProvider.value(
        value: mockAppBloc,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  group('PaywallPage', () {
    testWidgets('renders loading indicator when loading products', (
      tester,
    ) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable(<SubscriptionState>[]),
        initialState: const SubscriptionState(
          status: SubscriptionStatus.loadingProducts,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      // We can't use pumpAndSettle because the CircularProgressIndicator
      // creates an infinite animation. We pump once to build the frame
      // where the indicator is present, but offstage, and then find it
      // with `skipOffstage: false`.
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator, skipOffstage: false),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders plans when products are loaded', (tester) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable(<SubscriptionState>[]),
        initialState: SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
          products: [testMonthlyProduct, testAnnualProduct],
          selectedProduct: testAnnualProduct,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      await tester.pumpAndSettle();

      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Best Value'), findsOneWidget); // For annual plan
      expect(find.byType(ElevatedButton), findsOneWidget); // Subscribe button
    });

    testWidgets('renders error when no products are loaded', (tester) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable(<SubscriptionState>[]),
        initialState: const SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
          products: [],
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      await tester.pumpAndSettle();

      expect(find.text('An unknown error occurred.'), findsOneWidget);
    });

    testWidgets('renders localized demo plan titles correctly', (tester) async {
      final demoAnnualProduct = ProductDetails(
        id: 'annual_plan_id',
        title: 'demoAnnualPlanTitle', // This is the key
        description: 'desc',
        price: r'$99.99',
        rawPrice: 99.99,
        currencyCode: 'USD',
      );

      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable(<SubscriptionState>[]),
        initialState: SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
          products: [demoAnnualProduct],
          selectedProduct: demoAnnualProduct,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      await tester.pumpAndSettle();

      // The l10n key 'demoAnnualPlanTitle' resolves to 'Annual Premium (Demo)'.
      expect(find.text(r'$99.99'), findsOneWidget);
      expect(find.text('Annual Premium (Demo)'), findsOneWidget);
    });

    testWidgets('dispatches SubscriptionPlanSelected when a plan is tapped', (
      tester,
    ) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable(<SubscriptionState>[]),
        initialState: SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
          products: [testMonthlyProduct, testAnnualProduct],
          selectedProduct: testAnnualProduct, // Annual is selected initially
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      await tester.pumpAndSettle();

      // Tap the monthly plan
      await tester.scrollUntilVisible(find.text('Monthly'), 50);
      await tester.tap(find.text('Monthly'));
      await tester.pump();

      verify(
        () => mockSubscriptionBloc.add(
          any(that: isA<SubscriptionPlanSelected>()),
        ),
      ).called(1);
    });

    testWidgets(
      'dispatches SubscriptionPurchaseRequested when subscribe button is tapped',
      (tester) async {
        whenListen(
          mockSubscriptionBloc,
          Stream.fromIterable(<SubscriptionState>[]),
          initialState: SubscriptionState(
            status: SubscriptionStatus.productsLoaded,
            products: [testMonthlyProduct, testAnnualProduct],
            selectedProduct: testAnnualProduct,
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.tap(find.text('Go to Paywall'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        verify(
          () => mockSubscriptionBloc.add(
            any(that: isA<SubscriptionPurchaseRequested>()),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'dispatches SubscriptionRestoreRequested when restore button is tapped',
      (tester) async {
        whenListen(
          mockSubscriptionBloc,
          Stream.fromIterable(<SubscriptionState>[]),
          initialState: SubscriptionState(
            status: SubscriptionStatus.productsLoaded,
            products: [testMonthlyProduct, testAnnualProduct],
            selectedProduct: testAnnualProduct,
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.tap(find.text('Go to Paywall'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Restore Purchases'), 50);

        await tester.tap(find.text('Restore Purchases'));
        await tester.pump();

        verify(
          () => mockSubscriptionBloc.add(const SubscriptionRestoreRequested()),
        ).called(1);
      },
    );

    testWidgets('shows success dialog and pops on success state', (
      tester,
    ) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable([
          const SubscriptionState(status: SubscriptionStatus.productsLoaded),
          const SubscriptionState(status: SubscriptionStatus.success),
        ]),
        initialState: const SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
        ),
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: mockSubscriptionBloc,
          child: buildTestWidget(),
        ),
      );
      await tester.tap(find.text('Go to Paywall'));
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(); // Let the listener react

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Welcome to Premium!'), findsOneWidget);

      // Tap the "Got It" button
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();

      // Verify dialog is closed and page is popped
      expect(find.byType(AlertDialog), findsNothing);
      verify(() => mockNavigatorObserver.didPop(any(), any())).called(2);
    });

    testWidgets('shows error snackbar on failure state', (tester) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable([
          const SubscriptionState(status: SubscriptionStatus.productsLoaded),
          const SubscriptionState(
            status: SubscriptionStatus.failure,
            error: 'Test Error',
          ),
        ]),
        initialState: const SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      await tester.pumpAndSettle();

      await tester.pump(); // Let the listener react

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Purchase Failed: Test Error'),
        findsOneWidget,
      );
    });

    testWidgets('shows restoration success snackbar', (tester) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable([
          const SubscriptionState(
            status: SubscriptionStatus.restorationSuccess,
          ),
        ]),
        initialState: const SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      await tester.pump(); // Route transition
      await tester.pumpAndSettle(); // Listener and SnackBar animation

      expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
      expect(
        find.text('Your purchases have been successfully restored.'),
        findsOneWidget,
      );
    });

    testWidgets('shows restoration failure snackbar', (tester) async {
      whenListen(
        mockSubscriptionBloc,
        Stream.fromIterable([
          const SubscriptionState(
            status: SubscriptionStatus.restorationFailure,
          ),
        ]),
        initialState: const SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Go to Paywall'));
      await tester.pump(); // Route transition
      await tester.pumpAndSettle(); // Listener and SnackBar animation

      expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Could not restore purchases. Please try again or contact support.',
        ),
        findsOneWidget,
      );
    });
  });
}
