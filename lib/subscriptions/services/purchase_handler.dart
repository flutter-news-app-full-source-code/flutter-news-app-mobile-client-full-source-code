import 'dart:async';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/demo_subscription_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// {@template purchase_handler}
/// A global handler for in-app purchase streams.
///
/// This class is responsible for listening to the [SubscriptionServiceInterface]
/// stream throughout the entire application lifecycle. It handles:
/// 1. Validating receipts with the backend (or simulating it in demo).
/// 2. Completing transactions with the store.
/// 3. Updating the global [AppBloc] upon successful purchase.
///
/// This ensures that purchases completing in the background (e.g., "Ask to Buy",
/// interrupted sessions) are processed correctly even if the Paywall UI is closed.
/// {@endtemplate}
class PurchaseHandler {
  /// {@macro purchase_handler}
  PurchaseHandler({
    required SubscriptionServiceInterface subscriptionService,
    required DataRepository<PurchaseTransaction> purchaseTransactionRepository,
    required DataRepository<UserSubscription> userSubscriptionRepository,
    required DataRepository<User> userRepository,
    required AppBloc appBloc,
    required Logger logger,
  }) : _subscriptionService = subscriptionService,
       _purchaseTransactionRepository = purchaseTransactionRepository,
       _userSubscriptionRepository = userSubscriptionRepository,
       _userRepository = userRepository,
       _appBloc = appBloc,
       _logger = logger;

  final SubscriptionServiceInterface _subscriptionService;
  final DataRepository<PurchaseTransaction> _purchaseTransactionRepository;
  final DataRepository<UserSubscription> _userSubscriptionRepository;
  final DataRepository<User> _userRepository;
  final AppBloc _appBloc;
  final Logger _logger;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Initializes the listener. Should be called at app startup.
  void listen() {
    _subscription = _subscriptionService.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        _logger.severe('[PurchaseHandler] Error in purchase stream', error);
      },
    );
    _logger.info('[PurchaseHandler] Listening for purchase updates...');
  }

  /// Disposes the listener.
  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _onPurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _handleSuccessfulPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        _logger.warning(
          '[PurchaseHandler] Purchase error: ${purchase.error?.message}',
        );
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    _logger.info(
      '[PurchaseHandler] Processing purchase: ${purchase.purchaseID}, Status: ${purchase.status}',
    );

    try {
      final currentUser = _appBloc.state.user;
      if (currentUser == null) return;

      // In demo mode, we manually update the user's subscription state.
      // In a real environment, this would be handled by the backend after
      // validating the receipt.
      if (_subscriptionService is DemoSubscriptionService) {
        final newSubscription = UserSubscription(
          id: 'sub_${currentUser.id}',
          userId: currentUser.id,
          tier: AccessTier.premium,
          status: SubscriptionStatus.active,
          provider: StoreProvider.google, // Demo provider
          validUntil: DateTime.now().add(const Duration(days: 30)),
          willAutoRenew: true,
          originalTransactionId: purchase.purchaseID ?? 'demo_id',
        );

        // Use update with a fallback to create for idempotency in demo.
        try {
          await _userSubscriptionRepository.update(
            id: newSubscription.id,
            item: newSubscription,
            userId: currentUser.id,
          );
        } catch (_) {
          await _userSubscriptionRepository.create(
            item: newSubscription,
            userId: currentUser.id,
          );
        }
      } else {
        // For real stores, send the receipt to the backend for validation.
        final verificationData = purchase.verificationData;
        final transaction = PurchaseTransaction(
          planId: purchase.productID,
          provider: verificationData.source == 'app_store'
              ? StoreProvider.apple
              : StoreProvider.google,
          providerReceipt: verificationData.serverVerificationData,
        );
        await _purchaseTransactionRepository.create(item: transaction);
      }

      // Mark the purchase as complete with the respective store.
      if (purchase.pendingCompletePurchase) {
        await _subscriptionService.completePurchase(purchase);
      }

      // Trigger a refresh of the user's profile to update entitlements.
      // We fetch the latest user data from the repository to ensure we have
      // the updated AccessTier assigned by the backend.
      final updatedUser = await _userRepository.read(
        id: currentUser.id,
        userId: currentUser.id,
      );
      _appBloc.add(AppUserChanged(updatedUser));

      // Explicitly fetch and update the subscription state.
      // This ensures that renewals or changes that don't affect the user's tier
      // (and thus might be skipped by AppUserChanged) are still reflected in the UI.
      final subscriptionResponse = await _userSubscriptionRepository.readAll(
        userId: currentUser.id,
        filter: {'status': 'active'},
      );
      _appBloc.add(
        AppSubscriptionChanged(subscriptionResponse.items.firstOrNull),
      );
    } catch (e, s) {
      _logger.severe('[PurchaseHandler] Failed to process purchase', e, s);
    }
  }
}
