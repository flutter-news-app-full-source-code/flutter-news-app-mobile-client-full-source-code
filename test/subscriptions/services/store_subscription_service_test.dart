import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/store_subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

class MockLogger extends Mock implements Logger {}

void main() {
  late StoreSubscriptionService service;
  late MockInAppPurchase mockIap;
  late MockLogger mockLogger;

  setUpAll(() {
    registerFallbackValue(
      PurchaseParam(
        productDetails: ProductDetails(
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
    mockIap = MockInAppPurchase();
    mockLogger = MockLogger();
    service = StoreSubscriptionService(
      inAppPurchase: mockIap,
      logger: mockLogger,
    );
  });

  final testProductDetails = ProductDetails(
    id: 'test_product',
    title: 'Test',
    description: 'Test Desc',
    price: '1.99',
    rawPrice: 1.99,
    currencyCode: 'USD',
  );

  group('StoreSubscriptionService', () {
    test('isAvailable returns true when IAP is available', () async {
      when(() => mockIap.isAvailable()).thenAnswer((_) async => true);
      final result = await service.isAvailable();
      expect(result, isTrue);
      verify(() => mockIap.isAvailable()).called(1);
    });

    test('isAvailable returns false when IAP is not available', () async {
      when(() => mockIap.isAvailable()).thenAnswer((_) async => false);
      final result = await service.isAvailable();
      expect(result, isFalse);
    });

    test('queryProductDetails returns products on success', () async {
      final response = ProductDetailsResponse(
        productDetails: [testProductDetails],
        notFoundIDs: [],
      );
      when(
        () => mockIap.queryProductDetails(any()),
      ).thenAnswer((_) async => response);

      final result = await service.queryProductDetails({'test_product'});
      expect(result, [testProductDetails]);
    });

    test('queryProductDetails throws on error', () async {
      final response = ProductDetailsResponse(
        productDetails: [],
        notFoundIDs: [],
        error: IAPError(source: 'test', code: '1', message: 'error'),
      );
      when(
        () => mockIap.queryProductDetails(any()),
      ).thenAnswer((_) async => response);

      expect(
        () => service.queryProductDetails({'test_product'}),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'buyNonConsumable calls buyNonConsumable with correct params',
      () async {
        when(
          () => mockIap.buyNonConsumable(
            purchaseParam: any(named: 'purchaseParam'),
          ),
        ).thenAnswer((_) async => true);

        await service.buyNonConsumable(product: testProductDetails);

        final captured =
            verify(
                  () => mockIap.buyNonConsumable(
                    purchaseParam: captureAny(named: 'purchaseParam'),
                  ),
                ).captured.first
                as PurchaseParam;

        expect(captured.productDetails, testProductDetails);
        expect(captured, isNot(isA<GooglePlayPurchaseParam>()));
      },
    );

    test('restorePurchases calls restorePurchases', () async {
      when(() => mockIap.restorePurchases()).thenAnswer((_) async {});
      await service.restorePurchases();
      verify(() => mockIap.restorePurchases()).called(1);
    });

    test('completePurchase calls completePurchase', () async {
      final purchase = PurchaseDetails(
        purchaseID: '1',
        productID: 'a',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: '',
        ),
        transactionDate: '',
        status: PurchaseStatus.purchased,
      )..pendingCompletePurchase = true;

      when(() => mockIap.completePurchase(any())).thenAnswer((_) async {});
      await service.completePurchase(purchase);
      verify(() => mockIap.completePurchase(purchase)).called(1);
    });
  });
}
