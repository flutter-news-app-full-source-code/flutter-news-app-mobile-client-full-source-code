import 'package:ht_main/app/config/config.dart' as app_config;
import 'package:ht_main/bootstrap.dart';

// Define the current application environment here.
// Change this value to switch between environments for local development.
// production/development/demo
const currentEnvironment = app_config.AppEnvironment.development;

void main() async {
  final appConfig = switch (currentEnvironment) {
    app_config.AppEnvironment.production => app_config.AppConfig.production(),
    app_config.AppEnvironment.development => app_config.AppConfig.development(),
    app_config.AppEnvironment.demo => app_config.AppConfig.demo(),
  };
  await bootstrap(appConfig);
}
