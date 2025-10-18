import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_hot_restart_wrapper.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bootstrap.dart';

// Define the current application environment (production/development/demo).
const appEnvironment = AppEnvironment.demo;

void main() async {
  final appConfig = switch (appEnvironment) {
    AppEnvironment.production => AppConfig.production(),
    AppEnvironment.development => AppConfig.development(),
    AppEnvironment.demo => AppConfig.demo(),
  };

  final appWidget = await bootstrap(appConfig, appEnvironment);

  // The AppHotRestartWrapper is used at the root to enable a full application
  // restart via the "Retry" button on critical error pages.
  if (appConfig.environment == AppEnvironment.demo && kIsWeb) {
    runApp(
      AppHotRestartWrapper(
        child: DevicePreview(
          enabled: true,
          builder: (context) => appWidget,
          tools: const [DeviceSection()],
          backgroundColor: Colors.black87,
        ),
      ),
    );
  } else {
    runApp(AppHotRestartWrapper(child: appWidget));
  }
}
