import 'package:core/core.dart';

/// Extension on [UserFeedDecoratorStatus] to encapsulate the logic for
/// determining if a decorator can be shown.
extension UserFeedDecoratorStatusX on UserFeedDecoratorStatus {
  /// Determines if a decorator can be shown based on its completion status
  /// and the configured cooldown period.
  ///
  /// [daysBetweenViews]: The minimum number of days that must pass before the
  /// decorator can be shown again.
  ///
  /// Returns `true` if the decorator has never been shown, or if it has been
  /// shown but the cooldown period has elapsed. Returns `false` if the
  /// decorator action has been marked as completed or if it is still within
  /// its cooldown period.
  bool canBeShown({required int daysBetweenViews}) {
    if (isCompleted) {
      return false;
    }
    if (lastShownAt == null) {
      return true;
    }
    return DateTime.now().difference(lastShownAt!).inDays >= daysBetweenViews;
  }
}
