import 'package:ht_main/app/config/config.dart';
import 'package:ht_main/bootstrap.dart';

// Define the current application environment here.
// Change this value to switch between environments for local development.
// production/development/demo
const currentEnvironment = AppEnvironment.demo;

void main() async {
  final appConfig = switch (currentEnvironment) {
    AppEnvironment.production => AppConfig.production(),
    AppEnvironment.development => AppConfig.development(),
    AppEnvironment.demo => AppConfig.demo(),
  };
  await bootstrap(appConfig);
}
