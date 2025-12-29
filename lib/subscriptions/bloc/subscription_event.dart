part of 'subscription_bloc.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the subscription feature is initialized (e.g., Paywall opened).
/// Triggers fetching of available products from the store.
class SubscriptionStarted extends SubscriptionEvent {
  const SubscriptionStarted();
}

/// Dispatched when the user selects a product plan (e.g., Monthly vs Annual)
/// but hasn't confirmed the purchase yet.
class SubscriptionPlanSelected extends SubscriptionEvent {
  const SubscriptionPlanSelected(this.product);

  final ProductDetails product;

  @override
  List<Object?> get props => [product];
}

/// Dispatched when the user taps a purchase button for a specific product.
class SubscriptionPurchaseRequested extends SubscriptionEvent {
  const SubscriptionPurchaseRequested({
    required this.product,
    this.oldPurchaseDetails,
  });

  final ProductDetails product;

  /// The details of the currently active subscription, if any.
  /// This is required for subscription upgrades/downgrades on Android.
  final PurchaseDetails? oldPurchaseDetails;

  @override
  List<Object?> get props => [product, oldPurchaseDetails];
}

/// Dispatched when the user taps the "Restore Purchases" button.
class SubscriptionRestoreRequested extends SubscriptionEvent {
  const SubscriptionRestoreRequested();
}

/// Internal event: Dispatched when the [SubscriptionService] emits a new list
/// of purchase details (updates from the store).
class _SubscriptionPurchaseUpdated extends SubscriptionEvent {
  const _SubscriptionPurchaseUpdated({required this.purchaseDetailsList});

  final List<PurchaseDetails> purchaseDetailsList;

  @override
  List<Object> get props => [purchaseDetailsList];
}
