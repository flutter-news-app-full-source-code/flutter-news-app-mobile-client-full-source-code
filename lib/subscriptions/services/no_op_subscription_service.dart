import 'dart:async';

import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [SubscriptionServiceInterface].
///
/// This service is used when subscriptions are disabled in the remote
/// configuration. It prevents any interaction with the underlying store SDKs.
class NoOpSubscriptionService implements SubscriptionServiceInterface {
  /// Creates an instance of [NoOpSubscriptionService].
  NoOpSubscriptionService({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async {
    _logger.info(
      'NoOpSubscriptionService: isAvailable called. Returning false.',
    );
    return false;
  }

  @override
  Future<List<ProductDetails>> queryProductDetails(
    Set<String> productIds,
  ) async {
    _logger.info(
      'NoOpSubscriptionService: queryProductDetails called. Returning empty list.',
    );
    return [];
  }

  @override
  Future<void> buyNonConsumable({
    required ProductDetails product,
    String? applicationUserName,
    PurchaseDetails? oldPurchaseDetails,
  }) async {
    _logger.info('NoOpSubscriptionService: buyNonConsumable called. Ignoring.');
  }

  @override
  Future<void> restorePurchases() async {
    _logger.info('NoOpSubscriptionService: restorePurchases called. Ignoring.');
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    _logger.info('NoOpSubscriptionService: completePurchase called. Ignoring.');
  }
}
