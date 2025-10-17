# Changelog

## 1.4.0 - Upcoming Release

- **feat**: overhauled search and account features with a new sliver-based feed UI, integrated search bar, and modal account sheet.
- **fix(demo)**: correct data migration logic for anonymous to authenticated user transitions
- **refactor**: improved filter page reset button to clear local selections and disable when not applicable
- **feat**: auto-scroll to active filter chip in SavedFiltersBar
- **fix**: resolve bug where applying a modified filter incorrectly selects the original saved filter
- **refactor**: relocated saved filters management to the account page and introduced reordering capability.
- **feat**: created a reusable, searchable multi-select page for filtering
- **feat**: add 'Followed' filter to quickly view content from followed items
- **feat(demo)**: pre-populate saved filters and settings for new anonymous users
- **fix**: ensure saved filters are immediately visible on app start
- **fix**: corrected a bug where selecting a source type would check all sources
- **feat**: implement saved feed filters with create, rename, and delete
- **feat**: add horizontal filter bar to the headlines feed for quick selection
- **refactor**: replace monolithic "apply followed items" with granular controls
- **refactor**: simplified filter logic by removing the ambiguous 'isUsingFollowedItems' flag
- **refactor**: improved the source filter UI by replacing horizontal scrolling with a more scalable and user-friendly vertical layout and navigation
- **refactor**:  Updated the Headline Details page with a fading scroll effect for metadata chips and a new style for the 'Continue Reading' button. The main feed's filter icon was removed from the AppBar in favor of the new filter bar.

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
