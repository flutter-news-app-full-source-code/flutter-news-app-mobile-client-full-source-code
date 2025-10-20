import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';

/// An extension to provide localized names for the [SourceType] enum.
extension SourceTypeL10n on SourceType {
  /// Returns the localized name for the source type.
  String l10n(AppLocalizations l10n) {
    switch (this) {
      case SourceType.newsAgency:
        return l10n.sourceTypeNewsAgency;
      case SourceType.localNewsOutlet:
        return l10n.sourceTypeLocalNewsOutlet;
      case SourceType.nationalNewsOutlet:
        return l10n.sourceTypeNationalNewsOutlet;
      case SourceType.internationalNewsOutlet:
        return l10n.sourceTypeInternationalNewsOutlet;
      case SourceType.specializedPublisher:
        return l10n.sourceTypeSpecializedPublisher;
      case SourceType.blog:
        return l10n.sourceTypeBlog;
      case SourceType.governmentSource:
        return l10n.sourceTypeGovernmentSource;
      case SourceType.aggregator:
        return l10n.sourceTypeAggregator;
      case SourceType.other:
        return l10n.sourceTypeOther;
    }
  }

  /// Returns the plural localized name for the source type.
  String l10nPlural(AppLocalizations l10n) {
    switch (this) {
      case SourceType.newsAgency:
        return l10n.sourceTypeNewsAgencies;
      case SourceType.localNewsOutlet:
        return l10n.sourceTypeLocalNewsOutlets;
      case SourceType.nationalNewsOutlet:
        return l10n.sourceTypeNationalNewsOutlets;
      case SourceType.internationalNewsOutlet:
        return l10n.sourceTypeInternationalNewsOutlets;
      case SourceType.specializedPublisher:
        return l10n.sourceTypeSpecializedPublishers;
      case SourceType.blog:
        return l10n.sourceTypeBlogs;
      case SourceType.governmentSource:
        return l10n.sourceTypeGovernmentSources;
      case SourceType.aggregator:
        return l10n.sourceTypeAggregators;
      case SourceType.other:
        return l10n.sourceTypeOthers;
    }
  }
}
