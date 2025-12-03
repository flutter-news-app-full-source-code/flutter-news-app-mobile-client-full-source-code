import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:logging/logging.dart';

/// {@template demo_data_migration_service}
/// A service responsible for migrating user data (settings and preferences)
/// from an anonymous user ID to a new authenticated user ID in demo mode.
///
/// This service is specifically designed for the in-memory data clients
/// used in the demo environment, as backend APIs typically handle this
/// migration automatically.
/// {@endtemplate}
class DemoDataMigrationService {
  /// {@macro demo_data_migration_service}
  DemoDataMigrationService({
    required DataRepository<AppSettings> appSettingsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required DataRepository<Engagement> engagementRepository,
    required DataRepository<Report> reportRepository,
    required DataRepository<AppReview> appReviewRepository,
  }) : _appSettingsRepository = appSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _engagementRepository = engagementRepository,
       _reportRepository = reportRepository,
       _appReviewRepository = appReviewRepository,
       _logger = Logger('DemoDataMigrationService');

  final DataRepository<AppSettings> _appSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<Engagement> _engagementRepository;
  final DataRepository<Report> _reportRepository;
  final DataRepository<AppReview> _appReviewRepository;
  final Logger _logger;

  /// Migrates user settings and content preferences from an old anonymous
  /// user ID to a new authenticated user ID.
  ///
  /// This operation is designed to be idempotent and resilient to missing
  /// data for the old user ID.
  Future<void> migrateAnonymousData({
    required String oldUserId,
    required String newUserId,
  }) async {
    _logger.info(
      '[DemoDataMigrationService] Attempting to migrate data from '
      'anonymous user ID: $oldUserId to authenticated user ID: $newUserId',
    );

    // Migrate AppSettings
    try {
      final oldSettings = await _appSettingsRepository.read(
        id: oldUserId,
        userId: oldUserId,
      );
      final newSettings = oldSettings.copyWith(id: newUserId);

      try {
        // Attempt to update first (if a default entry already exists)
        await _appSettingsRepository.update(
          id: newUserId,
          item: newSettings,
          userId: newUserId,
        );
      } on NotFoundException {
        // If update fails because item not found, try to create
        try {
          await _appSettingsRepository.create(
            item: newSettings,
            userId: newUserId,
          );
        } on ConflictException {
          // If create fails due to conflict (item was created concurrently),
          // re-attempt update. This handles a race condition.
          await _appSettingsRepository.update(
            id: newUserId,
            item: newSettings,
            userId: newUserId,
          );
        }
      }

      await _appSettingsRepository.delete(id: oldUserId, userId: oldUserId);
      _logger.info(
        '[DemoDataMigrationService] AppSettings migrated successfully '
        'from $oldUserId to $newUserId.',
      );
    } on NotFoundException {
      _logger.info(
        '[DemoDataMigrationService] No AppSettings found for old user ID: '
        '$oldUserId. Skipping migration for settings.',
      );
    } catch (e, s) {
      _logger.severe(
        '[DemoDataMigrationService] Error migrating AppSettings from '
        '$oldUserId to $newUserId: $e',
        e,
        s,
      );
    }

    // Migrate UserContentPreferences
    try {
      final oldPreferences = await _userContentPreferencesRepository.read(
        id: oldUserId,
        userId: oldUserId,
      );
      final newPreferences = oldPreferences.copyWith(id: newUserId);

      try {
        // Attempt to update first (if a default entry already exists)
        await _userContentPreferencesRepository.update(
          id: newUserId,
          item: newPreferences,
          userId: newUserId,
        );
      } on NotFoundException {
        // If update fails because item not found, try to create
        try {
          await _userContentPreferencesRepository.create(
            item: newPreferences,
            userId: newUserId,
          );
        } on ConflictException {
          // If create fails due to conflict (item was created concurrently),
          // re-attempt update. This handles a race condition.
          await _userContentPreferencesRepository.update(
            id: newUserId,
            item: newPreferences,
            userId: newUserId,
          );
        }
      }

      await _userContentPreferencesRepository.delete(
        id: oldUserId,
        userId: oldUserId,
      );
      _logger.info(
        '[DemoDataMigrationService] UserContentPreferences migrated '
        'successfully from $oldUserId to $newUserId.',
      );
    } on NotFoundException {
      _logger.info(
        '[DemoDataMigrationService] No UserContentPreferences found for old '
        'user ID: $oldUserId. Skipping migration for preferences.',
      );
    } catch (e, s) {
      _logger.severe(
        '[DemoDataMigrationService] Error migrating UserContentPreferences '
        'from $oldUserId to $newUserId: $e',
        e,
        s,
      );
    }

    // Migrate Engagements
    try {
      final oldEngagements = await _engagementRepository.readAll(
        userId: oldUserId,
      );
      for (final oldEngagement in oldEngagements.items) {
        final newEngagement = oldEngagement.copyWith(userId: newUserId);
        await _engagementRepository.create(
          item: newEngagement,
          userId: newUserId,
        );
        await _engagementRepository.delete(
          id: oldEngagement.id,
          userId: oldUserId,
        );
      }
      _logger.info(
        '[DemoDataMigrationService] ${oldEngagements.items.length} '
        'engagements migrated successfully from $oldUserId to $newUserId.',
      );
    } catch (e, s) {
      _logger.severe(
        '[DemoDataMigrationService] Error migrating engagements from '
        '$oldUserId to $newUserId: $e',
        e,
        s,
      );
    }

    // Migrate Reports
    try {
      final oldReports = await _reportRepository.readAll(userId: oldUserId);
      for (final oldReport in oldReports.items) {
        final newReport = oldReport.copyWith(reporterUserId: newUserId);
        await _reportRepository.create(item: newReport, userId: newUserId);
        await _reportRepository.delete(id: oldReport.id, userId: oldUserId);
      }
      _logger.info(
        '[DemoDataMigrationService] ${oldReports.items.length} '
        'reports migrated successfully from $oldUserId to $newUserId.',
      );
    } catch (e, s) {
      _logger.severe(
        '[DemoDataMigrationService] Error migrating reports from '
        '$oldUserId to $newUserId: $e',
        e,
        s,
      );
    }

    // Migrate AppReviews
    try {
      final oldAppReviews = await _appReviewRepository.readAll(
        userId: oldUserId,
      );
      for (final oldAppReview in oldAppReviews.items) {
        final newAppReview = oldAppReview.copyWith(userId: newUserId);
        await _appReviewRepository.create(
          item: newAppReview,
          userId: newUserId,
        );
        await _appReviewRepository.delete(
          id: oldAppReview.id,
          userId: oldUserId,
        );
      }
      _logger.info(
        '[DemoDataMigrationService] ${oldAppReviews.items.length} '
        'app reviews migrated successfully from $oldUserId to $newUserId.',
      );
    } catch (e, s) {
      _logger.severe(
        '[DemoDataMigrationService] Error migrating app reviews from '
        '$oldUserId to $newUserId: $e',
        e,
        s,
      );
    }
  }
}
