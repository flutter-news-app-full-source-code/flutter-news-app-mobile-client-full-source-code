import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/analytics_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:logging/logging.dart';

/// {@template analytics_manager}
/// The concrete implementation of [AnalyticsService].
///
/// This manager acts as a smart proxy that enforces configuration rules defined
/// in [AnalyticsConfig] (e.g., sampling, disabled events) before delegating
/// to the active [AnalyticsProvider].
/// {@endtemplate}
class AnalyticsManager implements AnalyticsService {
  /// {@macro analytics_manager}
  AnalyticsManager({
    required AnalyticsConfig? initialConfig,
    required Map<AnalyticsProviders, AnalyticsProvider> providers,
    required AnalyticsProvider noOpProvider,
    Logger? logger,
  }) : _config = initialConfig,
       _providers = providers,
       _noOpProvider = noOpProvider,
       _logger = logger ?? Logger('AnalyticsManager');

  AnalyticsConfig? _config;
  final Map<AnalyticsProviders, AnalyticsProvider> _providers;
  final AnalyticsProvider _noOpProvider;
  final Logger _logger;
  final Random _random = Random();

  AnalyticsProvider get _activeProvider {
    if (_config == null || !_config!.enabled) return _noOpProvider;
    return _providers[_config!.activeProvider] ?? _noOpProvider;
  }

  @override
  Future<void> initialize() async {
    _logger.info('AnalyticsManager: Initializing...');
    // Initialize all providers to ensure they are ready if switched to.
    await Future.wait(_providers.values.map((p) => p.initialize()));
    await _noOpProvider.initialize();
    _logger.info('AnalyticsManager: Initialized.');
  }

  @override
  Future<void> logEvent(
    AnalyticsEvent event, {
    AnalyticsEventPayload? payload,
  }) async {
    final config = _config;
    if (config == null || !config.enabled) {
      return;
    }

    // 1. Check if Event is Disabled
    if (config.disabledEvents.contains(event)) {
      _logger.fine('Event ${event.name} is disabled by remote config.');
      return;
    }

    // 2. Check Sampling Rate
    final samplingRate = config.eventSamplingRates[event];
    if (samplingRate != null) {
      if (_random.nextDouble() > samplingRate) {
        _logger.fine('Event ${event.name} skipped due to sampling.');
        return;
      }
    }

    // 3. Delegate to Active Provider
    await _activeProvider.logEvent(
      name: event.name,
      parameters: payload?.toMap(),
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    final config = _config;
    if (config == null || !config.enabled) return;

    await _activeProvider.setUserId(userId);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    final config = _config;
    if (config == null || !config.enabled) return;

    await _activeProvider.setUserProperty(name: name, value: value);
  }

  @override
  void updateConfig(AnalyticsConfig config) {
    _logger.info('Updating Analytics Configuration.');
    _config = config;
  }
}
