# 📱✨ ht_main

![coverage: percentage](https://img.shields.io/badge/coverage-XX-green)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: PolyForm Free Trial](https://img.shields.io/badge/License-PolyForm%20Free%20Trial-blue)](https://polyformproject.org/licenses/free-trial/1.0.0)

`ht_main` is a flutter mobile application that serves as both a powerful, fully functional news application ready for deployment, and an exceptionally robust starter kit, architected for easy extension and customization. It is a key component of the [Headlines Toolkit](https://github.com/headlines-toolkit), an ecosystem that also includes a [Dart Frog backend API](https://github.com/headlines-toolkit/ht-api) and a [web-based content dashboard](https://github.com/headlines-toolkit/ht-dashboard).

## ⭐ Features & Benefits

`ht_main` comes packed with features to accelerate your development and delight your users:

#### 📰 **Dynamic & Engaging Headlines Feed**
Experience a beautifully crafted, infinitely scrolling news feed. It's highly performant and ready for your content.
*   **Benefit for you:** Save months of UI/UX development and complex state management. Get a production-quality feed system instantly! ⏱️

#### 🔍 **Advanced Content Filtering & Search**
Empower users with intuitive filtering for headlines by categories, sources, and countries. A dedicated search page helps users find exactly what they're looking for.
*   **Benefit for you:** Offer powerful content discovery tools that significantly enhance user engagement and satisfaction. 🎯

#### 🔐 **Robust User Authentication**
Secure and flexible authentication flows are built-in:
*   📧 **Email + Code (Passwordless) Sign-In:** Modern and secure.
*   👤 **Anonymous Sign-In:** Allow users to explore before committing.
*   🔗 **Account Linking:** Seamlessly convert anonymous users to registered accounts, ensuring all their personalized settings (like theme and language), content preferences (followed categories, sources, countries), and saved headlines are preserved and synced.
*   **Benefit for you:** Complex security and user management handled, including data migration during account linking, letting you focus on features. ✅

#### 🧑‍🎨 **Personalized User Accounts & Preferences**
Users can tailor their experience:
*   **Content Preferences:** Follow/unfollow categories, sources, and countries.
*   **Saved Headlines:** Bookmark articles for easy access later.
*   **Benefit for you:** A strong foundation for personalization, driving user retention and creating a sticky app experience. ❤️

#### ⚙️ **Customizable App Settings**
Offer users control over their app experience:
*   **Appearance:** Light/Dark/System themes, accent colors (via FlexColorScheme), font choices, and text scaling.
*   **Feed Display:** Customize how headlines are presented.
*   **Benefit for you:** Provide a premium, adaptable user experience that caters to individual needs. 🔧

#### 📱 **Adaptive UI for All Screens**
Built with `flutter_adaptive_scaffold`, `ht_main` offers responsive navigation and layouts that look great on both phones and tablets.
*   **Benefit for you:** Deliver a consistent and optimized UX across a wide range of devices effortlessly. ↔️

#### 🏗️ **Clean & Modern Architecture**
Developed with best practices for a maintainable and scalable codebase:
*   **Flutter & Dart:** Cutting-edge mobile development.
*   **BLoC Pattern:** Predictable and robust state management.
*   **GoRouter:** Well-structured and powerful navigation.
*   **Benefit for you:** An easy-to-understand, extendable, and testable foundation for your project. 📈

#### 🌍 **Localization Ready**
Fully internationalized with working English and Arabic localizations (`.arb` files). Adding more languages is straightforward.
*   **Benefit for you:** Easily adapt your application for a global audience. 🌐

---

## 🔑 Access and Licensing

`ht-main` is source-available as part of the Headlines Toolkit ecosystem.

To acquire a commercial license for building unlimited news applications, please visit 
the [Headlines Toolkit GitHub organization page](https://github.com/headlines-toolkit)
for more details.

---

## 🚀 Getting Started

1.  **Ensure Flutter is installed.** (See [Flutter documentation](https://flutter.dev/docs/get-started/install))
2.  **Clone the repository:**
    ```bash
    git clone https://github.com/headlines-toolkit/ht-main.git
    cd ht-main
    ```
3.  **Get dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```
    *(Note: For full functionality, ensure the `ht-api` backend service is running and accessible.)*

---

## ✅ Testing

This project aims for high test coverage to ensure quality and reliability.

*   Run tests with:
    ```bash
    flutter test
    ```
