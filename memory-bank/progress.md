# Progress

## What Works

-   Multiple environment configurations (development, staging, production) using `main_*.dart` files.
-   BLoC pattern implementation for state management:
    -   `AppBloc` for app-level state (navigation and theme).
    -   `HeadlinesFeedBloc` for managing headlines data, filtering, and fetching/refreshing.
    -   `HeadlinesSearchBloc` for managing headlines search.
-   Repository pattern for data access (`HtHeadlinesRepository`).
-   Initial Memory Bank setup.
-   Routing using `go_router`:
    -   Routes for headlines feed, search, and account.
    -   Nested route for article details within the headlines feed.
-   `headlines-feed` feature:
    -   `HeadlinesFeedBloc` for managing headlines data and filtering.
    -   `HeadlinesFeedPage` and `_HeadlinesFeedView` for displaying headlines.
    -   Filtering by category, source, and event country.
    -   Infinite scroll functionality.
    -   Refresh functionality.
-   `headlines-search` feature:
    -   `HeadlinesSearchBloc` for managing headlines search.
    -   `HeadlinesSearchPage` and `HeadlinesSearchView` for displaying search results.
    -   Debounced search term input.
    -   Uses shared widgets for initial, loading, and error states.
    -   Integrated search bar directly into the AppBar.
    -   Search button in the AppBar to trigger the search.
    -   Infinite scrolling.
-   Error handling within BLoCs, with specific error states.
-   Page/View pattern for UI components.

## What's Left to Build

-   Integration with the Firebase backend (currently using an in-memory client).
-   Implementation of remaining features:
    -   User accounts/profiles.
    -   Personalized recommendations.
    -   Saving articles.
    -   Offline reading.
    -   Push notifications.
    -   News categories/topics (beyond basic filtering).
    -   Social sharing.
    -   Comments/discussion features.
    -   Full implementation of the article details page (currently a placeholder).
-   Testing.
-   Future integration with Supabase.

## Current Status

-   Implementing remaining features and backend integration.

## Known Issues

-   None identified yet.
