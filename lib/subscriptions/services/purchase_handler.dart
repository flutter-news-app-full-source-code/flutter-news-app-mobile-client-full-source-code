import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/demo_subscription_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service_interface.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// {@template purchase_handler}
/// A global handler for in-app purchase streams.
///
/// This class is responsible for listening to the [SubscriptionServiceInterface]
/// stream throughout the entire application lifecycle. It handles:
/// 1. Validating receipts with the backend (or faking it in demo).
/// 2. Completing transactions with the store.
/// 3. Notifying listeners when a purchase has been successfully processed.
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
    required AuthRepository authRepository,
    required Logger logger,
  }) : _subscriptionService = subscriptionService,
       _purchaseTransactionRepository = purchaseTransactionRepository,
       _userSubscriptionRepository = userSubscriptionRepository,
       _userRepository = userRepository,
       _authRepository = authRepository,
       _logger = logger;

  final SubscriptionServiceInterface _subscriptionService;
  final DataRepository<PurchaseTransaction> _purchaseTransactionRepository;
  final DataRepository<UserSubscription> _userSubscriptionRepository;
  final DataRepository<User> _userRepository;
  final AuthRepository _authRepository;
  final Logger _logger;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseCompletedController = StreamController<void>.broadcast();

  /// A stream that emits an event when a purchase has been successfully
  /// verified and processed.
  ///
  /// The `AppBloc` listens to this stream to know when to refresh the
  /// user's entitlements.
  Stream<void> get purchaseCompleted => _purchaseCompletedController.stream;

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
    _purchaseCompletedController.close();
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
        // It's important to complete the transaction even if it's an error
        // to clear it from the queue.
        if (purchase.pendingCompletePurchase) {
          await _subscriptionService.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    _logger.info(
      '[PurchaseHandler] Processing purchase: ${purchase.purchaseID}, '
      'Status: ${purchase.status}',
    );

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        _logger.warning(
          '[PurchaseHandler] No user logged in. Cannot process purchase.',
        );
        return;
      }

      // In demo mode, we simulate the backend's validation process.
      if (_subscriptionService is DemoSubscriptionService) {
        _logger.info('[PurchaseHandler] Handling demo purchase...');
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

        // Update or create the subscription in the in-memory repo.
        await _userSubscriptionRepository.update(
          id: newSubscription.id,
          item: newSubscription,
          userId: currentUser.id,
        );

        // Update the user's tier in the in-memory repo.
        final updatedUser = currentUser.copyWith(tier: AccessTier.premium);
        await _userRepository.update(
          id: updatedUser.id,
          item: updatedUser,
          userId: updatedUser.id,
        );
      } else {
        // For real stores, send receipt to backend for zero-trust validation.
        _logger.info(
          '[PurchaseHandler] Sending purchase for backend validation...',
        );
        final verificationData = purchase.verificationData;
        final transaction = PurchaseTransaction(
          planId: purchase.productID,
          provider: verificationData.source == 'app_store'
              ? StoreProvider.apple
              : StoreProvider.google,
          providerReceipt: verificationData.serverVerificationData,
        );
        // The backend will validate this and update the user's entitlements.
        await _purchaseTransactionRepository.create(
          item: transaction,
          userId: currentUser.id,
        );
      }

      // Mark the purchase as complete with the respective store.
      // This is crucial to prevent the purchase from being processed again.
      if (purchase.pendingCompletePurchase) {
        await _subscriptionService.completePurchase(purchase);
        _logger.info(
          '[PurchaseHandler] Purchase ${purchase.purchaseID} completed with store.',
        );
      }

      // Notify listeners (i.e., AppBloc) that entitlements have changed.
      _purchaseCompletedController.add(null);
      _logger.info(
        '[PurchaseHandler] Notified listeners of purchase completion.',
      );
    } catch (e, s) {
      _logger.severe('[PurchaseHandler] Failed to process purchase', e, s);
    }
  }
}
