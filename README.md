<div align="center">
<img src="https://avatars.githubusercontent.com/u/202675624?s=400&u=dc72a2b53e8158956a3b672f8e52e39394b6b610&v=4" alt="Flutter News App Toolkit Logo" width="220">

# Flutter News App Mobile Client Full Source Code

<p>
<img src="https://img.shields.io/badge/coverage-XX%25-green?style=for-the-badge" alt="coverage: XX%">
<a href="https://flutter-news-app-full-source-code.github.io/flutter-news-app-mobile-client-full-source-code/"><img src="https://img.shields.io/badge/LIVE_DEMO-VIEW-orange?style=for-the-badge" alt="Live Demo: View"></a>
<a href="https://flutter-news-app-full-source-code.github.io/docs/mobile-client/local-setup/"><img src="https://img.shields.io/badge/DOCUMENTATION-READ-slategray?style=for-the-badge" alt="Documentation: Read"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/TRIAL_LICENSE-VIEW_TERMS-blue?style=for-the-badge" alt="Trial License: View Terms"></a>
<a href="https://github.com/sponsors/flutter-news-app-full-source-code"><img src="https://img.shields.io/badge/LIFETIME_LICENSE-PURCHASE-purple?style=for-the-badge" alt="Lifetime License: Purchase"></a>
</p>

</div>

This repository contains the complete, production-ready source code for a feature-rich Flutter news mobile app. It gives you everything you need to launch your own news app on the App Store and Google Play, right out of the box. It is a key component of the [**Flutter News App - Full Source Code Toolkit**](https://github.com/flutter-news-app-full-source-code), an ecosystem that also includes a Dart Frog [backend API](https://github.com/flutter-news-app-full-source-code/flutter-news-app-api-server-full-source-code) and a web-based [content dashboard](https://github.com/flutter-news-app-full-source-code/flutter-news-app-web-dashboard-full-source-code).

## ⭐ Everything You Get, Ready to Go

This app comes packed with all the features you need to launch a professional news application.

#### 📰 **Dynamic & Engaging Headlines Feed**
*   Display news in a beautiful, performant, infinitely scrolling feed.
*   **Customizable Display:** Users can personalize their feed by choosing headline density (compact, standard, comfortable) and image style (hidden, small thumbnail, large thumbnail).
*   **Rich In-Feed Decorators:** Beyond simple calls-to-action, the feed dynamically injects items like `CallToActionItem` (e.g., link account, upgrade, rate app, enable notifications) and `ContentCollectionItem` (e.g., suggested topics/sources to follow), all managed by configurable rules and user interaction status.
> **Your Advantage:** You get a production-quality feed system instantly. Skip the months of complex UI work and state management. ⏱️

#### 🔍 **Advanced Content Filtering & Search**
*   **Comprehensive Filtering:** Let users filter headlines by `Topic`, `Source`, and `Country` using a dedicated filter interface.
*   **"Followed Items" Filter:** Users can instantly filter the feed to show only content from their followed topics, sources, and countries.
*   **Unified Search:** Includes a dedicated search page to help users find specific content quickly, with the ability to search across headlines, topics, sources, and countries.
> **Your Advantage:** Give your users powerful content discovery tools that keep them engaged and coming back for more. 🎯

#### 💰 **Advanced Monetization Engine: Flexible & Remotely Controlled**
Go beyond basic ad banners. This app includes a sophisticated, provider-agnostic monetization engine designed for flexibility, performance, and a seamless user experience.

*   **Multi-Platform by Design:** The entire ad system is built on a provider-agnostic abstraction, giving you the freedom to choose your monetization strategy. It comes with pre-built, production-ready providers for:
    *   **Google AdMob:** The industry standard, ready to go out of the box.
    *   **Custom Ad Server:** Use the `LocalAdProvider` to serve ads directly from your own backend, giving you full control over your ad inventory and revenue.
    *   **Demo Provider:** A built-in placeholder provider that makes development and testing a breeze, without needing live ad network credentials.

*   **Seamless Integration, Not Intrusion:** Ads are designed to complement your content, not detract from it.
    *   **Theme-Aware Styling:** Native ads automatically inherit their look and feel from the user's selected theme (light/dark mode, colors, fonts), making them feel like a natural part of the UI.
    *   **Format-Aware Loading:** The system intelligently requests the right ad format (e.g., small or large templates) to match the user's feed layout preferences, ensuring a perfect fit every time.

*   **Optimized for Performance:** A fast, fluid user experience is paramount.
    *   **Intelligent Caching:** An `InlineAdCacheService` efficiently caches native and banner ads to ensure buttery-smooth scrolling in feeds, minimizing network requests and eliminating UI jank.
    *   **Proactive Interstitial Loading:** A dedicated manager pre-loads full-screen interstitial ads in the background, so they are ready to be displayed instantly during navigation without any lag.

*   **Powerful Remote Control:** All ad behavior is driven by the backend `RemoteConfig`. You can remotely control ad frequency, placement rules, and even switch the primary ad provider—all without shipping a new app update.

> **Your Advantage:** Start generating revenue from day one with a highly extensible and robust ad system that’s built to scale with your business. 💸

#### 🔐 **Robust User Authentication**
Secure and flexible authentication flows are built-in:
*   📧 **Email + Code (Passwordless) Sign-In:** Modern and secure.
*   👤 **Anonymous Sign-In:** Allow users to explore before committing.
*   🔗 **Account Linking:** Seamlessly convert anonymous users to registered accounts, preserving all their personalized settings, content preferences, and saved headlines.
> **Your Advantage:** All the complex security and user management is already done for you, including data migration when users link their accounts. ✅

#### 🧑‍🎨 **Personalized User Accounts & Preferences**
Users can tailor their experience:
*   **Content Preferences:** Follow/unfollow `Topic`s, `Source`s, and `Country`s.
*   **Saved Headlines:** Bookmark articles for easy access later.
*   **Decorator Interaction Tracking:** User interactions with in-feed decorators (e.g., "Link Account" prompts) are tracked and persisted, ensuring a personalized and non-repetitive experience.
> **Your Advantage:** Built-in personalization features that drive user retention and create a sticky app experience. ❤️

#### ⚙️ **Customizable App Settings**
Offer users control over their app experience:
*   **Appearance:** Configure base theme (Light/Dark/System), accent colors (via FlexColorScheme), font choices (family, size, weight).
*   **Feed Display:** Customize how headlines are presented, including `HeadlineDensity` and `HeadlineImageStyle`, and visibility of source/publish date.
*   **Language Selection:** Choose the application's display language.
> **Your Advantage:** Deliver a premium, adaptable user experience that caters to individual needs without writing any code. 🔧

#### 📡 **Backend-Driven Behavior**
The app is built to respond to commands from your backend API, allowing for dynamic control over the user experience:
*   **Remote Configuration:** Fetches global settings (`RemoteConfig`) from the backend, including ad configurations, user preference limits, and overall app status.
*   **Maintenance Mode:** Displays a full-screen "kill switch" page when the backend signals that the service is temporarily unavailable.
*   **Forced Updates:** Shows a non-dismissible "Update Required" screen when a new version is mandatory, guiding users to the app store.
*   **Dynamic Status Checks:** The `AppStatusService` proactively monitors the app's lifecycle and periodically checks for server-side status changes, ensuring real-time responsiveness.
> **Your Advantage:** The client-side logic to handle critical operational states is already implemented. Your app can gracefully manage server downtime and enforce version updates without you needing to code these complex, full-screen takeover flows. 🛠️

#### 📱 **Adaptive UI for All Screens**
Built with `flutter_adaptive_scaffold`, the app offers responsive navigation and layouts that look great on both phones and tablets.
> **Your Advantage:** Deliver a consistent and optimized UX across a wide range of devices effortlessly. ↔️

#### 🏗️ **Clean & Modern Architecture**
Developed with best practices for a maintainable and scalable codebase:
*   **Flutter & Dart:** Cutting-edge mobile development.
*   **BLoC Pattern:** Predictable and robust state management, enhanced with `bloc_concurrency` transformers (droppable, restartable, sequential) for advanced event handling.
*   **GoRouter:** Well-structured and powerful navigation.
*   **KV Storage Service:** Utilizes `KVStorageService` for secure and efficient local key-value storage.
> **Your Advantage:** The app is built on a clean, modern architecture that's easy to understand and maintain. It's solid and built to last. 📈

#### ⚙️ **Flexible Environment Configuration**
Easily switch between development (in-memory data or local API) and production environments with a simple code change. This empowers rapid prototyping, robust testing, and seamless deployment.
> **Your Advantage:** A flexible setup that speeds up your development cycle and makes deployment simple. 🚀

#### 🌍 **Localization Ready**
Fully internationalized with working English and Arabic localizations (`.arb` files). Adding more languages is straightforward.
> **Your Advantage:** Easily adapt your application for a global audience and tap into new markets. 🌐

---

## 🔑 License: Source-Available with a Free Trial

Get started for free and purchase when you're ready to launch!

*   **TRY IT:** Download and explore the full source code under the PolyForm Free Trial [license](LICENSE). Perfect for evaluation.
*   **BUY IT:** One-time payment for a lifetime license to publish unlimited commercial apps.
*   **GET YOURS:** [**Purchase via GitHub Sponsors**](https://github.sponsors/flutter-news-app-full-source-code).

> [!NOTE]
> *A single purchase provides a commercial license for every repository within the [Flutter News App - Full Source Code Toolkit](https://github.com/flutter-news-app-full-source-code). No other purchases are needed..*

---

## 🚀 Getting Started & Running Locally

For a complete guide on setting up your local environment, running the mobile client, and understanding the configuration, please see the **[Local Setup Guide](https://flutter-news-app-full-source-code.github.io/docs/mobile-client/local-setup/)** in our official documentation.

Our documentation provides a detailed, step-by-step walkthrough to get you up and running smoothly.

---

## ✅ Testing

This project aims for high test coverage to ensure quality and reliability.

*   Run tests with:
    ```bash
    very_good test --min-coverage 90
    ```
*   **Update Coverage Badge:** After `very_good test --min-coverage 90` passes, run `very_good test --min-coverage 100`. If it fails, get the integer percentage from the output (e.g., `97` from `97.55%`). If it passes, use `100`. Then, update `XX` in `![coverage: percentage](https://img.shields.io/badge/coverage-XX-green?style=for-the-badge)` in `README.md`.
