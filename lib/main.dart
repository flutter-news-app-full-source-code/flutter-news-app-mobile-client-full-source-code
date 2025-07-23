import 'dart:js_interop';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bootstrap.dart';

// Define the current application environment (production/development/demo).
const appEnvironment = AppEnvironment.demo;

@JS('removeSplashFromWeb')
external void removeSplashFromWeb();

void main() async {
  final appConfig = switch (appEnvironment) {
    AppEnvironment.production => AppConfig.production(),
    AppEnvironment.development => AppConfig.development(),
    AppEnvironment.demo => AppConfig.demo(),
  };

  final appWidget = await bootstrap(appConfig, appEnvironment);

  // Only remove the splash screen on web after the app is ready.
  if (kIsWeb) {
    removeSplashFromWeb();
  }

  if (appConfig.environment == AppEnvironment.demo) {
    runApp(
      DevicePreview(
        enabled: true,
        builder: (context) => appWidget,
        tools: const [DeviceSection()],
        backgroundColor: Colors.black87,
      ),
    );
  } else {
    runApp(appWidget);
  }
}
