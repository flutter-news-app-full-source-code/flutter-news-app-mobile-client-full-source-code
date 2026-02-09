<div align="center">
  <img src="https://repository-images.githubusercontent.com/946589707/1ee61062-ded3-44f9-bb6d-c35cd03b5d64" alt="Flutter News App Toolkit Mockup" width="440">
  <h1>Flutter News App Mobile Client</h1>
  <p><strong>Complete, production-ready source code for a feature-rich Flutter news app mobile client.</strong></p>
</div>

<p align="center">
  <a href="https://flutter-news-app-full-source-code.github.io/docs/mobile-client/local-setup/"><img src="https://img.shields.io/badge/DOCUMENTATION-READ-slategray?style=for-the-badge" alt="Documentation: Read"></a>
  <img src="https://img.shields.io/badge/coverage-39%25-green?style=for-the-badge" alt="coverage: _%">
  <a href="LICENSE"><img src="https://img.shields.io/badge/TRIAL_LICENSE-VIEW_TERMS-blue?style=for-the-badge" alt="Trial License: View Terms"></a>
  <a href="https://github.com/sponsors/flutter-news-app-full-source-code"><img src="https://img.shields.io/badge/LIFETIME_LICENSE-PURCHASE-purple?style=for-the-badge" alt="Lifetime License: Purchase"></a>
</p>

This repository contains the complete, production-ready source code for a feature-rich Flutter news app mobile client. It gives you everything you need to launch your own news app on the App Store and Google Play, right out of the box. It is a key component of the [**Flutter News App Full Source Code Toolkit**](https://github.com/flutter-news-app-full-source-code), an ecosystem that also includes a Dart Frog [backend API](https://github.com/flutter-news-app-full-source-code/flutter-news-app-api-server-full-source-code) and a web-based [content management dashboard](https://github.com/flutter-news-app-full-source-code/flutter-news-app-web-dashboard-full-source-code).


## ⭐ Feature Showcase: Everything You Get, Ready to Go

This toolkit is engineered with production-ready features that provide immediate value. Each component is designed to solve common, complex challenges in mobile app development, saving you months of work.

Explore the high-level domains below to see how.

<details>
<summary><strong>📰 Dynamic News Feed & Personalization</strong></summary>

### 📱 Intelligent Content Delivery
A beautiful, infinitely scrolling feed serves as the core of the user experience. It's not just a list; it's an intelligent, user-driven content delivery system.
- **Instantaneous Content Switching:** An intelligent, session-based cache pre-fetches and holds data, eliminating loading spinners when users switch between their preferred content views.
- **Personalized Viewing:** Users control their experience with settings for information density and image presentation, adapting the feed to their reading style.
- **Smart In-Feed Prompts:** The feed dynamically injects context-aware items like calls-to-action and content suggestions, driven by configurable rules to avoid user fatigue.
> **Your Advantage:** You get a world-class, production-quality feed system out of the box. Skip the complex UI, state management, and performance optimization work.

---

### 🎨 Deep User Customization
Empower users to tailor the app to their exact preferences, creating a sticky and personal experience.
- **Content Subscriptions:** Users can personalize their feed by following specific topics, news organizations, or areas of interest.
- **Appearance Control:** A comprehensive settings panel allows configuration of the theme (Light/Dark/System), accent colors, and font styles.
- **Personalized Collections:** Users can bookmark headlines for later reading and fully manage their custom-built news feeds.
> **Your Advantage:** Built-in personalization features that are proven to drive user retention are included and fully functional from day one.

</details>

<details>
<summary><strong>🔎 Advanced Search & Discovery</strong></summary>

### 🧭 Powerful Content Curation
Give users the tools to find exactly what they're looking for with a multi-faceted discovery system.
- **Dedicated Discovery Hub:** Users can browse publishers by category in horizontally scrolling carousels, apply regional filters, and perform targeted searches.
- **Smart Filter Bar:** A persistent, one-tap filter bar provides instant access to pre-defined and user-created content streams directly from the feed.
- **Multi-Dimensional Search:** Users can perform targeted searches across headlines, sources, and topics with advanced filtering options.
> **Your Advantage:** A sophisticated discovery engine that encourages exploration and increases session depth.

---

### 🔖 Smart Curation & Alerts
Turn passive readers into active curators with advanced tools for managing information flow.
- **Saved Filter Hub:** A dedicated hub allows users to construct, save, and manage highly specific news feeds (e.g., "Tech News from US & UK").
- **One-Tap Pinning:** Users can pin their favorite custom filters to the main feed for instant access.
- **Proactive Notification Subscriptions:** This is a standout feature. When saving a filter, users can subscribe to receive push notifications—such as breaking news alerts or daily digests—specifically for content that matches their custom criteria.
> **Your Advantage:** Deliver a "Bloomberg-terminal" style experience for power users, driving high retention through personalized alerts.

</details>

<details>
<summary><strong>🔔 Notifications & Engagement</strong></summary>

### 🔔 Proactive & Flexible Push Notifications
A robust, backend-driven notification system keeps users informed and brings them back to the content they care about.
- **Multi-Provider Architecture:** Built on an abstraction that supports any push notification service. It ships with production-ready providers for Firebase (FCM) and OneSignal.
- **Remote Provider Switching:** The primary notification provider is selected via remote configuration, allowing you to switch services on the fly without shipping an app update.
- **Intelligent Deep-Linking:** Tapping a notification opens the app and navigates directly to the relevant content, such as a specific news article, providing a seamless user experience.
- **Integrated Notification Center:** Includes a full-featured in-app notification center where users can view their history. Foreground notifications are handled gracefully, appearing as an unread indicator that leads the user to this central hub, avoiding intrusive system alerts during active use.
> **Your Advantage:** You get a highly flexible and scalable notification system that avoids vendor lock-in and is ready to re-engage users from day one.

---

### 💬 Community & Feedback Systems
A complete suite of tools to build a vibrant user community and gather valuable feedback directly within the app.
- **Configurable Headline Engagement:** Enable immediate user interaction directly on each headline within the feed. The entire engagement system is controlled via remote configuration, allowing you to dynamically adjust the depth of user interaction—from simple reactions to full comment threads—without an app update.
- **Intelligent Review Funnel:** A sophisticated, multi-layered system that strategically prompts users for an app review. Its behavior is entirely driven by remote configuration, including cooldown periods and positive interaction thresholds. It first gauges user sentiment with a private, in-app prompt: positive responses trigger the native OS review dialog, while negative responses open a private feedback form, ensuring you only ask happy users for public reviews and capture valuable insights from others.
- **Moderated Content Reporting:** Empower your community to maintain content quality with a built-in reporting system. Users can easily report headlines, sources, or individual comments through a guided process. All reports are submitted to the backend and are designed to be managed and actioned from the companion web dashboard.
> **Your Advantage:** Deploy a full-featured community and feedback system from day one. Skip the complexity of building engagement UI, state management for reactions, and the nuanced logic of a best-practice app review funnel.

</details>

<details>
<summary><strong>📊 Analytics & Business Intelligence</strong></summary>

### 📈 Pluggable, Multi-Provider Analytics
A robust, type-safe analytics system designed to give you deep insight into user behavior and feature adoption.
- **Multi-Provider Architecture:** Built on a powerful abstraction that supports any analytics service. It ships with production-ready providers for Firebase Analytics and Mixpanel, plus a Demo provider for easy development and testing.
- **Remote Provider Switching:** The primary analytics provider is selected via remote configuration, allowing you to switch services on the fly without shipping an app update.
- **Intelligent Event Throttling:** A smart "Analytics Engine" sits between your app and the provider, enforcing server-side rules for event sampling and filtering. This prevents you from exceeding provider rate limits on high-frequency events (like content views) and allows you to disable specific events remotely without an app update.
> **Your Advantage:** You get a highly flexible and scalable analytics system that avoids vendor lock-in and provides granular control over your data stream.

</details>

<details>
<summary><strong>👤 User Identity & Personalization</strong></summary>

### 🔐 Secure, Modern Authentication
A complete and secure user authentication system is built-in, covering the entire user lifecycle.
- **Flexible Sign-In Options:** Includes modern passwordless and anonymous sign-in flows to reduce friction for new users.
- **Tiered User Model:** The system clearly separates user identity (`Guest`, `Standard`) from feature entitlement (`Premium`), allowing for granular control over feature access.
- **Seamless Account Linking:** A robust process allows anonymous users to create a permanent account while transparently migrating all their data—including preferences, bookmarked headlines, and saved content views.
> **Your Advantage:** The complex logic for security, user management, and data migration is already solved, providing a seamless and secure user journey from the start.

</details>

<details>
<summary><strong>⚙️ Monetization & Revenue</strong></summary>

### 🏆 Engagement-Driven Rewards
A modern, time-based reward system that unlocks features through user engagement, moving away from traditional subscriptions.
- **Pay-with-Time Model:** Users can "pay" for premium features (like removing ads or unlocking exclusive content) by engaging with high-value rewarded video ads, monetizing non-paying users without friction.
- **Server-Verified Security:** Leverages AdMob's Server-Side Verification (SSV) to securely grant rewards like an ad-free experience or access to daily digests, ensuring a fraud-proof economy.
- **Centralized Rewards Hub:** A dedicated "Rewards Center" allows users to see all available offers, track the countdown on active rewards, and initiate new reward actions.
- **Configurable Offers:** All reward types and their durations (e.g., "Ad-Free for 24 hours") are controlled via remote configuration, allowing for dynamic adjustments without an app update.
> **Your Advantage:** Launch with a flexible, engagement-focused monetization strategy. The complex logic for handling ad display, server-side verification, and state management for timed rewards is already built, tested, and ready for production.

---

### 💸 Flexible, Provider-Agnostic Monetization
Start generating revenue immediately with a sophisticated ad system designed for performance and flexibility.
- **Multi-Provider Architecture:** Built on an abstraction that supports any ad network. It ships with production-ready providers for Google AdMob plus a Demo provider for easy testing.
- **Theme-Aware Ads:** Both inline and full-screen ads automatically adapt to the user's theme settings, making them feel like a natural part of the UI instead of an intrusion.
- **Performance Optimized:** An intelligent caching layer for inline and interstitial ads ensures a smooth, jank-free scrolling experience in feeds and during navigation.
> **Your Advantage:** Deploy a highly extensible, revenue-ready ad system that respects the user experience and scales with your business needs, all without being locked into a single provider.

</details>

<details>
<summary><strong>📡 Remote Management & Operations</strong></summary>

### 🎛️ Backend-Driven Remote Control
Manage your app's behavior and operational state in real-time without needing to ship an app update.
- **Centralized Configuration:** Remotely control ad frequency, placement rules, user permission limits, and other critical parameters from the backend.
- **Critical State Management:** Includes built-in, production-ready flows for essential "kill switch" scenarios. Instantly activate a full-screen maintenance page or enforce a mandatory update with a non-dismissible screen that directs users to the app store.
> **Your Advantage:** Gain the agility to respond to operational needs in real-time. Deploy with the confidence that you can manage the entire app lifecycle, from feature flags to critical updates, directly from your server.

</details>

<details>
<summary><strong>🏗️ Architecture & Developer Experience</strong></summary>

### ✅ Clean, Scalable & Maintainable Codebase
Built on a modern, multi-layered architecture that prioritizes clarity, testability, and separation of concerns.
- **Predictable State Management:** Leverages the BLoC pattern with advanced concurrency transformers to handle complex UI events gracefully.
- **Robust Startup Process:** A "gatekeeper" initialization sequence ensures all critical dependencies (Remote Config, User Settings) are loaded and validated *before* the main UI is built, eliminating a whole class of lifecycle bugs.
- **Type-Safe Declarative Routing:** Navigation is managed by GoRouter using named routes for a well-structured and maintainable system.
> **Your Advantage:** The codebase is engineered to be easy to understand, maintain, and extend. It provides a solid, professional foundation for future development.

---

### 🛠️ Production-Ready Environment Tooling
Utilizes compile-time variables (`--dart-define`) to seamlessly switch between `production`, `development`, and `demo` environments.
- **Error-Proof Configuration:** This approach ensures environment-specific settings like API endpoints are set at build time, preventing accidental release of development configurations.
> **Your Advantage:** A robust, professional environment setup that streamlines the development-to-production pipeline and prevents common configuration mistakes.

---

### 🌍 Localization-Ready from Day One
The application is fully internationalized and includes working English and Arabic localizations out of the box.
- **Simple Extensibility:** Adding new languages is a straightforward process using standard `.arb` files.
> **Your Advantage:** The architecture is designed for a global audience, allowing you to easily adapt the application and expand into new markets.

</details>

## 🚀 Getting Started & Running Locally

For a complete guide on setting up your local environment and running this project, please see the [Wiki](https://github.com/flutter-news-app-full-source-code/flutter-news-app-mobile-client-full-source-code/wiki) tab in this repository.

## 🔑 Licensing

This source code is licensed for commercial use and is provided for local evaluation. A **Lifetime Commercial License** is required for any production or public-facing application.

Please visit the main [Flutter News App Full Source Code Toolkit](https://github.com/flutter-news-app-full-source-code) organization page to review the full license terms and to purchase.
