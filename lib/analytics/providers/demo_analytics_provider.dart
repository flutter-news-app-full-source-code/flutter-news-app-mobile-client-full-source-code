import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/analytics_provider.dart';
import 'package:logging/logging.dart';

/// {@template demo_analytics_provider}
/// A demonstration implementation of [AnalyticsProviderInterface] that logs events
/// to the console.
/// {@endtemplate}
class DemoAnalyticsProvider extends AnalyticsProviderInterface {
  /// {@macro demo_analytics_provider}
  DemoAnalyticsProvider({Logger? logger})
    : _logger = logger ?? Logger('DemoAnalyticsProvider');

  final Logger _logger;

  @override
  Future<void> initialize() async {
    _logger.info('DemoAnalyticsProvider initialized.');
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    _logger.info(
      'ANALYTICS EVENT: $name\n'
      'Payload: $parameters',
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    _logger.info('ANALYTICS USER ID SET: $userId');
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    _logger.info('ANALYTICS USER PROPERTY SET: $name = $value');
  }
}
