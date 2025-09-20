import 'package:dotenv/dotenv.dart';

/// Defines the different application environments.
enum AppEnvironment {
  /// Represents the production environment.
  production,

  /// Represents a development environment connecting to a local API.
  development,

  /// Represents a demonstration environment with in-memory data.
  demo,
}

/// {@template env_config}
/// A class to manage and provide environment-specific configurations.
///
/// This class loads configuration from a `.env` file at application startup
/// and provides type-safe access to environment variables. It is the single
/// source of truth for all environment-dependent values.
/// {@endtemplate}
class EnvConfig {
  /// {@macro env_config}
  const EnvConfig._();

  static final _env = DotEnv(includePlatformEnvironment: true);

  /// Initializes the environment configuration by loading the `.env` file.
  ///
  /// This method must be called once at application startup before accessing
  /// any environment variables.
  static void init() {
    _env.load(['.env']);
  }

  /// The base URL for the API, loaded from the `BASE_URL` variable.
  static String get baseUrl {
    return _env['BASE_URL'] ?? '';
  }

  /// The current application environment, parsed from the `APP_ENVIRONMENT`
  /// variable.
  ///
  /// Defaults to `AppEnvironment.demo` if the variable is missing or invalid.
  static AppEnvironment get appEnvironment {
    final env = _env['APP_ENVIRONMENT']?.toLowerCase();
    switch (env) {
      case 'production':
        return AppEnvironment.production;
      case 'development':
        return AppEnvironment.development;
      case 'demo':
      default:
        return AppEnvironment.demo;
    }
  }
}
