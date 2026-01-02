import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [AnalyticsService].
///
/// This service is used when analytics are disabled in the remote
/// configuration. It prevents any interaction with the underlying analytics SDKs.
class NoOpAnalyticsService implements AnalyticsService {
  /// Creates an instance of [NoOpAnalyticsService].
  NoOpAnalyticsService({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing NoOpAnalyticsService (Analytics disabled).');
  }

  @override
  Future<void> logEvent(
    AnalyticsEvent event, {
    AnalyticsEventPayload? payload,
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

  @override
  void updateConfig(AnalyticsConfig config) {
    _logger.info(
      'NoOpAnalyticsService received config update. '
      'Ignoring as service was disabled at startup.',
    );
  }
}
