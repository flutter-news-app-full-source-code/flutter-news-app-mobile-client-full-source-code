# Changelog

## 1.3.0

- feat: enforce content following and bookmarking limits ([#145](link), [#159](link))
- feat: enforce mandatory app updates via remote configuration ([#134](link))
- refactor: separate authentication and account linking flows ([#142](link))
- refactor: use `flutter_native_splash` for web splash screen management ([#137](link))
- refactor: implement centralized logging for GoRouter navigation ([#143](link))
- fix: web splash screen remains visible indefinitely ([#136](link))
- fix: back button is unresponsive during authentication flow ([#144](link))
- fix: ensure proper redirection after successful authentication ([#148](link))
- fix: content limitation bottom sheet overflows on small screens ([#149](link))
- chore(deps): update bloc, go_router, and other key dependencies ([#135](link))
- docs: clarify feed display settings in README ([#150](link))
  
## 1.2.1

-   **Fix:** Resolved an issue where the web splash screen would not disappear after the application loaded due to an incorrect bootstrap script in `index.html`.

## 1.2.0

-   **Refactor:** Updated `flutter_launcher_icons` configurations.
-   **Refactor:** Updated `flutter_native_splash` configurations.
-   **Dependency Update:** Bumped `bloc` to `^9.0.1`.
-   **Dependency Update:** Bumped `flutter_bloc` to `^9.1.1`.
-   **Dependency Update:** Bumped `go_router` to `^16.2.4`.
-   **Dependency Update:** Bumped `google_fonts` to `^6.3.2`.
-   **Dependency Update:** Bumped `share_plus` to `^11.1.0`.
-   **Dependency Update:** Bumped `very_good_analysis` to `^10.0.0`.
-   **Metadata Update:** Updated `homepage` and `documentation` URLs.
-   **Metadata Update:** Added `funding` link.
-   **Metadata Update:** Added `flutter` and `flutter-full-app` to `topics`.
-   **Metadata Update:** Added `screenshots` configuration.

## 1.1.0

-   **Feature:** Implemented app version enforcement based on remote configuration, including a dedicated `UpdateRequiredPage` to guide users to update.
-   **Enhancement:** Integrated `package_info_plus` and `pub_semver` for accurate version retrieval and comparison across platforms (Android, iOS, Web).

## 1.0.1

-   **Version Control:** Transitioned from date-based versioning to semantic versioning. This release marks the first version following the semantic versioning standard.
