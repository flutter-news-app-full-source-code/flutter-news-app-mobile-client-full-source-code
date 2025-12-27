import 'dart:async';
import 'dart:io';

import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:logging/logging.dart';

/// {@template store_subscription_service}
/// A concrete implementation of [SubscriptionServiceInterface] that wraps
/// [InAppPurchase] to handle real store interactions on mobile platforms.
/// {@endtemplate}
class StoreSubscriptionService implements SubscriptionServiceInterface {
  /// {@macro store_subscription_service}
  StoreSubscriptionService({InAppPurchase? inAppPurchase, Logger? logger})
    : _iap = inAppPurchase ?? InAppPurchase.instance,
      _logger = logger ?? Logger('StoreSubscriptionService');

  final InAppPurchase _iap;
  final Logger _logger;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() async {
    try {
      final available = await _iap.isAvailable();
      _logger.info('[StoreSubscriptionService] Store available: $available');
      return available;
    } catch (e, s) {
      _logger.severe(
        '[StoreSubscriptionService] Failed to check store availability',
        e,
        s,
      );
      return false;
    }
  }

  @override
  Future<List<ProductDetails>> queryProductDetails(
    Set<String> productIds,
  ) async {
    _logger.info('[StoreSubscriptionService] Querying products: $productIds');
    final response = await _iap.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      _logger.warning(
        '[StoreSubscriptionService] Products not found: ${response.notFoundIDs}',
      );
    }

    if (response.error != null) {
      _logger.severe(
        '[StoreSubscriptionService] Query failed: ${response.error}',
      );
      throw Exception('Store query failed: ${response.error!.message}');
    }

    return response.productDetails;
  }

  @override
  Future<void> buyNonConsumable({
    required ProductDetails product,
    String? applicationUserName,
    PurchaseDetails? oldPurchaseDetails,
  }) async {
    _logger.info(
      '[StoreSubscriptionService] Initiating purchase for ${product.id}',
    );

    late final PurchaseParam purchaseParam;

    // For Android, we must construct a specific parameter object for upgrades
    // or downgrades to handle proration correctly and avoid double-billing.
    if (Platform.isAndroid && oldPurchaseDetails != null) {
      _logger.info('Android subscription change detected. Applying proration.');
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: applicationUserName,
        changeSubscriptionParam: ChangeSubscriptionParam(
          oldPurchaseDetails: oldPurchaseDetails as GooglePlayPurchaseDetails,
          replacementMode: ReplacementMode.withTimeProration,
        ),
      );
    } else {
      // For iOS, upgrades/downgrades are handled automatically by the App Store.
      // For new Android subscriptions, we use the standard parameter.
      purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: applicationUserName,
      );
    }

    try {
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        _logger.warning(
          '[StoreSubscriptionService] Buy request failed to start.',
        );
        throw Exception('Could not initiate purchase.');
      }
    } catch (e, s) {
      _logger.severe('[StoreSubscriptionService] Buy exception', e, s);
      rethrow;
    }
  }

  @override
  Future<void> restorePurchases() async {
    _logger.info('[StoreSubscriptionService] Restoring purchases...');
    await _iap.restorePurchases();
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
      _logger.fine(
        '[StoreSubscriptionService] Purchase ${purchase.purchaseID} completed.',
      );
    }
  }
}
