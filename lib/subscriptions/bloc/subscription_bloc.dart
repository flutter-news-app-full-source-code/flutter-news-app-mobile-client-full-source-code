import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({
    required SubscriptionServiceInterface subscriptionService,
    required DataRepository<PurchaseTransaction> purchaseTransactionRepository,
    required AppBloc appBloc,
    required RemoteConfig remoteConfig,
    required Logger logger,
  }) : _subscriptionService = subscriptionService,
       _purchaseTransactionRepository = purchaseTransactionRepository,
       _appBloc = appBloc,
       _remoteConfig = remoteConfig,
       _logger = logger,
       super(const SubscriptionState()) {
    on<SubscriptionStarted>(_onStarted);
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

  final SubscriptionServiceInterface _subscriptionService;
  final DataRepository<PurchaseTransaction> _purchaseTransactionRepository;
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

  Future<void> _onPurchaseRequested(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.purchasing));
    try {
      await _subscriptionService.buyNonConsumable(event.product);
      // The result will come through the stream listener (_onPurchaseUpdated)
    } catch (e, s) {
      _logger.severe('Failed to initiate purchase', e, s);
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
    }
  }

  Future<void> _onRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.restoring));
    try {
      await _subscriptionService.restorePurchases();
      // Results come via stream. If no purchases found, stream might not emit,
      // so we might need a timeout or UI feedback handled by the view.
    } catch (e, s) {
      _logger.severe('Failed to restore purchases', e, s);
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
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
        _logger.warning('Purchase error: ${purchase.error}');
        emit(
          state.copyWith(
            status: SubscriptionStatus.failure,
            error: purchase.error,
          ),
        );
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          // Validate with backend using the generic DataRepository.
          // We map the PurchaseDetails to a PurchaseTransaction DTO here.
          final verificationData = purchase.verificationData;
          final source = verificationData.source;

          StoreProvider provider;
          if (source == 'app_store') {
            provider = StoreProvider.apple;
          } else if (source == 'google_play') {
            provider = StoreProvider.google;
          } else {
            // Fallback or unknown store.
            provider = StoreProvider.google;
          }

          final transaction = PurchaseTransaction(
            planId: purchase.productID,
            provider: provider,
            providerReceipt: verificationData.serverVerificationData,
          );

          await _purchaseTransactionRepository.create(item: transaction);

          // Complete the transaction in the store
          if (purchase.pendingCompletePurchase) {
            await _subscriptionService.completePurchase(purchase);
          }

          emit(state.copyWith(status: SubscriptionStatus.success));

          // Force a user refresh to update entitlements immediately.
          // The backend should have updated the user's tier upon successful
          // validation of the purchase transaction.
          final currentUser = _appBloc.state.user;
          if (currentUser != null) {
            _appBloc.add(AppUserChanged(currentUser));
          }
        } catch (e, s) {
          _logger.severe('Failed to validate purchase', e, s);
          emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
        }
      }
    }
  }
}
