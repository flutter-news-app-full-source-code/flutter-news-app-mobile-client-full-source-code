import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide SubscriptionStatus;
import 'package:core/core.dart' as core show SubscriptionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/bloc/subscription_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/view/subscription_details_page.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late SubscriptionBloc mockSubscriptionBloc;
  late AppBloc mockAppBloc;
  late SubscriptionServiceInterface mockSubscriptionService;
  late Logger mockLogger;

  final testSubscription = UserSubscription(
    id: 'sub1',
    userId: 'user1',
    tier: AccessTier.premium,
    status: core.SubscriptionStatus.active,
    provider: StoreProvider.google,
    validUntil: DateTime.now().add(const Duration(days: 30)),
    willAutoRenew: true,
    originalTransactionId: 'gpa.1234-5678',
  );

  final testMonthlyProduct = ProductDetails(
    id: 'monthly_plan_id',
    title: 'Monthly',
    description: 'desc',
    price: r'$9.99',
    rawPrice: 9.99,
    currencyCode: 'USD',
  );

  final testAnnualProduct = ProductDetails(
    id: 'annual_plan_id',
    title: 'Annual',
    description: 'desc',
    price: r'$99.99',
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
  });

  setUp(() {
    mockSubscriptionBloc = MockSubscriptionBloc();
    mockAppBloc = MockAppBloc();
    mockSubscriptionService = MockSubscriptionService();
    mockLogger = MockLogger();

    when(() => mockAppBloc.state).thenReturn(
      AppState(
        status: AppLifeCycleStatus.authenticated,
        remoteConfig: mockRemoteConfig,
        userSubscription: testSubscription,
      ),
    );
  });

  Widget buildTestWidget() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: mockSubscriptionService),
        RepositoryProvider.value(value: mockLogger),
      ],
      child: BlocProvider.value(
        value: mockAppBloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: mockSubscriptionBloc,
            child: const SubscriptionDetailsView(),
          ),
        ),
      ),
    );
  }

  group('SubscriptionDetailsPage', () {
    testWidgets('renders subscription details correctly', (tester) async {
      when(
        () => mockSubscriptionBloc.state,
      ).thenReturn(const SubscriptionState());

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Current Plan'), findsOneWidget);
      expect(find.text('Premium User'), findsOneWidget);
      expect(find.textContaining('Renews on'), findsOneWidget);
      expect(find.text('Google Play Store'), findsOneWidget);
      expect(find.text('Manage in App Store'), findsOneWidget);
    });

    testWidgets('shows upgrade option and dispatches event on tap', (
      tester,
    ) async {
      final activePurchase = PurchaseDetails(
        purchaseID: 'pur1',
        productID: testMonthlyProduct.id,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'google_play',
        ),
        transactionDate: '',
        status: PurchaseStatus.purchased,
      );

      when(() => mockSubscriptionBloc.state).thenReturn(
        SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
          products: [testMonthlyProduct, testAnnualProduct],
          activePurchaseDetails: activePurchase,
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Upgrade Plan'), findsOneWidget);
      expect(find.text('Switch to an annual plan and save.'), findsOneWidget);

      await tester.tap(find.text('Switch Plan'));
      await tester.pump();

      verify(
        () => mockSubscriptionBloc.add(
          any(that: isA<SubscriptionPurchaseRequested>()),
        ),
      ).called(1);
    });
  });
}
