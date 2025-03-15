# 📰 Headlines Toolkit

## 📖 Overview

**Headlines Toolkit** is a source-available, full-stack Flutter application designed to provide a foundation for building news apps. It offers a streamlined, user-friendly experience for browsing news headlines and is built with a clean, maintainable architecture. Developers can freely evaluate the source code and run the app locally for a 32-day trial period. A commercial license is required for any use beyond this trial, including continued local use, modification, production use, or distribution.

## ✨ Features

-   🗞️ **Headlines Feed:** Displays a minimalist list of news headlines (title only, with source, category, and country represented as icons).
-   📃 **Headline Details Page:** Provides detailed information about a headline (title, image, source, category, date, and a "Continue Reading" button that opens the original article in the browser).
-   🔎 **Search:** Allows users to search for headlines.
-   🗂️ **Filtering:** Allows users to filter headlines by category, source, and event country.
-   🌗 **Dark Mode:** Supports light and dark themes.
-   📅 **Planned Features:**
    -   👥 User accounts/profiles
    -   🌟 Personalized recommendations
    -   💾 Saving articles
    -   📵 Offline Reading
    -   🔔 Push notifications
    -   📰 News categories/topics
    -   🚀 Social sharing
    -   💬 Comments/discussion features

## 🛠️ Technical Overview

-   🎯 **Language:** Dart
-   💙 **Framework:** Flutter
-   🧱 **State Management:** BLoC
-   🔀 **Routing:** go_router
-   ⚙️ **Backend:** Firebase (current), Supabase (future)
-   🏛️ **Architecture:** Layered architecture (Data, Repository, Business Logic, Presentation)
-   💉 **Dependency Injection:** Manual
-   ⚖️ **Licensing:** Source-available under the PolyForm Free Trial License for evaluation. Commercial license required for production use, distribution, or continued use beyond 32 days.

## ⚖️ License

This project is source-available under the [PolyForm Free Trial License 1.0.0](LICENSE). This license allows for free evaluation of the Headlines Toolkit source code and local execution of the application for up to 32 consecutive days. Any use beyond this trial period, including continued local use, modification, production use, or distribution, requires a commercial license.

## 💰 Commercial License

A commercial license covers all repositories within the Headlines Toolkit organization, including the backend and any related packages. This provides licensees with a complete, full-stack solution for building their news applications. The commercial license grants developers the rights to use the source code in production, customize it to their needs, and distribute their derived applications.

## 🚀 Getting Started

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/headlines-toolkit/ht-main
    ```
2.  **Navigate to the project directory:**

    ```bash
    cd ht-main
    ```
3.  **Get dependencies:**

    ```bash
    flutter pub get
    ```
4.  **Run the app (development flavor):**

    ```bash
    flutter run -t lib/main_development.dart
    ```

    This will run the app using the in-memory data client.

## 🗂️ Project Structure

The project is organized using a feature-based directory structure within the `lib` folder:

```
lib/
├── app/          # Main application widget, app-level BLoCs, and views
├── headlines-feed/ # Headlines feed feature
├── headlines-search/ # Headlines search feature
├── l10n/         # Localization files
├── router/       # Routing configuration
└── shared/       # Reusable widgets and utilities
```
