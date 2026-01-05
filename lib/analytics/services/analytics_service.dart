import 'package:core/core.dart';

/// {@template analytics_service}
/// An abstract interface for logging analytics events.
///
/// This service acts as a facade for the underlying analytics provider(s),
/// enforcing configuration rules such as event filtering and sampling before
/// dispatching events.
/// {@endtemplate}
abstract class AnalyticsService {
  /// {@macro analytics_service}
  const AnalyticsService();

  /// Initializes the analytics service and its underlying providers.
  Future<void> initialize();

  /// Logs a standardized [AnalyticsEvent] with an optional strongly-typed
  /// [payload].
  ///
  /// Implementations must serialize the [payload] (if provided) to a Map
  /// and send it to the active analytics provider.
  Future<void> logEvent(AnalyticsEvent event, {AnalyticsEventPayload? payload});

  /// Sets the user ID for the analytics session.
  ///
  /// This should be called when a user logs in to associate subsequent events
  /// with that user. Passing `null` should clear the user identity (e.g., on logout).
  Future<void> setUserId(String? userId);

  /// Sets a user property for the analytics session.
  ///
  /// User properties are attributes used to describe segments of the user base,
  /// such as language preference, theme, or subscription status.
  Future<void> setUserProperty({required String name, required String value});

  /// Updates the analytics configuration at runtime.
  ///
  /// This allows the service to adapt to changes in remote configuration
  /// (e.g., enabling/disabling specific events) without requiring a restart.
  void updateConfig(AnalyticsConfig config);
}
