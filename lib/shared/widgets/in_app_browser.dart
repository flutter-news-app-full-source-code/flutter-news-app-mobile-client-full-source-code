import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';

/// {@template in_app_browser}
/// A modal widget that displays a web page within the app using a custom
/// InAppWebView implementation.
///
/// This browser is presented modally and includes a custom app bar with a
/// close button, providing a consistent and controlled browsing experience.
///
/// It also tracks the "reading time" (duration the browser is open) and logs
/// it via the [AnalyticsService] when the browser is closed.
/// {@endtemplate}
class InAppBrowser extends StatefulWidget {
  /// {@macro in_app_browser}
  const InAppBrowser({required this.url, required this.contentId, super.key});

  /// The initial URL to load in the web view.
  final String url;

  /// The ID of the content being viewed, used for analytics tracking.
  final String contentId;

  /// A static method to show the browser as a modal dialog.
  static Future<void> show(
    BuildContext context, {
    required String url,
    required String contentId,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          InAppBrowser(url: url, contentId: contentId),
    );
  }

  @override
  State<InAppBrowser> createState() => _InAppBrowserState();
}

class _InAppBrowserState extends State<InAppBrowser> {
  double _progress = 0;
  late final DateTime _startTime;
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    // Capture the service reference early to ensure it's available in dispose.
    _analyticsService = context.read<AnalyticsService>();
  }

  @override
  void dispose() {
    _logReadingTime();
    super.dispose();
  }

  void _logReadingTime() {
    final duration = DateTime.now().difference(_startTime);
    // Only log if the user spent a meaningful amount of time (e.g., > 1 second)
    if (duration.inSeconds > 1) {
      // TODO(fulleni): log reading time for external browser also.
      _analyticsService.logEvent(
        AnalyticsEvent.contentReadingTime,
        payload: ContentReadingTimePayload(
          contentId: widget.contentId,
          durationInSeconds: duration.inSeconds,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          // Restrict navigation to the initial domain to keep the user focused.
          useShouldOverrideUrlLoading: true,
        ),
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          // Allow the initial URL to load, but cancel any subsequent navigations.
          return navigationAction.isForMainFrame
              ? NavigationActionPolicy.CANCEL
              : NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
