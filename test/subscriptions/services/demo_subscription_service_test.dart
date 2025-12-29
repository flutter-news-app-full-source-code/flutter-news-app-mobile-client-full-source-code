 import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/demo_subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  late DemoSubscriptionService service;
  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
    service = DemoSubscriptionService(logger: mockLogger);
  });

  final testProductDetails = ProductDetails(
    id: 'test_product',
    title: 'Test',
    description: 'Test Desc',
    price: '1.99',
    rawPrice: 1.99,
    currencyCode: 'USD',
  );

  group('DemoSubscriptionService', () {
    test('isAvailable always returns true', () async {
      expect(await service.isAvailable(), isTrue);
    });

    test('queryProductDetails returns mocked products', () async {
      final result = await service.queryProductDetails({'monthly_plan'});
      expect(result, isA<List<ProductDetails>>());
      expect(result.first.id, 'monthly_plan');
      expect(result.first.title, 'Monthly Premium (Demo)');
    });

    test('buyNonConsumable adds a purchased event to the stream', () async {
      await expectLater(
        service.purchaseStream,
        emits(
          isA<List<PurchaseDetails>>()
              .having(
                (list) => list.first.status,
                'status',
                PurchaseStatus.purchased,
              )
              .having(
                (list) => list.first.productID,
                'productID',
                testProductDetails.id,
              ),
        ),
      );

      await service.buyNonConsumable(product: testProductDetails);
    });

    test('restorePurchases adds a restored event to the stream', () async {
      await expectLater(
        service.purchaseStream,
        emits(
          isA<List<PurchaseDetails>>()
              .having(
                (list) => list.first.status,
                'status',
                PurchaseStatus.restored,
              )
              .having(
                (list) => list.first.productID,
                'productID',
                'demo_annual_plan',
              ),
        ),
      );

      await service.restorePurchases();
    });

    test('completePurchase completes without error', () async {
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
      );

      expect(service.completePurchase(purchase), completes);
    });
  });
}
