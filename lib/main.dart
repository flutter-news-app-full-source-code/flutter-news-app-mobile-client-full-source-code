import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_hot_restart_wrapper.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bootstrap.dart';

// Determine the current application environment from compile-time variables.
// Defaults to 'development' if no environment is specified.
const appEnvironment = String.fromEnvironment('APP_ENVIRONMENT') == 'production'
    ? AppEnvironment.production
    : AppEnvironment.development;

Future<void> main() async {
  final appConfig = switch (appEnvironment) {
    AppEnvironment.production => AppConfig.production(),
    AppEnvironment.development => AppConfig.development(),
  };

  // Ensure Flutter widgets are initialized before any Firebase operations.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp();

  final appWidget = await bootstrap(appConfig, appEnvironment);

  // The AppHotRestartWrapper is used at the root to enable a full application
  // restart via the "Retry" button on critical error pages.
  runApp(AppHotRestartWrapper(child: appWidget));
}
