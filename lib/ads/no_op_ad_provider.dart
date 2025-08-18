import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template no_op_ad_provider}
/// A "no-operation" implementation of [AdProvider] for platforms where
/// native ad SDKs are not supported (e.g., web).
///
/// This provider's `initialize` method does nothing, and its `loadNativeAd`
/// method returns a [NativeAd] with [AdProviderType.placeholder]. This ensures
/// that the application's UI can still render an "ad slot" for visual
/// consistency in demo environments, without attempting to load actual native
/// ads that would cause platform exceptions.
/// {@endtemplate}
class NoOpAdProvider implements AdProvider {
  /// {@macro no_op_ad_provider}
  NoOpAdProvider({Logger? logger})
      : _logger = logger ?? Logger('NoOpAdProvider');

  final Logger _logger;
  final Uuid _uuid = const Uuid();

  /// This method does nothing as there's no SDK to initialize.
  ///
  /// It logs a message to indicate its no-op nature.
  @override
  Future<void> initialize() async {
    _logger.info('No-Op Ad Provider initialized (no actual SDK to init).');
  }

  /// Loads a placeholder native ad.
  ///
  /// This method does not interact with any external ad network. Instead, it
  /// creates a [NativeAd] object with [AdProviderType.placeholder], which
  /// signals to the UI that a generic placeholder should be rendered.
  ///
  /// The [imageStyle] and [adThemeStyle] parameters are accepted for API
  /// compatibility but are not used to load a real ad.
  @override
  Future<NativeAd?> loadNativeAd({
    required HeadlineImageStyle imageStyle,
    required AdThemeStyle adThemeStyle,
  }) async {
    _logger.info('Loading placeholder native ad.');
    // Return a dummy NativeAd object with a placeholder type.
    // The `adObject` can be any non-null object, as it won't be used by
    // the placeholder rendering widget.
    return NativeAd(
      id: _uuid.v4(),
      provider: AdProviderType.placeholder,
      adObject: Object(), // Dummy object
      templateType: switch (imageStyle) {
        HeadlineImageStyle.largeThumbnail => NativeAdTemplateType.medium,
        _ => NativeAdTemplateType.small,
      },
    );
  }
}
