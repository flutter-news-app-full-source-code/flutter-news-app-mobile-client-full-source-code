import 'dart:async';

import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/providers/subscription_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [SubscriptionProvider].
///
/// This service is used when subscriptions are disabled in the remote
/// configuration. It prevents any interaction with the underlying store SDKs.
class NoOpSubscriptionProvider implements SubscriptionProvider {
  /// Creates an instance of [NoOpSubscriptionProvider].
  NoOpSubscriptionProvider({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async {
    _logger.info(
      'NoOpSubscriptionProvider: isAvailable called. Returning false.',
    );
    return false;
  }

  @override
  Future<List<ProductDetails>> queryProductDetails(
    Set<String> productIds,
  ) async {
    _logger.info(
      'NoOpSubscriptionProvider: queryProductDetails called. Returning empty list.',
    );
    return [];
  }

  @override
  Future<void> buyNonConsumable({
    required ProductDetails product,
    String? applicationUserName,
    PurchaseDetails? oldPurchaseDetails,
  }) async {
    _logger.info(
      'NoOpSubscriptionProvider: buyNonConsumable called. Ignoring.',
    );
  }

  @override
  Future<void> restorePurchases() async {
    _logger.info(
      'NoOpSubscriptionProvider: restorePurchases called. Ignoring.',
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    _logger.info(
      'NoOpSubscriptionProvider: completePurchase called. Ignoring.',
    );
  }
}
