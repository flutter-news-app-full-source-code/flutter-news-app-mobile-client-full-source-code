import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/analytics_provider.dart';
import 'package:logging/logging.dart';

/// {@template firebase_analytics_provider}
/// An implementation of [AnalyticsProvider] for Firebase Analytics.
/// {@endtemplate}
class FirebaseAnalyticsProvider extends AnalyticsProvider {
  /// {@macro firebase_analytics_provider}
  FirebaseAnalyticsProvider({
    required FirebaseAnalytics firebaseAnalytics,
    Logger? logger,
  }) : _firebaseAnalytics = firebaseAnalytics,
       _logger = logger ?? Logger('FirebaseAnalyticsProvider');

  final FirebaseAnalytics _firebaseAnalytics;
  final Logger _logger;

  @override
  Future<void> initialize() async {
    // Firebase Analytics is typically initialized via Firebase.initializeApp()
    // in main.dart, but we can set default properties here if needed.
    _logger.info('FirebaseAnalyticsProvider initialized.');
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Create a new map with the correct type for Firebase Analytics.
      // We must filter out null values because Firebase expects Map<String, Object>.
      final safeParameters = parameters != null
          ? Map<String, Object>.fromEntries(
              parameters.entries
                  .where((e) => e.value != null)
                  .map((e) => MapEntry(e.key, e.value! as Object)),
            )
          : null;
      await _firebaseAnalytics.logEvent(name: name, parameters: safeParameters);
    } catch (e, s) {
      _logger.warning('Failed to log event to Firebase: $name', e, s);
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _firebaseAnalytics.setUserId(id: userId);
    } catch (e, s) {
      _logger.warning('Failed to set user ID in Firebase.', e, s);
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _firebaseAnalytics.setUserProperty(name: name, value: value);
    } catch (e, s) {
      _logger.warning('Failed to set user property in Firebase: $name', e, s);
    }
  }
}
