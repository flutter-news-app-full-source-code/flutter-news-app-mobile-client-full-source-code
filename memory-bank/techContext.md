# Tech Context

## Technologies

-   **Language:** Dart
-   **Framework:** Flutter
-   **State Management:** BLoC
-   **Dependency Injection:** Manual
-   **Routing:** GoRouter (for declarative routing and navigation)

## Development Setup

-   The project uses flavor-specific entry points (`main_development.dart`, `main_staging.dart`, `main_production.dart`).
-   Dependencies are managed using `pubspec.yaml`.

## Testing

- The project emphasizes thorough testing, aiming for 100% test coverage.
- Tests are run using `flutter test` or `dart test`, or `very_good test`.

## Theming

- The project uses Flutter's theming capabilities, including `ThemeData`, `ColorScheme`, `TextTheme`, and component themes, to ensure a consistent visual style.

## Dependencies
- The project depends on external packages, managed by pubspec.yaml

## Localization
- The project uses Flutter's built-in localization support.
- It utilizes the `flutter_localizations` and `intl` packages.
- Localization is configured via the `l10n.yaml` file.

## Layered Architecture
- The project follows a layered architecture with the following layers:
    - Data
    - Repository
    - Business Logic
    - Presentation
