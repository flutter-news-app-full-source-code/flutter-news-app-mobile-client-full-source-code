# Changelog

## Upcoming Release

 - **refactor!**: Overhauled the application startup and authentication lifecycle to be robust and free of race conditions. This was a major architectural change that introduced a new `AppInitializationPage` and `AppInitializationBloc` to act as a "gatekeeper," ensuring all critical data is fetched *before* the main UI is built. This fixes a class of bugs related to indefinite loading screens, data migration on account linking, and inconsistent state during startup.

## 1.4.0 - 2025-10-17

- **feat**: overhauled search and account features with a new sliver-based feed UI, integrated search bar, and modal account sheet.
- **feat**: implemented an advanced feed filtering system with a quick-access filter bar, support for custom saved filters (create, rename, delete, reorder), and a dedicated "Followed" content view.
- **refactor**: enhanced the filter creation UI with a reusable multi-select component and a more scalable vertical layout for source selection.
- **fix(demo)**: corrected data migration for anonymous users and now pre-populate saved filters for a richer initial experience.

## 1.3.0 - 2025-10-10

- **feat**: enforce content following and bookmarking limits
- **feat**: enforce mandatory app updates via remote configuration
- **refactor**: separate authentication and account linking flows
- **refactor**: use `flutter_native_splash` for web splash screen management
- **refactor**: implement centralized logging for GoRouter navigation
- **fix**: web splash screen remains visible indefinitely
- **fix**: back button is unresponsive during authentication flow
- **fix**: ensure proper redirection after successful authentication
- **fix**: content limitation bottom sheet overflows on small screens
- **chore(deps)**: update bloc, go_router, and other key dependencies
- **docs**: clarify feed display settings in README
  
## 1.2.1

- **fix**: resolved an issue where the web splash screen would not disappear after the application loaded due to an incorrect bootstrap script in `index.html`.

## 1.2.0

- **refactor**: updated `flutter_launcher_icons` configurations
- **refactor**: updated `flutter_native_splash` configurations
- **chore(deps)**: bumped `bloc` to `^9.0.1`
- **chore(deps)**: bumped `flutter_bloc` to `^9.1.1`
- **chore(deps)**: bumped `go_router` to `^16.2.4`
- **chore(deps)**: bumped `google_fonts` to `^6.3.2`
- **chore(deps)**: bumped `share_plus` to `^11.1.0`
- **chore(deps)**: bumped `very_good_analysis` to `^10.0.0`
- **docs**: updated `homepage` and `documentation` URLs
- **docs**: added `funding` link
- **docs**: added `flutter` and `flutter-full-app` to `topics`
- **docs**: added `screenshots` configuration

## 1.1.0

- **feat**: implemented app version enforcement based on remote configuration, including a dedicated `UpdateRequiredPage` to guide users to update
- **feat**: integrated `package_info_plus` and `pub_semver` for accurate version retrieval and comparison across platforms (Android, iOS, Web)

## 1.0.1

- **chore**: transitioned from date-based versioning to semantic versioning. This release marks the first version following the semantic versioning standard
