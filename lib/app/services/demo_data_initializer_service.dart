import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:logging/logging.dart';

/// {@template demo_data_initializer_service}
/// A service responsible for ensuring that essential user-specific data
/// (like [UserAppSettings] and [UserContentPreferences]) exists for a new user
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
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required this.userAppSettingsFixturesData,
    required this.userContentPreferencesFixturesData,
  }) : _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _logger = Logger('DemoDataInitializerService');

  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final Logger _logger;

  /// A list of [UserAppSettings] fixture data to be used as a template.
  ///
  /// The first item in this list will be cloned for new users.
  final List<UserAppSettings> userAppSettingsFixturesData;

  /// A list of [UserContentPreferences] fixture data to be used as a template.
  ///
  /// The first item in this list will be cloned for new users.
  final List<UserContentPreferences> userContentPreferencesFixturesData;

  /// Initializes essential user-specific data in the in-memory clients
  /// for the given [user].
  ///
  /// This method checks if [UserAppSettings] and [UserContentPreferences]
  /// exist for the provided user ID. If any are missing, it creates them
  /// with default values.
  ///
  /// This prevents "READ FAILED" errors when the application attempts to
  /// access these user-specific data points for a newly signed-in anonymous
  /// user in the demo environment.
  Future<void> initializeUserSpecificData(User user) async {
    _logger.info('Initializing user-specific data for user ID: ${user.id}');

    await Future.wait([
      _ensureUserAppSettingsExist(user.id),
      _ensureUserContentPreferencesExist(user.id),
    ]);

    _logger.info(
      'User-specific data initialization completed for user ID: ${user.id}',
    );
  }

  /// Ensures that [UserAppSettings] exist for the given [userId].
  /// If not found, creates default settings.
  Future<void> _ensureUserAppSettingsExist(String userId) async {
    try {
      await _userAppSettingsRepository.read(id: userId, userId: userId);
      _logger.info('UserAppSettings found for user ID: $userId.');
    } on NotFoundException {
      _logger.info(
        'UserAppSettings not found for user ID: '
        '$userId. Creating settings from fixture.',
      );
      // Clone the first item from the fixture data, assigning the new user's ID.
      // This ensures every new demo user gets a rich, pre-populated set of settings.
      if (userAppSettingsFixturesData.isEmpty) {
        throw StateError(
          'Cannot create settings from fixture: userAppSettingsFixturesData is empty.',
        );
      }
      final fixtureSettings = userAppSettingsFixturesData.first.copyWith(
        id: userId,
      );

      await _userAppSettingsRepository.create(
        item: fixtureSettings,
        userId: userId,
      );
      _logger.info(
        'UserAppSettings from fixture created for '
        'user ID: $userId.',
      );
    } catch (e, s) {
      _logger.severe(
        'Error ensuring UserAppSettings exist '
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
      final fixturePreferences = userContentPreferencesFixturesData.first
          .copyWith(id: userId);

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
}
