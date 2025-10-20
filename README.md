<div align="center">
  <img src="https://repository-images.githubusercontent.com/946589707/33b56f2c-76c3-4af0-a67f-8c08ca494b1b" alt="Flutter News App Toolkit Mockup" width="440">
  <h1>Flutter News App Mobile Client</h1>
  <p><strong>Complete, production-ready source code for a feature-rich Flutter news app mobile client.</strong></p>
</div>

<p align="center">
  <a href="https://flutter-news-app-full-source-code.github.io/flutter-news-app-mobile-client-full-source-code/"><img src="https://img.shields.io/badge/LIVE_DEMO-VIEW-orange?style=for-the-badge" alt="Live Demo: View"></a>
  <a href="https://flutter-news-app-full-source-code.github.io/docs/mobile-client/local-setup/"><img src="https://img.shields.io/badge/DOCUMENTATION-READ-slategray?style=for-the-badge" alt="Documentation: Read"></a>
  <img src="https://img.shields.io/badge/coverage-_%25-green?style=for-the-badge" alt="coverage: _%">
</p>
<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/TRIAL_LICENSE-VIEW_TERMS-blue?style=for-the-badge" alt="Trial License: View Terms"></a>
  <a href="https://github.com/sponsors/flutter-news-app-full-source-code"><img src="https://img.shields.io/badge/LIFETIME_LICENSE-PURCHASE-purple?style=for-the-badge" alt="Lifetime License: Purchase"></a>
</p>

This repository contains the complete, production-ready source code for a feature-rich Flutter news app mobile client. It gives you everything you need to launch your own news app on the App Store and Google Play, right out of the box. It is a key component of the [**Flutter News App Full Source Code Toolkit**](https://github.com/flutter-news-app-full-source-code), an ecosystem that also includes a Dart Frog [backend API](https://github.com/flutter-news-app-full-source-code/flutter-news-app-api-server-full-source-code) and a web-based [content management dashboard](https://github.com/flutter-news-app-full-source-code/flutter-news-app-web-dashboard-full-source-code).

## ⭐ Feature Showcase: Everything You Get, Ready to Go

This app comes packed with all the features you need to launch a professional news application.
 
Click on any category to explore.

<details>
<summary><strong>📰 Content Discovery & Feed</strong></summary>

### 📰 Dynamic & Engaging Feed
- Display news in a beautiful, performant, infinitely scrolling feed.
- **Customizable Display:** Users can personalize their feed by choosing headline density (compact, standard, comfortable) and image style (hidden, small thumbnail, large thumbnail).
- **Rich In-Feed Decorators:** Beyond simple calls-to-action, the feed dynamically injects items like `CallToActionItem` (e.g., link account, upgrade, rate app, enable notifications) and `ContentCollectionItem` (e.g., suggested topics/sources to follow), all managed by configurable rules and user interaction status.
> **💡 Your Advantage:** You get a production-quality feed system instantly. Skip the months of complex UI work and state management. ⏱️

---

### 🔍 Powerful Filtering & Search
- **Quick-Access Filter Bar:** A persistent, horizontal filter bar on the main feed gives users one-tap access to their favorite content views. It includes built-in filters for "All" and "Followed" items, alongside any custom filters the user has saved.
- **Advanced Filter Creation:** A dedicated, full-screen interface allows users to build complex filters by combining multiple `Topics`, `Sources`, and `Countries`.
- **Saved Filters:** Users can name and save their custom filter combinations. These filters appear in the quick-access bar and can be reordered for a fully customized experience.
- **Integrated Headline Search:** A sleek search bar in the main feed's scrolling app bar provides a focused, full-screen search experience for headlines. A user avatar within the search bar offers instant modal access to account settings.
- **Intuitive Source Discovery:** A dedicated "Discover" tab provides a rich, multi-layered exploration experience. Users can browse sources by category in horizontally scrolling carousels, dive deeper into full lists with infinite scrolling and country-based filtering, and find specific sources using a familiar, contextual search bar.
> **🎯 Your Advantage:** Give your users powerful content discovery tools that keep them engaged and coming back for more.

</details>

<details>
<summary><strong>🔐 Security & Customization</strong></summary>

### 🔐 Robust User Authentication
- 📧 **Email + Code (Passwordless) Sign-In:** Modern and secure.
- 👤 **Anonymous Sign-In:** Allow users to explore before committing.
- 🔗 **Account Linking:** Seamlessly convert anonymous users to registered accounts, preserving all their personalized settings, content preferences, and saved headlines.
> **✅ Your Advantage:** All the complex security and user management is already done for you, including data migration when users link their accounts.

---

### 🧑‍🎨 Personalized User Accounts & Preferences
- **Content Preferences:** Follow/unfollow `Topic`s, `Source`s, and `Country`s.
- **Saved Headlines:** Bookmark articles for easy access later.
- **Saved Filters Management:** Rename, delete, and reorder saved filters to control your content discovery shortcuts.
- **Decorator Interaction Tracking:** User interactions with in-feed decorators (e.g., "Link Account" prompts) are tracked and persisted, ensuring a personalized and non-repetitive experience.
> **❤️ Your Advantage:** Built-in personalization features that drive user retention and create a sticky app experience.

---

### ⚙️ Customizable App Settings
- **Appearance:** Configure base theme (Light/Dark/System), accent colors (via FlexColorScheme), font choices (family, size, weight).
- **Feed Display:** Customize how headlines are presented, including `HeadlineDensity` and `HeadlineImageStyle`.
- **Language Selection:** Choose the application's display language.
> **🎨 Your Advantage:** Deliver a premium, adaptable user experience that caters to individual needs without writing any code.

</details>

<details>
<summary><strong>💰 Monetization & Remote Control</strong></summary>

### 💸 Advanced Monetization Engine: Flexible & Remotely Controlled
Go beyond basic ad banners. This app includes a sophisticated, provider-agnostic monetization engine designed for flexibility, performance, and a seamless user experience.

- **Multi-Platform by Design:** The entire ad system is built on a provider-agnostic abstraction, giving you the freedom to choose your monetization strategy. It comes with pre-built, production-ready providers for:
    - **Google AdMob Provider:** The industry standard, ready to go out of the box.
    - **Local Ad Provider:** Use a custom ad server to serve ads directly from your own backend, giving you full control over your ad inventory and revenue.
    - **Demo Ad Provider:** A built-in placeholder provider that makes development and testing a breeze, without needing live ad network credentials.
- **Seamless Integration, Not Intrusion:** Ads are designed to complement your content, not detract from it.
    - **Theme-Aware Styling:** Native ads automatically inherit their look and feel from the user's selected theme (light/dark mode, colors, fonts), making them feel like a natural part of the UI.
    - **Format-Aware Loading:** The system intelligently requests the right ad format (e.g., small or large templates) to match the user's feed layout preferences, ensuring a perfect fit every time.
- **Optimized for Performance:** A fast, fluid user experience is paramount.
    - **Intelligent Caching:** An `InlineAdCacheService` efficiently caches native and banner ads to ensure buttery-smooth scrolling in feeds, minimizing network requests and eliminating UI jank.
    - **Proactive Interstitial Loading:** A dedicated manager pre-loads full-screen interstitial ads in the background, so they are ready to be displayed instantly during navigation without any lag.
- **Powerful Remote Control:** All ad behavior is driven by the backend `RemoteConfig`. You can remotely control ad frequency, placement rules, and even switch the primary ad provider—all without shipping a new app update.
> **💸 Your Advantage:** Start generating revenue from day one with a highly extensible and robust ad system that’s built to scale with your business.

---

### 📡 Centralized Application Control: Dynamic & Adaptable
Gain complete command over your application's operational state and user experience through a powerful, backend-driven control plane. This architecture empowers you to manage critical app behavior and content delivery with significant flexibility, eliminating the need for frequent app store updates.

- **Real-time Configuration Management:**
    - **Comprehensive Global Settings:** Remotely manage all critical application parameters, including detailed advertising configurations, user preference limits, and overall application status. This allows for dynamic adjustments to features and policies without client-side code changes.
    - **Adaptive User Engagement:** Control the dynamic injection and behavior of in-app prompts and content collections. Tailor their appearance, frequency, and targeting based on user roles and historical interactions, ensuring a highly personalized and effective engagement strategy.
- **Robust Operational Resilience:**
    - **Proactive Status Monitoring:** An intelligent background service continuously monitors the application's health and status against backend directives. This ensures immediate detection and response to any changes in operational state.
    - **Seamless Critical State Handling:** Implement essential "kill switch" functionalities and version enforcement with built-in, production-ready flows:
        - **Maintenance Mode:** Instantly activate a full-screen maintenance page, providing clear communication to users during service downtime.
        - **Mandatory Updates:** Enforce critical updates by displaying a non-dismissible screen that guides users directly to the latest version in their respective app stores.
> **⚙️ Your Advantage:** Deploy with confidence, knowing you have a sophisticated, backend-driven system to manage your app's lifecycle, content, and user experience. This architecture provides the agility to respond to market demands and operational needs in real-time, ensuring continuous service delivery and a superior user journey.

</details>

<details>
<summary><strong>🏗️ Architecture & Technical Excellence</strong></summary>

### 🏗️ Clean & Modern Architecture
- Developed with best practices for a maintainable and scalable codebase:
    - **Multi-Layered Architecture:** A clear separation of concerns into a Data Layer (handling raw data retrieval), Repository Layer (abstracting data sources), and Business Logic Layer (managing state with BLoC) ensures the codebase is decoupled, testable, and easy to reason about.
    - **Robust Startup & Lifecycle Management:** The app features a rock-solid, "gatekeeper" startup architecture. An `AppInitializationPage` and dedicated `AppInitializationBloc` orchestrate a sequential, race-condition-free startup process using an `AppInitializer` service. This guarantees all critical dependencies (Remote Config, User Settings) are loaded and validated *before* the main application UI is ever built, eliminating an entire class of complex lifecycle bugs.
    - **Advanced State Management:** The app leverages the **BLoC pattern** for predictable state management, enhanced with `bloc_concurrency` transformers (droppable, restartable) for sophisticated UI event handling.
    - **Dependency Injection:** Dependencies are provided throughout the app using `RepositoryProvider` and `BlocProvider`, making components highly testable and reusable.
    - **Type-Safe, Declarative Routing:** Navigation is managed by **GoRouter**, using named routes for a well-structured and maintainable navigation system.
> **📈 Your Advantage:** The app is built on a clean, modern architecture that's easy to understand and maintain. It's solid and built to last.


---

### 🛠️ Flexible Environment Configuration
- Easily switch between development (in-memory data or local API) and production environments with a simple code change. This empowers rapid prototyping, robust testing, and seamless deployment.
> **🚀 Your Advantage:** A flexible setup that speeds up your development cycle and makes deployment simple.

---

### 🌍 Localization Ready
- Fully internationalized with working English and Arabic localizations (`.arb` files). Adding more languages is straightforward.
> **🌐 Your Advantage:** Easily adapt your application for a global audience and tap into new markets.

</details>

## 🔑 Licensing

This `Flutter News App Mobile Client` package is an integral part of the [**Flutter News App Full Source Code Toolkit**](https://github.com/flutter-news-app-full-source-code). For comprehensive details regarding licensing, including trial and commercial options for the entire toolkit, please refer to the main toolkit organization page.


## 🚀 Getting Started & Running Locally

For a complete guide on setting up your local environment, running the mobile client, and understanding the configuration, please see the **[Local Setup Guide](https://flutter-news-app-full-source-code.github.io/docs/mobile-client/local-setup/)** in our official documentation.

Our documentation provides a detailed, step-by-step walkthrough to get you up and running smoothly.
