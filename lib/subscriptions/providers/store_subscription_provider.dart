import 'dart:async';
import 'dart:io';

import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/providers/subscription_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:logging/logging.dart';

/// {@template store_subscription_provider}
/// A concrete implementation of [SubscriptionProvider] that wraps
/// [InAppPurchase] to handle real store interactions on mobile platforms.
/// {@endtemplate}
class StoreSubscriptionProvider implements SubscriptionProvider {
  /// {@macro store_subscription_provider}
  StoreSubscriptionProvider({InAppPurchase? inAppPurchase, Logger? logger})
    : _iap = inAppPurchase ?? InAppPurchase.instance,
      _logger = logger ?? Logger('StoreSubscriptionProvider');

  final InAppPurchase _iap;
  final Logger _logger;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() async {
    try {
      final available = await _iap.isAvailable();
      _logger.info('[StoreSubscriptionProvider] Store available: $available');
      return available;
    } catch (e, s) {
      _logger.severe(
        '[StoreSubscriptionProvider] Failed to check store availability',
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
    _logger.info('[StoreSubscriptionProvider] Querying products: $productIds');
    final response = await _iap.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      _logger.warning(
        '[StoreSubscriptionProvider] Products not found: ${response.notFoundIDs}',
      );
    }

    if (response.error != null) {
      _logger.severe(
        '[StoreSubscriptionProvider] Query failed: ${response.error}',
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
      '[StoreSubscriptionProvider] Initiating purchase for ${product.id}',
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
          '[StoreSubscriptionProvider] Buy request failed to start.',
        );
        throw Exception('Could not initiate purchase.');
      }
    } catch (e, s) {
      _logger.severe('[StoreSubscriptionProvider] Buy exception', e, s);
      rethrow;
    }
  }

  @override
  Future<void> restorePurchases() async {
    _logger.info('[StoreSubscriptionProvider] Restoring purchases...');
    await _iap.restorePurchases();
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
      _logger.fine(
        '[StoreSubscriptionProvider] Purchase ${purchase.purchaseID} completed.',
      );
    }
  }
}
