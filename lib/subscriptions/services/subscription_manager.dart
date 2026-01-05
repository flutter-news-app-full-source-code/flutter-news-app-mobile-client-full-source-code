import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/providers/subscription_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// {@template subscription_manager}
/// The "Brain" of the subscription feature.
///
/// It implements [SubscriptionService] and delegates operations to the
/// appropriate [SubscriptionProvider] based on the remote configuration.
/// {@endtemplate}
class SubscriptionManager implements SubscriptionService {
  /// {@macro subscription_manager}
  SubscriptionManager({
    required SubscriptionConfig? initialConfig,
    required SubscriptionProvider storeProvider,
    required SubscriptionProvider noOpProvider,
    required Logger logger,
  }) : _config = initialConfig,
       _storeProvider = storeProvider,
       _noOpProvider = noOpProvider,
       _logger = logger;

  // ignore: unused_field
  final SubscriptionConfig? _config;
  final SubscriptionProvider _storeProvider;
  final SubscriptionProvider _noOpProvider;
  final Logger _logger;

  /// Determines the active provider based on the configuration.
  SubscriptionProvider get _activeProvider {
    if (_config != null && _config.enabled) {
      return _storeProvider;
    }
    return _noOpProvider;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _activeProvider.purchaseStream;

  @override
  Future<bool> isAvailable() {
    return _activeProvider.isAvailable();
  }

  @override
  Future<List<ProductDetails>> queryProductDetails(Set<String> productIds) {
    return _activeProvider.queryProductDetails(productIds);
  }

  @override
  Future<void> buyNonConsumable({
    required ProductDetails product,
    String? applicationUserName,
    PurchaseDetails? oldPurchaseDetails,
  }) {
    if (_config == null || !_config.enabled) {
      _logger.warning(
        'Attempted to buyNonConsumable while subscriptions are disabled.',
      );
      return Future.value();
    }
    return _activeProvider.buyNonConsumable(
      product: product,
      applicationUserName: applicationUserName,
      oldPurchaseDetails: oldPurchaseDetails,
    );
  }

  @override
  Future<void> restorePurchases() {
    return _activeProvider.restorePurchases();
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _activeProvider.completePurchase(purchase);
  }
}
