import 'dart:js_interop';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ht_main/app/config/config.dart';
import 'package:ht_main/bootstrap.dart';

// Define the current application environment here.
// Change this value to switch between environments for local development.
// production/development/demo
const currentEnvironment = AppEnvironment.demo;

@JS('removeSplashFromWeb')
external void removeSplashFromWeb();

void main() async {
  final appConfig = switch (currentEnvironment) {
    AppEnvironment.production => AppConfig.production(),
    AppEnvironment.development => AppConfig.development(),
    AppEnvironment.demo => AppConfig.demo(),
  };

  final appWidget = await bootstrap(appConfig, currentEnvironment);

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
