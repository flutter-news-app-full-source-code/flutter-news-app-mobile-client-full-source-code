part of 'subscription_bloc.dart';

enum SubscriptionStatus {
  initial,
  loadingProducts,
  productsLoaded,
  purchasing,
  restoring,
  success,
  failure,
  restorationSuccess,
  restorationFailure,
}

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.products = const [],
    this.selectedProduct,
    this.activePurchaseDetails,
    this.error,
  });

  final SubscriptionStatus status;
  final List<ProductDetails> products;
  final ProductDetails? selectedProduct;

  /// Holds the purchase details of the user's currently active subscription.
  /// This is populated by restoring purchases and is used for upgrades.
  final PurchaseDetails? activePurchaseDetails;

  final Object? error;

  /// Helper to get the monthly plan if available.
  ProductDetails? get monthlyPlan => products.firstWhereOrNull(
    (p) =>
        p.id.contains('monthly'), // Simple heuristic, refined by config later
  );

  /// Helper to get the annual plan if available.
  ProductDetails? get annualPlan =>
      products.firstWhereOrNull((p) => p.id.contains('annual'));

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<ProductDetails>? products,
    ProductDetails? selectedProduct,
    PurchaseDetails? activePurchaseDetails,
    Object? error,
    bool clearError = false,
    bool clearActivePurchase = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      activePurchaseDetails: clearActivePurchase
          ? null
          : activePurchaseDetails ?? this.activePurchaseDetails,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    selectedProduct,
    activePurchaseDetails,
    error,
  ];
}
