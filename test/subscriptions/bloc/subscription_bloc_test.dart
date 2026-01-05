import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' hide SubscriptionStatus;
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/bloc/subscription_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionService extends Mock
    implements SubscriptionService {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockLogger extends Mock implements Logger {}

class MockPurchaseDetails extends Mock implements PurchaseDetails {}

void main() {
  late SubscriptionBloc subscriptionBloc;
  late MockSubscriptionService mockSubscriptionService;
  late MockAppBloc mockAppBloc;
  late MockLogger mockLogger;
  late RemoteConfig mockRemoteConfig;
  late StreamController<List<PurchaseDetails>> purchaseStreamController;

  final testMonthlyProduct = ProductDetails(
    id: 'monthly_plan',
    title: 'Monthly',
    description: 'desc',
    price: r'$9.99',
    rawPrice: 9.99,
    currencyCode: 'USD',
  );

  final testAnnualProduct = ProductDetails(
    id: 'annual_plan',
    title: 'Annual',
    description: 'desc',
    price: '.99',
    rawPrice: 99.99,
    currencyCode: 'USD',
  );

  setUp(() {
    mockSubscriptionService = MockSubscriptionService();
    mockAppBloc = MockAppBloc();
    mockLogger = MockLogger();
    purchaseStreamController =
        StreamController<List<PurchaseDetails>>.broadcast();

    mockRemoteConfig = RemoteConfig(
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
        general: GeneralAppConfig(termsOfServiceUrl: '', privacyPolicyUrl: ''),
      ),
      features: FeaturesConfig(
        analytics: const AnalyticsConfig(
          enabled: true,
          activeProvider: AnalyticsProviders.firebase,
          disabledEvents: {},
          eventSamplingRates: {},
        ),
        ads: const AdConfig(
          enabled: false,
          primaryAdPlatform: AdPlatformType.admob,
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
          primaryProvider: PushNotificationProviders.firebase,
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

    when(
      () => mockSubscriptionService.purchaseStream,
    ).thenAnswer((_) => purchaseStreamController.stream);

    subscriptionBloc = SubscriptionBloc(
      subscriptionService: mockSubscriptionService,
      appBloc: mockAppBloc,
      remoteConfig: mockRemoteConfig,
      logger: mockLogger,
    );
  });

  setUpAll(() {
    registerFallbackValue(
      ProductDetails(
        id: 'id',
        title: 'title',
        description: 'description',
        price: 'price',
        rawPrice: 0,
        currencyCode: 'USD',
      ),
    );
  });

  tearDown(() {
    purchaseStreamController.close();
    subscriptionBloc.close();
  });

  group('SubscriptionBloc', () {
    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [loading, loaded] when SubscriptionStarted is successful',
      setUp: () {
        when(
          () => mockSubscriptionService.isAvailable(),
        ).thenAnswer((_) async => true);
        when(
          () => mockSubscriptionService.queryProductDetails(any()),
        ).thenAnswer((_) async => [testMonthlyProduct, testAnnualProduct]);
      },
      build: () => subscriptionBloc,
      act: (bloc) => bloc.add(const SubscriptionStarted()),
      expect: () => [
        const SubscriptionState(status: SubscriptionStatus.loadingProducts),
        SubscriptionState(
          status: SubscriptionStatus.productsLoaded,
          products: [testMonthlyProduct, testAnnualProduct],
          selectedProduct: testAnnualProduct, // Annual is recommended
        ),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [failure] when store is not available',
      setUp: () {
        when(
          () => mockSubscriptionService.isAvailable(),
        ).thenAnswer((_) async => false);
      },
      build: () => subscriptionBloc,
      act: (bloc) => bloc.add(const SubscriptionStarted()),
      expect: () => [
        const SubscriptionState(status: SubscriptionStatus.loadingProducts),
        isA<SubscriptionState>()
            .having((s) => s.status, 'status', SubscriptionStatus.failure)
            .having((s) => s.error, 'error', 'Store not available'),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [failure] when querying products fails',
      setUp: () {
        when(
          () => mockSubscriptionService.isAvailable(),
        ).thenAnswer((_) async => true);
        when(
          () => mockSubscriptionService.queryProductDetails(any()),
        ).thenThrow(Exception('Query failed'));
      },
      build: () => subscriptionBloc,
      act: (bloc) => bloc.add(const SubscriptionStarted()),
      expect: () => [
        const SubscriptionState(status: SubscriptionStatus.loadingProducts),
        isA<SubscriptionState>()
            .having((s) => s.status, 'status', SubscriptionStatus.failure)
            .having((s) => s.error, 'error', isA<Exception>()),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits new state with selectedProduct on SubscriptionPlanSelected',
      build: () => subscriptionBloc,
      act: (bloc) => bloc.add(SubscriptionPlanSelected(testMonthlyProduct)),
      expect: () => [SubscriptionState(selectedProduct: testMonthlyProduct)],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [purchasing] and calls buyNonConsumable on SubscriptionPurchaseRequested',
      setUp: () {
        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: User(
              id: 'user1',
              email: 'a@b.com',
              role: UserRole.user,
              tier: AccessTier.standard,
              createdAt: DateTime.now(),
            ),
          ),
        );
        when(
          () => mockSubscriptionService.buyNonConsumable(
            product: any(named: 'product'),
            applicationUserName: any(named: 'applicationUserName'),
          ),
        ).thenAnswer((_) async {
          return;
        });
      },
      build: () => subscriptionBloc,
      act: (bloc) =>
          bloc.add(SubscriptionPurchaseRequested(product: testMonthlyProduct)),
      expect: () => <SubscriptionState>[
        const SubscriptionState(status: SubscriptionStatus.purchasing),
      ],
      verify: (_) {
        verify(
          () => mockSubscriptionService.buyNonConsumable(
            product: testMonthlyProduct,
            applicationUserName: 'user1',
          ),
        ).called(1);
      },
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [restoring] and calls restorePurchases on SubscriptionRestoreRequested',
      setUp: () {
        when(
          () => mockSubscriptionService.restorePurchases(),
        ).thenAnswer((_) async {
          return;
        });
      },
      build: () => subscriptionBloc,
      act: (bloc) => bloc.add(const SubscriptionRestoreRequested()),
      expect: () => [
        const SubscriptionState(status: SubscriptionStatus.restoring),
      ],
      verify: (_) {
        verify(() => mockSubscriptionService.restorePurchases()).called(1);
      },
    );

    group('SubscriptionPurchaseUpdated', () {
      final pendingPurchase = PurchaseDetails(
        purchaseID: '1',
        productID: 'a',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: '',
        ),
        transactionDate: '',
        status: PurchaseStatus.pending,
      );
      final purchased = PurchaseDetails(
        purchaseID: '1',
        productID: 'a',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: '',
        ),
        transactionDate: '',
        status: PurchaseStatus.purchased,
      );
      final restored = PurchaseDetails(
        purchaseID: '1',
        productID: 'a',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: '',
        ),
        transactionDate: '',
        status: PurchaseStatus.restored,
      );

      final errorPurchase = MockPurchaseDetails();
      when(() => errorPurchase.status).thenReturn(PurchaseStatus.error);
      when(
        () => errorPurchase.error,
      ).thenReturn(IAPError(source: 'test', code: '1', message: 'error'));

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emits [purchasing] on pending status',
        build: () => subscriptionBloc,
        act: (bloc) => purchaseStreamController.add([pendingPurchase]),
        expect: () => [
          const SubscriptionState(status: SubscriptionStatus.purchasing),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emits [success] on purchased status',
        build: () => subscriptionBloc,
        act: (bloc) => purchaseStreamController.add([purchased]),
        expect: () => [
          const SubscriptionState(status: SubscriptionStatus.success),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emits [restorationSuccess] on restored status',
        build: () => subscriptionBloc,
        act: (bloc) => purchaseStreamController.add([restored]),
        expect: () => [
          const SubscriptionState(
            status: SubscriptionStatus.restorationSuccess,
          ),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emits [failure] on error status',
        build: () => subscriptionBloc,
        act: (bloc) => purchaseStreamController.add([errorPurchase]),
        expect: () => [
          isA<SubscriptionState>()
              .having((s) => s.status, 'status', SubscriptionStatus.failure)
              .having((s) => s.error, 'error', isA<IAPError>()),
        ],
      );
    });
  });
}
