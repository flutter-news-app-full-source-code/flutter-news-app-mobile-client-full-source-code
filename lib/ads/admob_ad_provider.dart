import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart'
    as app_native_ad;
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';

/// {@template admob_ad_provider}
/// A concrete implementation of [AdProvider] for Google AdMob.
///
/// This class handles the initialization of the Google Mobile Ads SDK
/// and the loading of native ads specifically for AdMob. It adapts the
/// AdMob-specific [admob.NativeAd] object into our generic [app_native_ad.NativeAd]
/// model.
/// {@endtemplate}
class AdMobAdProvider implements AdProvider {
  /// {@macro admob_ad_provider}
  AdMobAdProvider({Logger? logger})
    : _logger = logger ?? Logger('AdMobAdProvider');

  final Logger _logger;
  final Uuid _uuid = const Uuid();

  static const _nativeAdLoadTimeout = 15;

  /// The AdMob Native Ad Unit ID for Android.
  ///
  /// This should be replaced with your production Ad Unit ID.
  /// For testing, use `ca-app-pub-3940256099942544/2247696110`.
  static const String _androidNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  /// The AdMob Native Ad Unit ID for iOS.
  ///
  /// This should be replaced with your production Ad Unit ID.
  /// For testing, use `ca-app-pub-3940256099942544/3986624511`.
  static const String _iosNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  /// The AdMob Native Ad Unit ID for Web.
  ///
  /// AdMob does not officially support native ads on web. This is a placeholder.
  /// For testing, use `ca-app-pub-3940256099942544/2247696110` (Android test ID).
  static const String _webNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  /// Returns the appropriate native ad unit ID based on the platform.
  String get _nativeAdUnitId {
    if (kIsWeb) {
      return _webNativeAdUnitId;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidNativeAdUnitId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosNativeAdUnitId;
    }
    return ''; // Fallback for unsupported platforms
  }

  @override
  Future<void> initialize() async {
    _logger.info('Initializing Google Mobile Ads SDK...');
    try {
      await admob.MobileAds.instance.initialize();
      _logger.info('Google Mobile Ads SDK initialized successfully.');
    } catch (e) {
      _logger.severe('Failed to initialize Google Mobile Ads SDK: $e');
      // TODO(fulleni): Depending on requirements, you might want to rethrow or handle this more gracefully.
      // For now, we log and continue, as ad loading might still work in some cases.
    }
  }

  @override
  @override
  Future<app_native_ad.NativeAd?> loadNativeAd({
    required HeadlineImageStyle imageStyle,
    required ThemeData theme,
  }) async {
    if (_nativeAdUnitId.isEmpty) {
      _logger.warning('No native ad unit ID configured for this platform.');
      return null;
    }

    _logger.info('Attempting to load native ad from unit ID: $_nativeAdUnitId');

    final templateType = switch (imageStyle) {
      HeadlineImageStyle.largeThumbnail => admob.TemplateType.medium,
      _ => admob.TemplateType.small,
    };

    final completer = Completer<admob.NativeAd?>();

    final ad = admob.NativeAd(
      adUnitId: _nativeAdUnitId,
      request: const admob.AdRequest(),
      nativeTemplateStyle: _createNativeTemplateStyle(
        templateType: templateType,
        theme: theme,
      ),
      listener: admob.NativeAdListener(
        onAdLoaded: (ad) {
          _logger.info('Native Ad loaded successfully.');
          completer.complete(ad as admob.NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          _logger.severe('Native Ad failed to load: $error');
          ad.dispose();
          completer.complete(null);
        },
        onAdClicked: (ad) {
          _logger.info('Native Ad clicked.');
        },
        onAdImpression: (ad) {
          _logger.info('Native Ad impression recorded.');
        },
        onAdClosed: (ad) {
          _logger.info('Native Ad closed.');
          ad.dispose();
        },
        onAdOpened: (ad) {
          _logger.info('Native Ad opened.');
        },
        onAdWillDismissScreen: (ad) {
          _logger.info('Native Ad will dismiss screen.');
        },
      ),
    );

    try {
      await ad.load();
    } catch (e) {
      _logger.severe('Error during native ad load: $e');
      completer.complete(null);
    }

    // Add a timeout to the future to prevent hanging if callbacks are not called.
    final googleNativeAd = await completer.future.timeout(
      const Duration(seconds: _nativeAdLoadTimeout),
      onTimeout: () {
        _logger.warning('Native ad loading timed out.');
        ad.dispose(); // Dispose the ad if it timed out
        return null;
      },
    );

    if (googleNativeAd == null) {
      return null;
    }

    // Map the Google Mobile Ads NativeAd to our generic NativeAd model.
    return app_native_ad.NativeAd(
      id: _uuid.v4(), // Generate a unique ID for our internal model
      provider: app_native_ad.AdProviderType.admob, // Set the provider
      adObject: googleNativeAd, // Store the original AdMob object
    );
  }

  /// Creates a [NativeTemplateStyle] based on the app's current theme.
  ///
  /// This method maps the application's theme properties (colors, text styles)
  /// to the AdMob native ad styling options, ensuring a consistent look and feel.
  admob.NativeTemplateStyle _createNativeTemplateStyle({
    required admob.TemplateType templateType,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return admob.NativeTemplateStyle(
      templateType: templateType,
      mainBackgroundColor: colorScheme.surface,
      cornerRadius: AppSpacing.sm, // 8.0
      callToActionTextStyle: admob.NativeTemplateTextStyle(
        textColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        style: admob.NativeTemplateFontStyle.normal,
        size: textTheme.labelLarge?.fontSize,
      ),
      primaryTextStyle: admob.NativeTemplateTextStyle(
        textColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
        style: admob.NativeTemplateFontStyle.bold,
        size: textTheme.titleMedium?.fontSize,
      ),
      secondaryTextStyle: admob.NativeTemplateTextStyle(
        textColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        style: admob.NativeTemplateFontStyle.normal,
        size: textTheme.bodyMedium?.fontSize,
      ),
      tertiaryTextStyle: admob.NativeTemplateTextStyle(
        textColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        style: admob.NativeTemplateFontStyle.normal,
        size: textTheme.labelSmall?.fontSize,
      ),
    );
  }
}
