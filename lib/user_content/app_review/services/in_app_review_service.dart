import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/native_review_service.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:logging/logging.dart';


/// {@template in_app_review_service}
/// A concrete implementation of [NativeReviewService] that uses the
/// `in_app_review` package.
/// {@endtemplate}
class InAppReviewService implements NativeReviewService {
  /// {@macro in_app_review_service}
  InAppReviewService({required InAppReview inAppReview, Logger? logger})
    : _inAppReview = inAppReview,
      _logger = logger ?? Logger('InAppReviewService');

  final InAppReview _inAppReview;
  final Logger _logger;

  @override
  Future<bool> requestReview() async {
    if (await _inAppReview.isAvailable()) {
      _logger.info('Requesting native in-app review prompt.');
      await _inAppReview.requestReview();
      return true;
    }
    _logger.warning('Native in-app review is not available on this device.');
    return false;
  }
}
