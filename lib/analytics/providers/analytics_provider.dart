/// {@template analytics_provider_interface}
/// Defines the contract for a specific analytics SDK adapter (e.g., Firebase, Mixpanel).
///
/// The [AnalyticsEngine] uses implementations of this interface to delegate
/// the actual data transmission.
/// {@endtemplate}
abstract class AnalyticsProviderInterface {
  /// {@macro analytics_provider_interface}
  const AnalyticsProviderInterface();

  /// Initializes the underlying analytics SDK.
  Future<void> initialize();

  /// Logs an event to the provider.
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  });

  /// Sets the user ID for the provider.
  Future<void> setUserId(String? userId);

  /// Sets a user property for the provider.
  Future<void> setUserProperty({required String name, required String value});
}
