import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({
    required SubscriptionService subscriptionService,
    required AppBloc appBloc,
    required RemoteConfig remoteConfig,
    required Logger logger,
  }) : _subscriptionService = subscriptionService,
       _appBloc = appBloc,
       _remoteConfig = remoteConfig,
       _logger = logger,
       super(const SubscriptionState()) {
    on<SubscriptionStarted>(_onStarted);
    on<SubscriptionPlanSelected>(_onPlanSelected);
    on<SubscriptionPurchaseRequested>(_onPurchaseRequested);
    on<SubscriptionRestoreRequested>(_onRestoreRequested);
    on<_SubscriptionPurchaseUpdated>(_onPurchaseUpdated);

    // Listen to the global purchase stream from the service.
    _purchaseSubscription = _subscriptionService.purchaseStream.listen(
      (purchaseDetailsList) {
        add(
          _SubscriptionPurchaseUpdated(
            purchaseDetailsList: purchaseDetailsList,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.severe('Error in purchase stream', error, stackTrace);
        // We might want to emit a failure state here if appropriate
      },
    );
  }

  final SubscriptionService _subscriptionService;
  final AppBloc _appBloc;
  final RemoteConfig _remoteConfig;
  final Logger _logger;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  @override
  Future<void> close() {
    _purchaseSubscription.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    SubscriptionStarted event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.loadingProducts));

    try {
      final isAvailable = await _subscriptionService.isAvailable();
      if (!isAvailable) {
        emit(
          state.copyWith(
            status: SubscriptionStatus.failure,
            error: 'Store not available',
          ),
        );
        return;
      }

      final config = _remoteConfig.features.subscription;
      final productIds = <String>{};

      // Extract product IDs based on platform (logic simplified for brevity,
      // assumes we check platform or config provides correct IDs)
      // In a real app, we'd check Platform.isAndroid/iOS here or in the config object.
      // For now, we add both to be safe or rely on the service to filter.
      if (config.monthlyPlan.enabled) {
        if (config.monthlyPlan.appleProductId != null) {
          productIds.add(config.monthlyPlan.appleProductId!);
        }
        if (config.monthlyPlan.googleProductId != null) {
          productIds.add(config.monthlyPlan.googleProductId!);
        }
      }
      if (config.annualPlan.enabled) {
        if (config.annualPlan.appleProductId != null) {
          productIds.add(config.annualPlan.appleProductId!);
        }
        if (config.annualPlan.googleProductId != null) {
          productIds.add(config.annualPlan.googleProductId!);
        }
      }

      final products = await _subscriptionService.queryProductDetails(
        productIds,
      );

      // Pre-select the annual plan if recommended
      ProductDetails? selected;
      if (config.annualPlan.isRecommended) {
        selected = products.firstWhereOrNull(
          (p) =>
              p.id == config.annualPlan.appleProductId ||
              p.id == config.annualPlan.googleProductId,
        );
      }

      emit(
        state.copyWith(
          status: SubscriptionStatus.productsLoaded,
          products: products,
          selectedProduct: selected ?? products.firstOrNull,
        ),
      );
    } catch (e, s) {
      _logger.severe('Failed to load subscription products', e, s);
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
    }
  }

  void _onPlanSelected(
    SubscriptionPlanSelected event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(selectedProduct: event.product, clearError: true));
  }

  Future<void> _onPurchaseRequested(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(
      state.copyWith(status: SubscriptionStatus.purchasing, clearError: true),
    );
    try {
      final applicationUserName = _appBloc.state.user?.id;
      await _subscriptionService.buyNonConsumable(
        product: event.product,
        oldPurchaseDetails: event.oldPurchaseDetails,
        applicationUserName: applicationUserName,
      );
    } catch (e, s) {
      _logger.severe('Failed to initiate purchase', e, s);
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
    }
  }

  Future<void> _onRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(
      state.copyWith(status: SubscriptionStatus.restoring, clearError: true),
    );
    try {
      await _subscriptionService.restorePurchases();
      // The `_onPurchaseUpdated` method will handle the successful restoration
      // event from the stream. Here, we just need to indicate that the process
      // was initiated. If the stream doesn't emit a restored purchase, we
      // might need a timeout or a different mechanism to handle the case where
      // there's nothing to restore. For now, we rely on the stream.
    } catch (e, s) {
      _logger.severe('Failed to initiate restore', e, s);
      emit(
        state.copyWith(status: SubscriptionStatus.restorationFailure, error: e),
      );
    }
  }

  Future<void> _onPurchaseUpdated(
    _SubscriptionPurchaseUpdated event,
    Emitter<SubscriptionState> emit,
  ) async {
    for (final purchase in event.purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        emit(state.copyWith(status: SubscriptionStatus.purchasing));
      } else if (purchase.status == PurchaseStatus.error) {
        _logger.warning(
          '[SubscriptionBloc] Purchase error from stream: ${purchase.error}',
        );
        emit(
          state.copyWith(
            status: SubscriptionStatus.failure,
            error: purchase.error,
          ),
        );
      } else if (purchase.status == PurchaseStatus.purchased) {
        // Validation is handled by the global PurchaseHandler.
        // This BLoC only updates the UI to reflect a successful state for
        // new purchases, which triggers the success dialog and page pop.
        emit(state.copyWith(status: SubscriptionStatus.success));
      } else if (purchase.status == PurchaseStatus.restored) {
        // A restored purchase was successfully processed by the PurchaseHandler.
        // Update the UI to reflect a successful restoration.
        emit(state.copyWith(status: SubscriptionStatus.restorationSuccess));
      }
    }
  }
}
