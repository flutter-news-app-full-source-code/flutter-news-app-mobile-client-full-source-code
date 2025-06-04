import 'package:ht_main/app/config/config.dart' as app_config;
import 'package:ht_main/bootstrap.dart';

// Define the current application environment here.
// Change this value to switch between environments for local development.
const app_config.AppEnvironment currentEnvironment =
    app_config
        .AppEnvironment
        .developmentInMemory; // Or .developmentApi, or .production

void main() async {
  final appConfig = switch (currentEnvironment) {
    app_config.AppEnvironment.production => app_config.AppConfig.production(),
    app_config.AppEnvironment.developmentInMemory =>
      app_config.AppConfig.developmentInMemory(),
    app_config.AppEnvironment.developmentApi =>
      app_config.AppConfig.developmentApi(),
  };
  await bootstrap(appConfig);
}
