import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';

/// An extension on [FeedDecoratorType] to provide randomized, localized
/// strings for decorator titles, descriptions, and calls to action.
///
/// This centralizes the logic for selecting from multiple string variations,
/// making the UI components cleaner and the string management more maintainable.
extension FeedDecoratorTypeL10n on FeedDecoratorType {
  /// Returns a random string from a list of string-producing functions.
  ///
  /// This helper function is used to select a random variation of a
  /// localized string. It takes a list of functions, each returning a string,
  /// and executes one at random.
  String _randomString(List<String> options) {
    if (options.isEmpty) return '';
    final randomIndex = Random().nextInt(options.length);
    return options[randomIndex];
  }

  /// Resolves the [SupportedLanguage] key corresponding to the current locale.
  SupportedLanguage _getLanguageKey(AppLocalizations l10n) {
    try {
      // l10n.localeName typically returns 'en', 'ar', etc.
      // We match this against the SupportedLanguage enum.
      return SupportedLanguage.values.byName(l10n.localeName);
    } catch (_) {
      // Fallback to English if the locale is not supported or parsing fails.
      // This ensures we always return a valid key for the map.
      return SupportedLanguage.en;
    }
  }

  /// Gets a randomized, localized title for the decorator.
  ///
  /// Uses a switch statement on the decorator type to determine the correct
  /// set of title variations from [AppLocalizations] and then selects one
  /// randomly.
  String getRandomTitle(AppLocalizations l10n) {
    switch (this) {
      case FeedDecoratorType.linkAccount:
        return _randomString([
          l10n.decoratorLinkAccountTitle_1,
          l10n.decoratorLinkAccountTitle_2,
        ]);
      case FeedDecoratorType.unlockRewards:
        return _randomString([l10n.decoratorUnlockRewardsTitle]);
      case FeedDecoratorType.rateApp:
        return _randomString([
          l10n.decoratorRateAppTitle_1,
          l10n.decoratorRateAppTitle_2,
        ]);
      case FeedDecoratorType.suggestedTopics:
        return _randomString([
          l10n.decoratorSuggestedTopicsTitle_1,
          l10n.decoratorSuggestedTopicsTitle_2,
        ]);
      case FeedDecoratorType.suggestedSources:
        return _randomString([
          l10n.decoratorSuggestedSourcesTitle_1,
          l10n.decoratorSuggestedSourcesTitle_2,
        ]);
    }
  }

  /// Returns a map containing the randomized title keyed by the current language.
  Map<SupportedLanguage, String> getLocalizedTitleMap(AppLocalizations l10n) {
    final text = getRandomTitle(l10n);
    return {_getLanguageKey(l10n): text};
  }

  /// Gets a randomized, localized description for the decorator.
  ///
  /// This only applies to [FeedDecoratorCategory.callToAction] decorators.
  /// It returns an empty string for content collection types.
  String getRandomDescription(AppLocalizations l10n, {String? duration}) {
    switch (this) {
      case FeedDecoratorType.linkAccount:
        return _randomString([
          l10n.decoratorLinkAccountDescription_1,
          l10n.decoratorLinkAccountDescription_2,
        ]);
      case FeedDecoratorType.unlockRewards:
        // Enforce duration presence for this type.
        if (duration == null) {
          return '';
        }
        return _randomString([
          l10n.decoratorUnlockRewardsDescription(duration),
        ]);
      case FeedDecoratorType.rateApp:
        return _randomString([
          l10n.decoratorRateAppDescription_1,
          l10n.decoratorRateAppDescription_2,
        ]);
      case FeedDecoratorType.suggestedTopics:
      case FeedDecoratorType.suggestedSources:
        return '';
    }
  }

  /// Returns a map containing the randomized description keyed by the current language.
  Map<SupportedLanguage, String> getLocalizedDescriptionMap(
    AppLocalizations l10n, {
    String? duration,
  }) {
    final text = getRandomDescription(l10n, duration: duration);
    return {_getLanguageKey(l10n): text};
  }

  /// Gets a randomized, localized call-to-action text for the decorator.
  ///
  /// This only applies to [FeedDecoratorCategory.callToAction] decorators.
  /// It returns an empty string for content collection types.
  String getRandomCtaText(AppLocalizations l10n) {
    switch (this) {
      case FeedDecoratorType.linkAccount:
        return _randomString([
          l10n.decoratorLinkAccountCta_1,
          l10n.decoratorLinkAccountCta_2,
        ]);
      case FeedDecoratorType.unlockRewards:
        return _randomString([l10n.decoratorUnlockRewardsCta]);
      case FeedDecoratorType.rateApp:
        return _randomString([
          l10n.decoratorRateAppCta_1,
          l10n.decoratorRateAppCta_2,
        ]);
      case FeedDecoratorType.suggestedTopics:
      case FeedDecoratorType.suggestedSources:
        return '';
    }
  }

  /// Returns a map containing the randomized CTA text keyed by the current language.
  Map<SupportedLanguage, String> getLocalizedCtaMap(AppLocalizations l10n) {
    final text = getRandomCtaText(l10n);
    return {_getLanguageKey(l10n): text};
  }
}
