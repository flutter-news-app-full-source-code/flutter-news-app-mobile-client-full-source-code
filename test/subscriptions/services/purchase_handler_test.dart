import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/purchase_handler.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionService extends Mock
    implements SubscriptionServiceInterface {}

class MockPurchaseTransactionRepository extends Mock
    implements DataRepository<PurchaseTransaction> {}

class MockUserSubscriptionRepository extends Mock
    implements DataRepository<UserSubscription> {}

class MockUserRepository extends Mock implements DataRepository<User> {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLogger extends Mock implements Logger {}

void main() {
  late PurchaseHandler purchaseHandler;
  late MockSubscriptionService mockSubscriptionService;
  late MockPurchaseTransactionRepository mockPurchaseTransactionRepository;
  late MockUserSubscriptionRepository mockUserSubscriptionRepository;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;
  late MockLogger mockLogger;

  late StreamController<List<PurchaseDetails>> purchaseStreamController;

  setUp(() {
    mockSubscriptionService = MockSubscriptionService();
    mockPurchaseTransactionRepository = MockPurchaseTransactionRepository();
    mockUserSubscriptionRepository = MockUserSubscriptionRepository();
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();
    mockLogger = MockLogger();

    purchaseStreamController = StreamController<List<PurchaseDetails>>();
    when(
      () => mockSubscriptionService.purchaseStream,
    ).thenAnswer((_) => purchaseStreamController.stream);

    purchaseHandler = PurchaseHandler(
      subscriptionService: mockSubscriptionService,
      purchaseTransactionRepository: mockPurchaseTransactionRepository,
      userSubscriptionRepository: mockUserSubscriptionRepository,
      userRepository: mockUserRepository,
      authRepository: mockAuthRepository,
      logger: mockLogger,
    );

    registerFallbackValue(
      const PurchaseTransaction(
        planId: 'test_plan',
        provider: StoreProvider.google,
        providerReceipt: 'test_receipt',
      ),
    );
  });

  tearDown(() {
    purchaseStreamController.close();
    purchaseHandler.dispose();
  });

  group('PurchaseHandler', () {
    const testUserId = 'user_123';
    final testUser = User(
      id: testUserId,
      email: 'test@example.com',
      role: UserRole.user,
      tier: AccessTier.standard,
      createdAt: DateTime.now(),
    );

    final testPurchase = PurchaseDetails(
      purchaseID: 'purchase_1',
      productID: 'product_1',
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server_receipt',
        source: 'google_play',
      ),
      transactionDate: '1234567890',
      status: PurchaseStatus.purchased,
    );

    final testRestoredPurchase = PurchaseDetails(
      purchaseID: 'purchase_2',
      productID: 'product_1',
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server_receipt',
        source: 'app_store',
      ),
      transactionDate: '1234567890',
      status: PurchaseStatus.restored,
    );

    test('should listen to purchase stream on initialization', () {
      purchaseHandler.listen();
      verify(() => mockSubscriptionService.purchaseStream).called(1);
    });

    test(
      'should process "purchased" status: validate with backend and complete transaction',
      () async {
        // Arrange
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(
          () => mockPurchaseTransactionRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer(
          (_) async => const PurchaseTransaction(
            planId: 'product_1',
            provider: StoreProvider.google,
            providerReceipt: 'server_receipt',
          ),
        );
        when(
          () => mockSubscriptionService.completePurchase(any()),
        ).thenAnswer((_) async {});

        testPurchase.pendingCompletePurchase = true;

        // Act
        purchaseHandler.listen();
        purchaseStreamController.add([testPurchase]);

        // Assert
        await Future<void>.delayed(Duration.zero); // Wait for async stream

        // 1. Verify backend validation call
        verify(
          () => mockPurchaseTransactionRepository.create(
            item: any(
              named: 'item',
              that: isA<PurchaseTransaction>()
                  .having((t) => t.planId, 'planId', 'product_1')
                  .having((t) => t.provider, 'provider', StoreProvider.google)
                  .having(
                    (t) => t.providerReceipt,
                    'receipt',
                    'server_receipt',
                  ),
            ),
            userId: testUserId,
          ),
        ).called(1);

        // 2. Verify transaction completion
        verify(
          () => mockSubscriptionService.completePurchase(testPurchase),
        ).called(1);
      },
    );

    test(
      'should process "restored" status: validate with backend and complete transaction',
      () async {
        // Arrange
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(
          () => mockPurchaseTransactionRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer(
          (_) async => const PurchaseTransaction(
            planId: 'product_1',
            provider: StoreProvider.apple,
            providerReceipt: 'server_receipt',
          ),
        );
        when(
          () => mockSubscriptionService.completePurchase(any()),
        ).thenAnswer((_) async {});

        testRestoredPurchase.pendingCompletePurchase = true;

        // Act
        purchaseHandler.listen();
        purchaseStreamController.add([testRestoredPurchase]);

        // Assert
        await Future<void>.delayed(Duration.zero);

        // Verify backend validation call with Apple provider
        verify(
          () => mockPurchaseTransactionRepository.create(
            item: any(
              named: 'item',
              that: isA<PurchaseTransaction>().having(
                (t) => t.provider,
                'provider',
                StoreProvider.apple,
              ),
            ),
            userId: testUserId,
          ),
        ).called(1);

        verify(
          () => mockSubscriptionService.completePurchase(testRestoredPurchase),
        ).called(1);
      },
    );

    test(
      'should complete transaction even if backend validation fails',
      () async {
        // Arrange
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(
          () => mockPurchaseTransactionRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        ).thenThrow(Exception('Backend error'));
        when(
          () => mockSubscriptionService.completePurchase(any()),
        ).thenAnswer((_) async {});

        testPurchase.pendingCompletePurchase = true;

        // Act
        purchaseHandler.listen();
        purchaseStreamController.add([testPurchase]);

        // Assert
        await Future<void>.delayed(Duration.zero);

        // Should still try to complete purchase to unblock queue
        verify(
          () => mockSubscriptionService.completePurchase(testPurchase),
        ).called(1);
      },
    );

    test(
      'should handle "error" status by completing purchase if pending',
      () async {
        // Arrange
        final errorPurchase = PurchaseDetails(
          purchaseID: 'error_1',
          productID: 'product_1',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'google_play',
          ),
          transactionDate: '',
          status: PurchaseStatus.error,
        )..pendingCompletePurchase = true;

        when(
          () => mockSubscriptionService.completePurchase(any()),
        ).thenAnswer((_) async {});

        // Act
        purchaseHandler.listen();
        purchaseStreamController.add([errorPurchase]);

        // Assert
        await Future<void>.delayed(Duration.zero);
        verify(
          () => mockSubscriptionService.completePurchase(errorPurchase),
        ).called(1);
        verifyNever(
          () => mockPurchaseTransactionRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        );
      },
    );

    test('should not process purchase if no user is logged in', () async {
      // Arrange
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => null);

      // Act
      purchaseHandler.listen();
      purchaseStreamController.add([testPurchase]);

      // Assert
      await Future<void>.delayed(Duration.zero);
      verifyNever(
        () => mockPurchaseTransactionRepository.create(
          item: any(named: 'item'),
          userId: any(named: 'userId'),
        ),
      );
    });
  });
}
