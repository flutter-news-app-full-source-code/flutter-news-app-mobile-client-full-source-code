part of 'subscription_bloc.dart';

enum SubscriptionStatus {
  initial,
  loadingProducts,
  productsLoaded,
  purchasing,
  restoring,
  success,
  failure,
}

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.products = const [],
    this.selectedProduct,
    this.error,
  });

  final SubscriptionStatus status;
  final List<ProductDetails> products;
  final ProductDetails? selectedProduct;
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
    Object? error,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, products, selectedProduct, error];
}
