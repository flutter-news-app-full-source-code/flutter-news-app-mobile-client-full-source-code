<div align="center">
<img src="https://avatars.githubusercontent.com/u/202675624?s=400&u=dc72a2b53e8158956a3b672f8e52e39394b6b610&v=4" alt="Flutter News App Toolkit Logo" width="220">

# Flutter News App - Mobile Client Full Source Code

<p>
<img src="https://img.shields.io/badge/coverage-0%25-green?style=for-the-badge" alt="coverage: 0%">
<a href="https://flutter-news-app-full-source-code.github.io/flutter-news-app-mobile-client-full-source-code/"><img src="https://img.shields.io/badge/LIVE_DEMO-VIEW-orange?style=for-the-badge" alt="Live Demo: View"></a>
<a href="https://google.com"><img src="https://img.shields.io/badge/DOCUMENTATION-READ-slategray?style=for-the-badge" alt="Documentation: Read"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/TRIAL_LICENSE-VIEW_TERMS-blue?style=for-the-badge" alt="Trial License: View Terms"></a>
<a href="https://github.com/sponsors/flutter-news-app-full-source-code"><img src="https://img.shields.io/badge/LIFETIME_LICENSE-PURCHASE-purple?style=for-the-badge" alt="Lifetime License: Purchase"></a>
</p>

</div>

This repository contains the complete, production-ready source code for a feature-rich Flutter news mobile app. It gives you everything you need to launch your own news app on the App Store and Google Play, right out of the box. It is a key component of the [**Flutter News App - Full Source Code Toolkit**](https://github.com/flutter-news-app-full-source-code), an ecosystem that also includes a Dart Frog [backend API](https://github.com/flutter-news-app-full-source-code/flutter-news-app-api-server-full-source-code) and a web-based [content dashboard](https://github.com/flutter-news-app-full-source-code/flutter-news-app-web-dashboard-full-source-code).

## ⭐ Everything You Get, Ready to Go

This app comes packed with all the features you need to launch a professional news application.

#### 📰 **Dynamic & Engaging Headlines Feed**
*   Display news in a beautiful, performant, infinitely scrolling feed.
*   Strategically display in-feed messages to drive user actions. Show calls-to-action like 'Create an Account' to anonymous users or 'Upgrade to Premium' to authenticated users, all based on configurable rules.
> **Your Advantage:** You get a production-quality feed system instantly. Skip the months of complex UI work and state management. ⏱️

#### 🔍 **Advanced Content Filtering & Search**
*   Let users filter headlines by categories, sources, and countries.
*   Includes a dedicated search page to help users find specific content quickly.
> **Your Advantage:** Give your users powerful content discovery tools that keep them engaged and coming back for more. 🎯

#### 🔐 **Robust User Authentication**
Secure and flexible authentication flows are built-in:
*   📧 **Email + Code (Passwordless) Sign-In:** Modern and secure.
*   👤 **Anonymous Sign-In:** Allow users to explore before committing.
*   🔗 **Account Linking:** Seamlessly convert anonymous users to registered accounts, preserving all their personalized settings, content preferences, and saved headlines.
> **Your Advantage:** All the complex security and user management is already done for you, including data migration when users link their accounts. ✅

#### 🧑‍🎨 **Personalized User Accounts & Preferences**
Users can tailor their experience:
*   **Content Preferences:** Follow/unfollow categories, sources, and countries.
*   **Saved Headlines:** Bookmark articles for easy access later.
> **Your Advantage:** Built-in personalization features that drive user retention and create a sticky app experience. ❤️

#### ⚙️ **Customizable App Settings**
Offer users control over their app experience:
*   **Appearance:** Light/Dark/System themes, accent colors (via FlexColorScheme), font choices, and text scaling.
*   **Feed Display:** Customize how headlines are presented.
> **Your Advantage:** Deliver a premium, adaptable user experience that caters to individual needs without writing any code. 🔧

#### 📱 **Adaptive UI for All Screens**
Built with `flutter_adaptive_scaffold`, the app offers responsive navigation and layouts that look great on both phones and tablets.
> **Your Advantage:** Deliver a consistent and optimized UX across a wide range of devices effortlessly. ↔️

#### 🏗️ **Clean & Modern Architecture**
Developed with best practices for a maintainable and scalable codebase:
*   **Flutter & Dart:** Cutting-edge mobile development.
*   **BLoC Pattern:** Predictable and robust state management.
*   **GoRouter:** Well-structured and powerful navigation.
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
*   **GET YOURS:** [**Purchase via GitHub Sponsors**](https://github.com/sponsors/flutter-news-app-full-source-code).

> [!NOTE]
> *A single purchase provides a commercial license for every repository within the [Flutter News App - Full Source Code Toolkit](https://github.com/flutter-news-app-full-source-code). No other purchases are needed..*

---

## 🚀 Getting Started & Running Locally

1.  **Ensure Flutter is installed.** (See [Flutter documentation](https://flutter.dev/docs/get-started/install))
2.  **Clone the repository:**
    ```bash
    git clone https://github.com/flutter-news-app-full-source-code/flutter-news-app-mobile-client-full-source-code.git
    cd flutter-news-app-mobile-client-full-source-code
    ```
3.  **Get dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the app:**

    To run the app, first select your desired environment in `lib/main.dart`:

    ```dart
    // lib/main.dart

    // Use `AppEnvironment.demo` to run with in-memory data (no API needed).
    // Use `AppEnvironment.development` to connect to a local backend API.
    // Use `AppEnvironment.production` to connect to a live backend API.
    const appEnvironment = AppEnvironment.demo; 
    ```

    Then, run the app from your terminal:
    ```bash
    flutter run -d chrome
    ```
    *(Note: For `development/production` environment, ensure the [backend service](https://github.com/flutter-news-app-full-source-code/flutter-news-app-api-server-full-source-code) is running.)*

---

## ✅ Testing

This project aims for high test coverage to ensure quality and reliability.

*   Run tests with:
    ```bash
    flutter test
