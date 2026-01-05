import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// {@template subscription_provider}
/// Defines the contract for the underlying subscription vendor implementation.
/// {@endtemplate}
abstract class SubscriptionProvider {
  /// Exposes the stream of purchase updates from the vendor.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Checks if the store is available on the current device.
  Future<bool> isAvailable();

  /// Fetches product details for the given set of [productIds].
  Future<List<ProductDetails>> queryProductDetails(Set<String> productIds);

  /// Initiates the purchase flow for a specific [product].
  Future<void> buyNonConsumable({
    required ProductDetails product,
    String? applicationUserName,
    PurchaseDetails? oldPurchaseDetails,
  });

  /// Restores previously purchased non-consumable items.
  Future<void> restorePurchases();

  /// Marks a transaction as complete.
  Future<void> completePurchase(PurchaseDetails purchase);
}
