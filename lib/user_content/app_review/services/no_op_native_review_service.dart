import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/native_review_service.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [NativeReviewService].
///
/// This service is used when the app review feature is disabled in the remote
/// configuration. It prevents any interaction with the platform's native review API.
class NoOpNativeReviewService implements NativeReviewService {
  /// Creates an instance of [NoOpNativeReviewService].
  NoOpNativeReviewService({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Future<bool> requestReview() async {
    _logger.fine('NoOpNativeReviewService: requestReview called. Ignoring.');
    return false;
  }
}
