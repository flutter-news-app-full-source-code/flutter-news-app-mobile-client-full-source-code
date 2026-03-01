import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';

/// Extension on [SupportedLanguage] to provide localized string representations.
extension SupportedLanguageL10n on SupportedLanguage {
  /// Returns a localized string for the [SupportedLanguage].
  String l10n(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    switch (this) {
      case SupportedLanguage.en:
        return l10n.languageNameEn;
      case SupportedLanguage.es:
        return l10n.languageNameEs;
      case SupportedLanguage.fr:
        return l10n.languageNameFr;
      case SupportedLanguage.ar:
        return l10n.languageNameAr;
      case SupportedLanguage.pt:
        return l10n.languageNamePt;
      case SupportedLanguage.de:
        return l10n.languageNameDe;
      case SupportedLanguage.it:
        return l10n.languageNameIt;
      case SupportedLanguage.zh:
        return l10n.languageNameZh;
      case SupportedLanguage.hi:
        return l10n.languageNameHi;
      case SupportedLanguage.ja:
        return l10n.languageNameJa;
    }
  }
}