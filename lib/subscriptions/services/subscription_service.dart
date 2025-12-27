import 'dart:async';

import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// {@template subscription_service}
/// A wrapper service around [InAppPurchase] to handle store interactions.
///
/// This service abstracts the complexity of the underlying IAP plugin and
/// provides a unified interface for:
/// 1.  Fetching product details (prices, descriptions) from the store.
/// 2.  Initiating purchase flows.
/// 3.  Listening to the global purchase stream (essential for handling
///     interrupted transactions).
///
/// It also includes a **Demo Mode** that simulates store behavior when
/// [AppEnvironment.demo] is active, allowing UI testing without real IAP.
/// {@endtemplate}
class SubscriptionService {
  /// {@macro subscription_service}
  SubscriptionService({
    required AppEnvironment environment,
    InAppPurchase? inAppPurchase,
    Logger? logger,
  }) : _environment = environment,
       _iap = inAppPurchase ?? InAppPurchase.instance,
       _logger = logger ?? Logger('SubscriptionService');

  final AppEnvironment _environment;
  final InAppPurchase _iap;
  final Logger _logger;

  /// Exposes the stream of purchase updates from the store.
  ///
  /// This stream MUST be listened to at app startup to handle pending
  /// transactions or purchases that completed while the app was backgrounded.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// Checks if the store is available on the current device.
  Future<bool> isAvailable() async {
    if (_environment == AppEnvironment.demo) {
      _logger.info('[SubscriptionService] Demo mode: Store is available.');
      return true;
    }
    try {
      final available = await _iap.isAvailable();
      _logger.info('[SubscriptionService] Store available: $available');
      return available;
    } catch (e, s) {
      _logger.severe(
        '[SubscriptionService] Failed to check store availability',
        e,
        s,
      );
      return false;
    }
  }

  /// Fetches product details for the given set of [productIds].
  Future<List<ProductDetails>> queryProductDetails(
    Set<String> productIds,
  ) async {
    if (_environment == AppEnvironment.demo) {
      _logger.info(
        '[SubscriptionService] Demo mode: Returning mock products for $productIds',
      );
      return productIds.map(_createMockProduct).toList();
    }

    _logger.info('[SubscriptionService] Querying products: $productIds');
    final response = await _iap.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      _logger.warning(
        '[SubscriptionService] Products not found: ${response.notFoundIDs}',
      );
    }

    if (response.error != null) {
      _logger.severe('[SubscriptionService] Query failed: ${response.error}');
      throw Exception('Store query failed: ${response.error!.message}');
    }

    return response.productDetails;
  }

  /// Initiates the purchase flow for a specific [product].
  ///
  /// This method returns immediately. The result of the purchase will be
  /// delivered via [purchaseStream].
  Future<void> buyNonConsumable(ProductDetails product) async {
    _logger.info('[SubscriptionService] Initiating purchase for ${product.id}');

    if (_environment == AppEnvironment.demo) {
      _logger.info(
        '[SubscriptionService] Demo mode: Simulating successful purchase.',
      );
      // In demo mode, the UI/Bloc will handle the "success" state manually
      // or we would need a mock stream controller. For this architecture,
      // we assume the Bloc handles the demo logic if needed, or we rely on
      // integration tests.
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        _logger.warning('[SubscriptionService] Buy request failed to start.');
        throw Exception('Could not initiate purchase.');
      }
    } catch (e, s) {
      _logger.severe('[SubscriptionService] Buy exception', e, s);
      rethrow;
    }
  }

  /// Restores previously purchased non-consumable items.
  ///
  /// This triggers the store to replay past transactions on the [purchaseStream].
  Future<void> restorePurchases() async {
    _logger.info('[SubscriptionService] Restoring purchases...');
    if (_environment == AppEnvironment.demo) {
      _logger.info('[SubscriptionService] Demo mode: Restore simulated.');
      return;
    }
    await _iap.restorePurchases();
  }

  /// Marks a transaction as complete.
  ///
  /// This is crucial for iOS to prevent the transaction from reappearing
  /// on the next app launch.
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (_environment == AppEnvironment.demo) return;
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
      _logger.fine(
        '[SubscriptionService] Purchase ${purchase.purchaseID} completed.',
      );
    }
  }

  /// Creates a mock product for demo mode.
  ProductDetails _createMockProduct(String id) {
    return ProductDetails(
      id: id,
      title: id.contains('annual')
          ? 'Annual Premium (Demo)'
          : 'Monthly Premium (Demo)',
      description: 'Unlock all features (Demo Mode)',
      price: id.contains('annual') ? r'$99.99' : r'$9.99',
      rawPrice: id.contains('annual') ? 99.99 : 9.99,
      currencyCode: 'USD',
    );
  }
}
