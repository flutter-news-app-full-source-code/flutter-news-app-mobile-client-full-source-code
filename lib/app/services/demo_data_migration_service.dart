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
  }) : _appSettingsRepository = appSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _logger = Logger('DemoDataMigrationService');

  final DataRepository<AppSettings> _appSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
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
  }
}
