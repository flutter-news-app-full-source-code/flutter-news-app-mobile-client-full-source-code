import 'package:core/core.dart';

/// Extension on [User] to provide a convenient way to check
/// for "running" states.
extension AppUserX on User {
  /// Returns `true` if the user is a guest user.
  bool get isGuest => appRole == AppUserRole.guestUser;
}
