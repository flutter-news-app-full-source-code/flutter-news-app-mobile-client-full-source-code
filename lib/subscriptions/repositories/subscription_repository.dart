import 'package:core/core.dart';
import 'package:data_client/data_client.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

/// {@template subscription_repository}
/// A repository that handles the business logic for subscription validation.
///
/// It acts as a bridge between the raw [PurchaseDetails] from the store
/// and the backend API. It converts the store receipt into a [PurchaseTransaction]
/// and sends it to the backend for cryptographic validation and entitlement granting.
/// {@endtemplate}
class SubscriptionRepository {
  /// {@macro subscription_repository}
  SubscriptionRepository({
    required DataClient<PurchaseTransaction> transactionClient,
    Logger? logger,
  }) : _transactionClient = transactionClient,
       _logger = logger ?? Logger('SubscriptionRepository');

  final DataClient<PurchaseTransaction> _transactionClient;
  final Logger _logger;

  /// Validates a purchase with the backend.
  ///
  /// This method:
  /// 1. Determines the [StoreProvider] (Apple/Google).
  /// 2. Extracts the verification data (receipt/token).
  /// 3. Sends a [PurchaseTransaction] to the backend.
  ///
  /// If successful, the backend will update the user's [AccessTier].
  /// The client should then refresh the user profile to reflect this change.
  Future<void> validatePurchase(PurchaseDetails purchase) async {
    _logger.info(
      '[SubscriptionRepository] Validating purchase: ${purchase.productID}',
    );

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

    try {
      await _transactionClient.create(item: transaction);
      _logger.info(
        '[SubscriptionRepository] Purchase validation request sent successfully.',
      );
    } catch (e, s) {
      _logger.severe('[SubscriptionRepository] Validation failed', e, s);
      throw OperationFailedException(
        'Failed to validate purchase with server: $e',
      );
    }
  }
}
