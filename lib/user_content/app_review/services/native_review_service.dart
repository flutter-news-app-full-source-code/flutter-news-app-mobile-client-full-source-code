/// {@template native_review_service}
/// An interface for handling native in-app review requests.
///
/// {@endtemplate}
abstract class NativeReviewService {
  /// Requests the native in-app review prompt.
  ///
  /// Returns `true` if the request was made successfully, `false` otherwise.
  /// This does not guarantee that the prompt was shown.
  Future<bool> requestReview();
}
