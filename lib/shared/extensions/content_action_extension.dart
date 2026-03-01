import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client/shared/services/content_limitation_service.dart';

/// Extension on [ContentAction] to centralize mapping logic.
extension ContentActionExtension on ContentAction {
  /// Maps the client-side [ContentAction] to the core [LimitedAction] enum
  /// used for analytics.
  LimitedAction toLimitedAction() {
    switch (this) {
      case ContentAction.bookmarkHeadline:
        return LimitedAction.bookmarkHeadline;
      case ContentAction.followTopic:
        return LimitedAction.followTopic;
      case ContentAction.followSource:
        return LimitedAction.followSource;
      case ContentAction.followCountry:
        return LimitedAction.followCountry;
      case ContentAction.saveFilter:
        return LimitedAction.saveFilter;
      case ContentAction.pinFilter:
        return LimitedAction.pinFilter;
      case ContentAction.subscribeToSavedFilterNotifications:
        return LimitedAction.subscribeToSavedFilterNotifications;
      case ContentAction.postComment:
        return LimitedAction.postComment;
      case ContentAction.reactToContent:
        return LimitedAction.reactToContent;
      case ContentAction.submitReport:
        return LimitedAction.submitReport;
      case ContentAction.editProfile:
        throw UnsupportedError(
          'ContentAction $this does not map to LimitedAction',
        );
    }
  }

  /// Returns the localized body text for the limitation bottom sheet.
  String getLocalizedMessage(AppLocalizations l10n) {
    switch (this) {
      case ContentAction.bookmarkHeadline:
        return l10n.limitReachedBodySave;
      case ContentAction.followTopic:
      case ContentAction.followSource:
      case ContentAction.followCountry:
        return l10n.limitReachedBodyFollow;
      case ContentAction.postComment:
        return l10n.limitReachedBodyComments;
      case ContentAction.reactToContent:
        return l10n.limitReachedBodyReactions;
      case ContentAction.submitReport:
        return l10n.limitReachedBodyReports;
      case ContentAction.saveFilter:
        return l10n.limitReachedBodySaveFilters;
      case ContentAction.pinFilter:
        return l10n.limitReachedBodyPinFilters;
      case ContentAction.subscribeToSavedFilterNotifications:
        return l10n.limitReachedBodySubscribeToNotifications;
      case ContentAction.editProfile:
        return l10n.standardLimitBody;
    }
  }
}
