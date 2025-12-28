import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// {@template demo_subscription_service}
/// A demo implementation of the [SubscriptionServiceInterface].
///
/// This service simulates subscription flows for use on platforms where native
/// in-app purchases are not available (like web) or for demonstration purposes.
///
/// It fakes product fetching and purchase requests, and pushes simulated
/// `PurchaseDetails` updates onto its stream to be processed by the
/// `PurchaseHandler`.
/// {@endtemplate}
class DemoSubscriptionService implements SubscriptionServiceInterface {
  /// {@macro demo_subscription_service}
  DemoSubscriptionService({required Logger logger}) : _logger = logger;

  final Logger _logger;
  final _purchaseStreamController =
      StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseStreamController.stream;

  @override
  Future<bool> isAvailable() {
    _logger.info('[DemoSubscriptionService] Store is available (simulated).');
    return Future.value(true);
  }

  @override
  Future<List<ProductDetails>> queryProductDetails(Set<String> productIds) {
    _logger.info(
      '[DemoSubscriptionService] Querying product details for: $productIds (simulated).',
    );
    final demoProducts = productIds.map((id) {
      final isMonthly = id.contains('monthly');
      return ProductDetails(
        id: id,
        title: isMonthly ? 'Monthly Premium (Demo)' : 'Annual Premium (Demo)',
        description: 'A demo subscription plan.',
        price: isMonthly ? r'$9.99' : r'$99.99',
        rawPrice: isMonthly ? 9.99 : 99.99,
        currencyCode: 'USD',
      );
    }).toList();
    return Future.value(demoProducts);
  }

  @override
  Future<void> buyNonConsumable({
    required ProductDetails product,
    String? applicationUserName,
    PurchaseDetails? oldPurchaseDetails,
  }) {
    _logger.info(
      '[DemoSubscriptionService] Initiating purchase for ${product.id} (simulated).',
    );
    // Simulate a successful purchase by pushing a new PurchaseDetails
    // object onto the stream. This will be caught by the PurchaseHandler,
    // which will then handle the entitlement logic.
    final purchaseDetails = PurchaseDetails(
      purchaseID: 'demo_purchase_${DateTime.now().millisecondsSinceEpoch}',
      productID: product.id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData:
            'demo_server_verification_${DateTime.now().millisecondsSinceEpoch}',
        source: defaultTargetPlatform == TargetPlatform.android
            ? 'google_play'
            : 'app_store',
      ),
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      status: PurchaseStatus.purchased,
    );
    _purchaseStreamController.add([purchaseDetails]);
    return Future.value();
  }

  @override
  Future<void> restorePurchases() {
    _logger.info('[DemoSubscriptionService] Restoring purchases (simulated).');
    // In a real scenario, this would query the store. Here, we can simulate
    // finding a previously purchased item if needed, or do nothing if we
    // assume the user has no prior purchases in the demo.
    // For this uscase, we'll simulate finding no purchases to restore.
    _purchaseStreamController.add([]);
    return Future.value();
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    _logger.info(
      '[DemoSubscriptionService] Completing purchase: ${purchase.purchaseID} (simulated).',
    );
    return Future.value();
  }
}
