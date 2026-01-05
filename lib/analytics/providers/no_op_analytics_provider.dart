import 'dart:async';

import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/analytics_provider.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [AnalyticsProvider].
///
/// This provider is used as a fallback or placeholder when no specific
/// analytics provider is active.
class NoOpAnalyticsProvider implements AnalyticsProvider {
  /// Creates an instance of [NoOpAnalyticsProvider].
  NoOpAnalyticsProvider({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing NoOpAnalyticsProvider.');
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    // No-op
  }

  @override
  Future<void> setUserId(String? userId) async {
    // No-op
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    // No-op
  }
}
