import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/analytics_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:logging/logging.dart';

/// {@template analytics_engine}
/// The concrete implementation of [AnalyticsService].
///
/// This engine acts as a smart proxy that enforces configuration rules defined
/// in [AnalyticsConfig] (e.g., sampling, disabled events) before delegating
/// to the active [AnalyticsProviderInterface].
/// {@endtemplate}
class AnalyticsEngine implements AnalyticsService {
  /// {@macro analytics_engine}
  AnalyticsEngine({
    required AnalyticsConfig initialConfig,
    required Map<AnalyticsProvider, AnalyticsProviderInterface> providers,
    Logger? logger,
  }) : _config = initialConfig,
       _providers = providers,
       _logger = logger ?? Logger('AnalyticsEngine');

  AnalyticsConfig _config;
  final Map<AnalyticsProvider, AnalyticsProviderInterface> _providers;
  final Logger _logger;
  final Random _random = Random();

  @override
  Future<void> logEvent(
    AnalyticsEvent event, {
    AnalyticsEventPayload? payload,
  }) async {
    // 1. Check Global Enablement
    if (!_config.enabled) {
      return;
    }

    // 2. Check if Event is Disabled
    if (_config.disabledEvents.contains(event)) {
      _logger.fine('Event ${event.name} is disabled by remote config.');
      return;
    }

    // 3. Check Sampling Rate
    final samplingRate = _config.eventSamplingRates[event];
    if (samplingRate != null) {
      if (_random.nextDouble() > samplingRate) {
        _logger.fine('Event ${event.name} skipped due to sampling.');
        return;
      }
    }

    // 4. Delegate to Active Provider
    final activeProvider = _providers[_config.activeProvider];
    if (activeProvider != null) {
      await activeProvider.logEvent(
        name: event.name,
        parameters: payload?.toMap(),
      );
    } else {
      _logger.warning(
        'No provider found for active type: ${_config.activeProvider}',
      );
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!_config.enabled) return;
    final activeProvider = _providers[_config.activeProvider];
    await activeProvider?.setUserId(userId);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_config.enabled) return;
    final activeProvider = _providers[_config.activeProvider];
    await activeProvider?.setUserProperty(name: name, value: value);
  }

  @override
  void updateConfig(AnalyticsConfig config) {
    _logger.info('Updating Analytics Configuration.');
    _config = config;
  }
}
