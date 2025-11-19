import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_hot_restart_wrapper.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bootstrap.dart';

// Determine the current application environment from compile-time variables.
// Defaults to 'demo' if no environment is specified.
const appEnvironment = String.fromEnvironment('APP_ENVIRONMENT') == 'production'
    ? AppEnvironment.production
    : (String.fromEnvironment('APP_ENVIRONMENT') == 'development'
          ? AppEnvironment.development
          : AppEnvironment.demo);

void main() async {
  // Ensure Flutter widgets are initialized before any Firebase operations.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase services only on non-web platforms, as it's used
  // for push notifications which are not supported in the web demo.
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
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
