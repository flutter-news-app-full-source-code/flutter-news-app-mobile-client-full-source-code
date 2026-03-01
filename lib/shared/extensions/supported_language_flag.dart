import 'package:core/core.dart';

/// Extension on [SupportedLanguage] to provide flag image URLs.
extension SupportedLanguageFlag on SupportedLanguage {
  /// Returns a country code reasonably associated with the language for flag display.
  String get flagCountryCode {
    switch (this) {
      case SupportedLanguage.en:
        return 'gb'; // Great Britain
      case SupportedLanguage.es:
        return 'es'; // Spain
      case SupportedLanguage.fr:
        return 'fr'; // France
      case SupportedLanguage.ar:
        return 'sa'; // Saudi Arabia (common for Arabic)
      case SupportedLanguage.pt:
        return 'pt'; // Portugal
      case SupportedLanguage.de:
        return 'de'; // Germany
      case SupportedLanguage.it:
        return 'it'; // Italy
      case SupportedLanguage.zh:
        return 'cn'; // China
      case SupportedLanguage.hi:
        return 'in'; // India
      case SupportedLanguage.ja:
        return 'jp'; // Japan
    }
  }

  /// Returns a URL for a 40px-wide flag image from a CDN.
  String get flagUrl => 'https://flagcdn.com/w40/$flagCountryCode.png';
}
