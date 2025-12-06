import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:logging/logging.dart';

/// {@template demo_data_initializer_service}
/// A service responsible for ensuring that essential user-specific data
/// (like [AppSettings] and [UserContentPreferences]) exists for a new user
/// in the demo environment.
///
/// Instead of creating default empty objects, this service now acts as a
/// "fixture injector". It clones rich, pre-defined data from fixture lists,
/// providing new anonymous users with a full-featured initial experience,
/// including pre-populated saved filters.
///
/// This service is specifically designed for the in-memory data clients
/// used in the demo environment. In production/development environments,
/// the backend API is responsible for initializing user data.
/// {@endtemplate}
class DemoDataInitializerService {
  /// {@macro demo_data_initializer_service}
  DemoDataInitializerService({
    required DataRepository<AppSettings> appSettingsRepository,
    required DataRepository<UserContentPreferences>
        userContentPreferencesRepository,
    required DataRepository<Engagement> engagementRepository,
    required DataRepository<Report> reportRepository,
    required DataRepository<AppReview> appReviewRepository,
    required DataRepository<InAppNotification> inAppNotificationRepository,
    required this.appSettingsFixturesData,
    required this.userContentPreferencesFixturesData,
    required this.inAppNotificationsFixturesData,
    required this.engagementFixturesData,
    required this.reportFixturesData,
    required this.appReviewFixturesData,
  })  : _appSettingsRepository = appSettingsRepository,
        _userContentPreferencesRepository = userContentPreferencesRepository,
        _engagementRepository = engagementRepository,
        _reportRepository = reportRepository,
        _appReviewRepository = appReviewRepository,
        _inAppNotificationRepository = inAppNotificationRepository,
        _logger = Logger('DemoDataInitializerService');

  final DataRepository<AppSettings> _appSettingsRepository;
  final DataRepository<UserContentPreferences>
      _userContentPreferencesRepository;
  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final DataRepository<Engagement> _engagementRepository;
  final DataRepository<Report> _reportRepository;
  final DataRepository<AppReview> _appReviewRepository;
  final Logger _logger;

  /// A list of [AppSettings] fixture data to be used as a template.
  ///
  /// The first item in this list will be cloned for new users.
  final List<AppSettings> appSettingsFixturesData;

  /// A list of [UserContentPreferences] fixture data to be used as a template.
  ///
  /// The first item in this list will be cloned for new users.
  final List<UserContentPreferences> userContentPreferencesFixturesData;

  /// A list of [InAppNotification] fixture data to be used as a template.
  ///
  /// All items in this list will be cloned for new users.
  final List<InAppNotification> inAppNotificationsFixturesData;

  /// A list of [Engagement] fixture data to be used as a template.
  final List<Engagement> engagementFixturesData;

  /// A list of [Report] fixture data to be used as a template.
  final List<Report> reportFixturesData;

  /// A list of [AppReview] fixture data to be used as a template.
  final List<AppReview> appReviewFixturesData;

  /// Initializes essential user-specific data in the in-memory clients
  /// for the given [user].
  ///
  /// This method checks if [AppSettings] and [UserContentPreferences]
  /// exist for the provided user ID. If any are missing, it creates them
  /// with default values.
  ///
  /// This prevents "READ FAILED" errors when the application attempts to
  /// access these user-specific data points for a newly signed-in anonymous
  /// user in the demo environment.
  Future<void> initializeUserSpecificData(User user) async {
    _logger.info('Initializing user-specific data for user ID: ${user.id}');

    await Future.wait([
      _ensureAppSettingsExist(user.id),
      _ensureUserContentPreferencesExist(user.id),
      _ensureInAppNotificationsExist(user.id),
      _ensureEngagementsExist(user.id),
      _ensureReportsExist(user.id),
      _ensureAppReviewsExist(user.id),
    ]);

    _logger.info(
      'User-specific data initialization completed for user ID: ${user.id}',
    );
  }

  /// Ensures that [AppSettings] exist for the given [userId].
  /// If not found, creates default settings.
  Future<void> _ensureAppSettingsExist(String userId) async {
    try {
      await _appSettingsRepository.read(id: userId, userId: userId);
      _logger.info('AppSettings found for user ID: $userId.');
    } on NotFoundException {
      _logger.info(
        'AppSettings not found for user ID: '
        '$userId. Creating settings from fixture.',
      );
      // Clone the first item from the fixture data, assigning the new user's ID.
      // This ensures every new demo user gets a rich, pre-populated set of settings.
      if (appSettingsFixturesData.isEmpty) {
        throw StateError(
          'Cannot create settings from fixture: appSettingsFixturesData is empty.',
        );
      }
      final fixtureSettings = appSettingsFixturesData.first.copyWith(
        id: userId,
      );

      await _appSettingsRepository.create(
        item: fixtureSettings,
        userId: userId,
      );
      _logger.info(
        'AppSettings from fixture created for '
        'user ID: $userId.',
      );
    } catch (e, s) {
      _logger.severe(
        'Error ensuring AppSettings exist '
        'for user ID: $userId: $e',
        e,
        s,
      );
      rethrow;
    }
  }

  /// Ensures that [UserContentPreferences] exist for the given [userId].
  /// If not found, creates default preferences.
  Future<void> _ensureUserContentPreferencesExist(String userId) async {
    try {
      await _userContentPreferencesRepository.read(id: userId, userId: userId);
      _logger.info('UserContentPreferences found for user ID: $userId.');
    } on NotFoundException {
      _logger.info(
        'UserContentPreferences not found for '
        'user ID: $userId. Creating preferences from fixture.',
      );
      // Clone the first item from the fixture data, assigning the new user's ID.
      // This provides new demo users with pre-populated saved filters and other preferences.
      if (userContentPreferencesFixturesData.isEmpty) {
        throw StateError(
          'Cannot create preferences from fixture: userContentPreferencesFixturesData is empty.',
        );
      }
      final fixturePreferences =
          userContentPreferencesFixturesData.first.copyWith(id: userId);

      await _userContentPreferencesRepository.create(
        item: fixturePreferences,
        userId: userId,
      );
      _logger.info(
        'UserContentPreferences from fixture created '
        'for user ID: $userId.',
      );
    } catch (e, s) {
      _logger.severe(
        'Error ensuring UserContentPreferences '
        'exist for user ID: $userId: $e',
        e,
        s,
      );
      rethrow;
    }
  }

  /// Ensures that [InAppNotification]s exist for the given [userId].
  ///
  /// This method clones all notifications from the fixture data, assigns the
  /// new user's ID to each one, and creates them in the in-memory repository.
  /// This provides new demo users with a pre-populated notification center.
  Future<void> _ensureInAppNotificationsExist(String userId) async {
    try {
      // Check if notifications already exist for this user.
      final existingNotifications = await _inAppNotificationRepository.readAll(
        userId: userId,
      );
      if (existingNotifications.items.isNotEmpty) {
        _logger.info('InAppNotifications already exist for user ID: $userId.');
        return;
      }

      _logger.info(
        'No InAppNotifications found for user ID: $userId. Creating from fixture.',
      );

      if (inAppNotificationsFixturesData.isEmpty) {
        _logger.warning(
          'inAppNotificationsFixturesData is empty. No notifications to create.',
        );
        return;
      }

      // Exclude the first notification, which will be used for the simulated push.
      final notificationsToCreate =
          inAppNotificationsFixturesData.skip(1).toList();

      final userNotifications =
          notificationsToCreate.map((n) => n.copyWith(userId: userId)).toList();

      await Future.wait(
        userNotifications.map(
          (n) => _inAppNotificationRepository.create(item: n, userId: userId),
        ),
      );
      _logger.info(
        '${userNotifications.length} InAppNotifications from fixture created for user ID: $userId.',
      );
    } catch (e, s) {
      _logger.severe(
        'Error ensuring InAppNotifications exist for user ID: $userId: $e',
        e,
        s,
      );
      // We don't rethrow here as failing to create notifications
      // is not a critical failure for the app's startup.
    }
  }

  /// Ensures that [Engagement]s exist for the given [userId].
  Future<void> _ensureEngagementsExist(String userId) async {
    try {
      final existing = await _engagementRepository.readAll(userId: userId);
      if (existing.items.isNotEmpty) {
        _logger.info('Engagements already exist for user ID: $userId.');
        return;
      }

      _logger.info(
        'No Engagements found for user ID: $userId. Creating from fixture.',
      );

      if (engagementFixturesData.isEmpty) {
        _logger.warning('engagementFixturesData is empty. No items to create.');
        return;
      }

      // Filter engagements to only those not belonging to the fixture user.
      final engagementsToCreate = engagementFixturesData
          .where((e) => e.userId != 'fixture_user_id')
          .toList();

      final userItems = engagementsToCreate.map(
        (i) => i.copyWith(userId: userId),
      );

      await Future.wait(
        userItems.map(
          (item) => _engagementRepository.create(item: item, userId: userId),
        ),
      );
      _logger.info(
        '${userItems.length} Engagements from fixture created for user ID: $userId.',
      );
    } catch (e, s) {
      _logger.severe(
        'Error ensuring Engagements exist for user ID: $userId: $e',
        e,
        s,
      );
    }
  }

  /// Ensures that [Report]s exist for the given [userId].
  Future<void> _ensureReportsExist(String userId) async {
    try {
      final existing = await _reportRepository.readAll(userId: userId);
      if (existing.items.isNotEmpty) {
        _logger.info('Reports already exist for user ID: $userId.');
        return;
      }

      _logger.info(
        'No Reports found for user ID: $userId. Creating from fixture.',
      );

      if (reportFixturesData.isEmpty) {
        _logger.warning('reportFixturesData is empty. No items to create.');
        return;
      }

      final userItems = reportFixturesData.map(
        (i) => i.copyWith(reporterUserId: userId),
      );

      await Future.wait(
        userItems.map(
          (item) => _reportRepository.create(item: item, userId: userId),
        ),
      );
      _logger.info(
        '${userItems.length} Reports from fixture created for user ID: $userId.',
      );
    } catch (e, s) {
      _logger.severe(
        'Error ensuring Reports exist for user ID: $userId: $e',
        e,
        s,
      );
    }
  }

  /// Ensures that [AppReview]s exist for the given [userId].
  Future<void> _ensureAppReviewsExist(String userId) async {
    try {
      final existing = await _appReviewRepository.readAll(userId: userId);
      if (existing.items.isNotEmpty) {
        _logger.info('AppReviews already exist for user ID: $userId.');
        return;
      }

      _logger.info(
        'No AppReviews found for user ID: $userId. Creating from fixture.',
      );

      if (appReviewFixturesData.isEmpty) {
        _logger.warning('appReviewFixturesData is empty. No items to create.');
        return;
      }

      final userItems = appReviewFixturesData.map(
        (i) => i.copyWith(userId: userId),
      );

      await Future.wait(
        userItems.map(
          (item) => _appReviewRepository.create(item: item, userId: userId),
        ),
      );
      _logger.info(
        '${userItems.length} AppReviews from fixture created for user ID: $userId.',
      );
    } catch (e, s) {
      _logger.severe(
        'Error ensuring AppReviews exist for user ID: $userId: $e',
        e,
        s,
      );
    }
  }
}
