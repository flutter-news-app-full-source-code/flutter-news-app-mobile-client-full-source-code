import 'dart:async';

import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';

/// {@template demo_subscription_service}
/// A pure Dart implementation of [SubscriptionServiceInterface] for demo/web.
///
/// It simulates store behavior using in-memory streams and local storage
/// to persist "purchased" state across app restarts, mimicking a real store's
/// restoration capability.
/// {@endtemplate}
class DemoSubscriptionService implements SubscriptionServiceInterface {
  /// {@macro demo_subscription_service}
  DemoSubscriptionService({
    required KVStorageService storageService,
    Logger? logger,
  }) : _storageService = storageService,
       _logger = logger ?? Logger('DemoSubscriptionService');

  final KVStorageService _storageService;
  final Logger _logger;
  final _purchaseStreamController =
      StreamController<List<PurchaseDetails>>.broadcast();

  static const _storageKey = 'demo_purchased_product_ids';

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseStreamController.stream;

  @override
  Future<bool> isAvailable() async {
    _logger.info('[DemoSubscriptionService] Store is available (simulated).');
    return true;
  }

  @override
  Future<List<ProductDetails>> queryProductDetails(
    Set<String> productIds,
  ) async {
    _logger.info(
      '[DemoSubscriptionService] Returning mock products for $productIds',
    );
    return productIds.map(_createMockProduct).toList();
  }

  @override
  Future<void> buyNonConsumable(ProductDetails product) async {
    _logger.info(
      '[DemoSubscriptionService] Simulating purchase for ${product.id}',
    );

    // Simulate network delay
    await Future<void>.delayed(const Duration(seconds: 1));

    final purchase = _createMockPurchase(product.id);

    // Persist the purchase to simulate "ownership"
    await _persistPurchase(product.id);

    _purchaseStreamController.add([purchase]);
  }

  @override
  Future<void> restorePurchases() async {
    _logger.info('[DemoSubscriptionService] Restoring simulated purchases...');
    
    // Simulate network delay
    await Future<void>.delayed(const Duration(seconds: 1));

    final purchasedIds = await _getPurchasedIds();
    if (purchasedIds.isEmpty) {
      _logger.info('[DemoSubscriptionService] No purchases to restore.');
      return;
    }

    final purchases = purchasedIds.map((id) {
      return _createMockPurchase(id, status: PurchaseStatus.restored);
    }).toList();

    _purchaseStreamController.add(purchases);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    _logger.fine(
      '[DemoSubscriptionService] Purchase ${purchase.purchaseID} completed.',
    );
  }

  ProductDetails _createMockProduct(String id) {
    return ProductDetails(
      id: id,
      title:
          id.contains('annual')
              ? 'Annual Premium (Demo)'
              : 'Monthly Premium (Demo)',
      description: 'Unlock all features (Demo Mode)',
      price: id.contains('annual') ? r'$99.99' : r'$9.99',
      rawPrice: id.contains('annual') ? 99.99 : 9.99,
      currencyCode: 'USD',
    );
  }

  PurchaseDetails _createMockPurchase(
    String productId, {
    PurchaseStatus status = PurchaseStatus.purchased,
  }) {
    return PurchaseDetails(
      purchaseID: 'demo_purchase_${DateTime.now().millisecondsSinceEpoch}',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'demo_local_data',
        serverVerificationData: 'demo_server_data',
        source: 'demo_source',
      ),
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      status: status,
    );
  }

  Future<List<String>> _getPurchasedIds() async {
    try {
      final jsonString = await _storageService.readString(key: _storageKey);
      if (jsonString == null) return [];
      // Simple comma-separated list for demo purposes
      return jsonString.split(',');
    } catch (e) {
      return [];
    }
  }

  Future<void> _persistPurchase(String productId) async {
    final currentIds = await _getPurchasedIds();
    if (!currentIds.contains(productId)) {
      final newIds = [...currentIds, productId];
      await _storageService.writeString(
        key: _storageKey,
        value: newIds.join(','),
      );
    }
  }
}
