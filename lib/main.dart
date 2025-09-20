import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/env_config.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/splash_screen_remover/web_splash_remover.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bootstrap.dart';

void main() async {
  // Initialize the environment configuration from the .env file.
  // This must be called before accessing any environment variables.
  EnvConfig.init();

  final appWidget = await bootstrap();

  // Only remove the splash screen on web after the app is ready.
  if (kIsWeb) {
    removeSplashFromWeb();
  }

  // Enable DevicePreview only in the demo environment on the web.
  if (EnvConfig.appEnvironment == AppEnvironment.demo && kIsWeb) {
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
