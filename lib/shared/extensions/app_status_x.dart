import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';

/// Extension on [AppLifeCycleStatus] to provide a convenient way to check
/// for "running" states.
extension AppStatusX on AppLifeCycleStatus {
  /// Returns `true` if the app is in a state where the main UI should be
  /// interactive.
  bool get isRunning =>
      this == AppLifeCycleStatus.authenticated ||
      this == AppLifeCycleStatus.anonymous ||
      this == AppLifeCycleStatus.unauthenticated;
}
