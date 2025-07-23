import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';

/// An extension on [ContentType] to provide localized display names.
extension ContentTypeX on ContentType {
  /// Returns a user-friendly, localized display name for the content type.
  String displayName(BuildContext context) {
    switch (this) {
      case ContentType.headline:
        return context.l10n.contentTypeHeadline;
      case ContentType.topic:
        return context.l10n.contentTypeTopic;
      case ContentType.source:
        return context.l10n.contentTypeSource;
      case ContentType.country:
        // While not searchable, providing a name is good practice.
        return context.l10n.contentTypeCountry;
    }
  }
}
