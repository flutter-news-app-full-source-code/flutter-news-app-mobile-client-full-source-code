import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';

/// {@template demo_content_limitation_service}
/// An in-memory implementation of [ContentLimitationService] for the demo
/// environment.
///
/// This service simulates backend limit enforcement by tracking user actions
/// within a single session. It uses simple in-memory counters to check against
/// the limits defined in the `RemoteConfig`. This provides a high-fidelity
/// demo experience without requiring a backend or local persistence.
/// {@endtemplate}
class DemoContentLimitationService implements ContentLimitationService {
  /// {@macro demo_content_limitation_service}
  DemoContentLimitationService({required AppBloc appBloc}) : _appBloc = appBloc;

  final AppBloc _appBloc;

  /// In-memory counters for daily actions. These reset with every app launch.
  final Map<ContentAction, int> _dailyCounts = {};

  @override
  Future<LimitationStatus> checkAction(ContentAction action) async {
    final state = _appBloc.state;
    final user = state.user;
    final preferences = state.userContentPreferences;
    final remoteConfig = state.remoteConfig;

    if (user == null || preferences == null || remoteConfig == null) {
      return LimitationStatus.allowed;
    }

    final limits = remoteConfig.user.limits;
    final role = user.appRole;

    switch (action) {
      case ContentAction.bookmarkHeadline:
        final count = preferences.savedHeadlines.length;
        final limit = limits.savedHeadlines[role];
        if (limit != null && count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.saveHeadlineFilter:
        final count = preferences.savedHeadlineFilters.length;
        final limit = limits.savedHeadlineFilters[role]?.total;
        if (limit != null && count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.pinHeadlineFilter:
        final count =
            preferences.savedHeadlineFilters.where((f) => f.isPinned).length;
        final limit = limits.savedHeadlineFilters[role]?.pinned;
        if (limit != null && count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.followTopic:
      case ContentAction.followSource:
      case ContentAction.followCountry:
        final limit = limits.followedItems[role];
        if (limit == null) return LimitationStatus.allowed;

        final int count;
        switch (action) {
          case ContentAction.followTopic:
            count = preferences.followedTopics.length;
          case ContentAction.followSource:
            count = preferences.followedSources.length;
          case ContentAction.followCountry:
            count = preferences.followedCountries.length;
          default:
            count = 0;
        }
        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.postComment:
        final count = _dailyCounts[action] ?? 0;
        final limit = limits.commentsPerDay[role];
        if (limit != null && count >= limit) {
          return _getLimitationStatusForRole(role);
        }
        _dailyCounts[action] = count + 1;

      case ContentAction.reactToContent:
        final count = _dailyCounts[action] ?? 0;
        final limit = limits.reactionsPerDay[role];
        if (limit != null && count >= limit) {
          return _getLimitationStatusForRole(role);
        }
        _dailyCounts[action] = count + 1;

      case ContentAction.submitReport:
        final count = _dailyCounts[action] ?? 0;
        final limit = limits.reportsPerDay[role];
        if (limit != null && count >= limit) {
          return _getLimitationStatusForRole(role);
        }
        _dailyCounts[action] = count + 1;

      // This action is not limited by this service.
      case ContentAction.subscribeToHeadlineFilterNotifications:
        break;
    }

    return LimitationStatus.allowed;
  }

  /// Maps an [AppUserRole] to the corresponding [LimitationStatus].
  LimitationStatus _getLimitationStatusForRole(AppUserRole role) {
    switch (role) {
      case AppUserRole.guestUser:
        return LimitationStatus.anonymousLimitReached;
      case AppUserRole.standardUser:
        return LimitationStatus.standardUserLimitReached;
      case AppUserRole.premiumUser:
        return LimitationStatus.premiumUserLimitReached;
    }
  }
}