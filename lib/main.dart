import 'package:ht_main/app/config/config.dart' as app_config;
import 'package:ht_main/bootstrap.dart';

// Define the current application environment here.
// Change this value to switch between environments for local development.
const app_config.AppEnvironment currentEnvironment =
    app_config.AppEnvironment.development; // production/development/demo

void main() async {
  final appConfig = switch (currentEnvironment) {
    app_config.AppEnvironment.production => app_config.AppConfig.production(),
    app_config.AppEnvironment.demo => app_config.AppConfig.demo(),
    app_config.AppEnvironment.development => app_config.AppConfig.development(),
  };
  await bootstrap(appConfig);
}
