import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper class to convert a Stream to a Listenable for GoRouter.
///
/// Every time the "stream" receives an event, this [ChangeNotifier] notifies
/// its listeners, causing GoRouter to re-evaluate its routes and redirects
/// when used with `refreshListenable`.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream].
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Notify listeners immediately to ensure initial state is considered.
    // Although GoRouter likely handles initial state, this ensures consistency.
    notifyListeners();
    // Subscribe to the stream. Use asBroadcastStream to allow multiple
    // listeners if needed elsewhere, though typically only GoRouter
    // listens here.
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(), // Notify on every stream event
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  /// Cancels the stream subscription when this notifier is disposed.
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
