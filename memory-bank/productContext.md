# Product Context

## Project Name

Headlines Toolkit

## Problem

Existing news apps for end-users can be cluttered, overwhelming, or lack personalization options. For developers, building a fully-featured news app from scratch is time-consuming and requires significant effort, especially when including a backend.

## Solution

Headlines Toolkit is a source-available Flutter application. Developers can freely view and evaluate the source code and run the app locally for a trial period of up to 32 consecutive days.  Any use beyond this trial period, including continued local use, modification, production use, or distribution, requires a commercial license. It provides a streamlined and user-friendly experience for browsing news headlines and is designed as a comprehensive, full-stack solution, saving developers time and effort in building their own news apps. The app leverages a clean UI, efficient data handling, and a layered architecture to deliver relevant information quickly. It currently uses a Firebase backend, with plans to add Supabase support in the future.

## Target Audience

Developers seeking a ready-made, customizable foundation for building their own news applications.

## Business Model

Commercial licenses are offered to developers, granting them the rights to use the Headlines Toolkit source code beyond the 32-day evaluation period, including for production use, customization, and distribution of derived applications. The source code is freely available for a 32-day evaluation, allowing developers to thoroughly test the software before purchasing a commercial license.

## App Features

-   **Headlines Feed:** Displays a minimalist list of news headlines, showing only the title, with source, category, and country represented as icons.
-   **Headline Details Page:** When a user taps a headline, they are taken to a details page that displays:
    -   Title
    -   Image
    -   Source
    -   Category
    -   Date
    -   "Continue Reading" button (opens the original source URL in the user's default browser)
-   **Search:** Allows users to search for specific headlines.
-   **Filtering:** Allows users to filter headlines by category, source, and event country.
-   **User Accounts/Profiles:** Functionality for user authentication and profile management.
-   **Personalized Recommendations:**  Provides personalized news recommendations based on user preferences and activity.
-   **Saving Articles:** Allows users to save articles for later reading.
-   **Offline Reading:**  Allows users to access saved articles even without an internet connection.
-   **Push Notifications:** Sends push notifications to users about breaking news or important updates.
-   **News Categories/Topics:**  Provides a wide range of news categories and topics beyond basic filtering.
-   **Social Sharing:**  Allows users to share articles on social media platforms.
-   **Comments/Discussion Features:**  Provides a platform for users to comment on and discuss articles.
-   **Dark Mode:** Offers a dark mode option for improved readability in low-light conditions.

## User Experience Goals

-   **Clarity:** Headlines and content should be presented in a clear and readable format.
-   **Efficiency:** The app should load quickly and respond smoothly to user interactions.
-   **Simplicity:** The interface should be intuitive and easy to navigate.

## How it Should Work

1.  The app fetches headlines from a data source (currently Firebase, with plans for Supabase).
2.  Headlines are displayed in a minimalist list in the feed.
3.  Users can tap on a headline to view the details page.
4.  Users can search and filter headlines.
5.  The app will support various features common to top news apps, as listed above.
