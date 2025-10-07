import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class GoRouterObserver extends NavigatorObserver {
  GoRouterObserver({required this.logger});

  final Logger logger;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.info(
      'Pushed: ${route.settings.name} | from: ${previousRoute?.settings.name}',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.info(
      'Popped: ${route.settings.name} | to: ${previousRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.info(
      'Removed: ${route.settings.name} | previous: ${previousRoute?.settings.name}',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    logger.info(
      'Replaced: ${oldRoute?.settings.name} | with: ${newRoute?.settings.name}',
    );
  }
}
