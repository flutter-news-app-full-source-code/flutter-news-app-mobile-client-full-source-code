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

/// Dispatched when the user taps a purchase button for a specific product.
class SubscriptionPurchaseRequested extends SubscriptionEvent {
  const SubscriptionPurchaseRequested({required this.product});

  final ProductDetails product;

  @override
  List<Object> get props => [product];
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
