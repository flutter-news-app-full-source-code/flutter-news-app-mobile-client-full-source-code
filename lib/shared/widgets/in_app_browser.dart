import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// {@template in_app_browser}
/// A modal widget that displays a web page within the app using a custom
/// InAppWebView implementation.
///
/// This browser is presented modally and includes a custom app bar with a
/// close button, providing a consistent and controlled browsing experience.
/// {@endtemplate}
class InAppBrowser extends StatefulWidget {
  /// {@macro in_app_browser}
  const InAppBrowser({required this.url, super.key});

  /// The initial URL to load in the web view.
  final String url;

  /// A static method to show the browser as a modal dialog.
  static Future<void> show(BuildContext context, {required String url}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          InAppBrowser(url: url),
    );
  }

  @override
  State<InAppBrowser> createState() => _InAppBrowserState();
}

class _InAppBrowserState extends State<InAppBrowser> {
  double _progress = 0;

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
