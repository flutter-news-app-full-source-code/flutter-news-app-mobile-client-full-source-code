import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart';

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
  const DemoDataMigrationService({
    required HtDataRepository<UserAppSettings> userAppSettingsRepository,
    required HtDataRepository<UserContentPreferences>
    userContentPreferencesRepository,
  }) : _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository;

  final HtDataRepository<UserAppSettings> _userAppSettingsRepository;
  final HtDataRepository<UserContentPreferences>
  _userContentPreferencesRepository;

  /// Migrates user settings and content preferences from an old anonymous
  /// user ID to a new authenticated user ID.
  ///
  /// This operation is designed to be idempotent and resilient to missing
  /// data for the old user ID.
  Future<void> migrateAnonymousData({
    required String oldUserId,
    required String newUserId,
  }) async {
    print(
      '[DemoDataMigrationService] Attempting to migrate data from '
      'anonymous user ID: $oldUserId to authenticated user ID: $newUserId',
    );

    // Migrate UserAppSettings
    try {
      final oldSettings = await _userAppSettingsRepository.read(
        id: oldUserId,
        userId: oldUserId,
      );
      final newSettings = oldSettings.copyWith(id: newUserId);

      try {
        // Attempt to update first (if a default entry already exists)
        await _userAppSettingsRepository.update(
          id: newUserId,
          item: newSettings,
          userId: newUserId,
        );
      } on NotFoundException {
        // If update fails because item not found, try to create
        try {
          await _userAppSettingsRepository.create(
            item: newSettings,
            userId: newUserId,
          );
        } on ConflictException {
          // If create fails due to conflict (item was created concurrently),
          // re-attempt update. This handles a race condition.
          await _userAppSettingsRepository.update(
            id: newUserId,
            item: newSettings,
            userId: newUserId,
          );
        }
      }

      await _userAppSettingsRepository.delete(id: oldUserId, userId: oldUserId);
      print(
        '[DemoDataMigrationService] UserAppSettings migrated successfully '
        'from $oldUserId to $newUserId.',
      );
    } on NotFoundException {
      print(
        '[DemoDataMigrationService] No UserAppSettings found for old user ID: '
        '$oldUserId. Skipping migration for settings.',
      );
    } catch (e, s) {
      print(
        '[DemoDataMigrationService] Error migrating UserAppSettings from '
        '$oldUserId to $newUserId: $e\n$s',
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
      print(
        '[DemoDataMigrationService] UserContentPreferences migrated '
        'successfully from $oldUserId to $newUserId.',
      );
    } on NotFoundException {
      print(
        '[DemoDataMigrationService] No UserContentPreferences found for old '
        'user ID: $oldUserId. Skipping migration for preferences.',
      );
    } catch (e, s) {
      print(
        '[DemoDataMigrationService] Error migrating UserContentPreferences '
        'from $oldUserId to $newUserId: $e\n$s',
      );
    }
  }
}