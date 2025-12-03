import 'package:in_app_review/in_app_review.dart';
import 'package:logging/logging.dart';

/// {@template native_review_service}
/// An interface for handling native in-app review requests.
///
/// This abstraction allows for different implementations, such as a real one
/// using the `in_app_review` package and a no-op one for testing or
/// unsupported platforms.
/// {@endtemplate}
abstract class NativeReviewService {
  /// Requests the native in-app review prompt.
  ///
  /// Returns `true` if the request was made successfully, `false` otherwise.
  /// This does not guarantee that the prompt was shown.
  Future<bool> requestReview();
}

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
