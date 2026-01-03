import 'dart:async';

import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/analytics_provider.dart';
import 'package:logging/logging.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// {@template mixpanel_analytics_provider}
/// An implementation of [AnalyticsProvider] for Mixpanel.
/// {@endtemplate}
class MixpanelAnalyticsProvider extends AnalyticsProvider {
  /// {@macro mixpanel_analytics_provider}
  MixpanelAnalyticsProvider({
    required String projectToken,
    required bool trackAutomaticEvents,
    Logger? logger,
  }) : _projectToken = projectToken,
       _trackAutomaticEvents = trackAutomaticEvents,
       _logger = logger ?? Logger('MixpanelAnalyticsProvider');

  final String _projectToken;
  final bool _trackAutomaticEvents;
  final Logger _logger;
  Mixpanel? _mixpanel;

  @override
  Future<void> initialize() async {
    try {
      _mixpanel = await Mixpanel.init(
        _projectToken,
        trackAutomaticEvents: _trackAutomaticEvents,
      );
      _logger.info('Mixpanel initialized successfully.');
    } catch (e, s) {
      _logger.severe('Failed to initialize Mixpanel.', e, s);
    }
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (_mixpanel == null) return;
    try {
      unawaited(_mixpanel!.track(name, properties: parameters));
    } catch (e, s) {
      _logger.warning('Failed to log event to Mixpanel: $name', e, s);
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (_mixpanel == null) return;
    try {
      if (userId == null) {
        unawaited(_mixpanel!.reset());
      } else {
        unawaited(_mixpanel!.identify(userId));
      }
    } catch (e, s) {
      _logger.warning('Failed to set user ID in Mixpanel.', e, s);
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (_mixpanel == null) return;
    try {
      _mixpanel!.getPeople().set(name, value);
    } catch (e, s) {
      _logger.warning('Failed to set user property in Mixpanel: $name', e, s);
    }
  }
}
