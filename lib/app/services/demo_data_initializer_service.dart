import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:logging/logging.dart'; // Import Logger

/// {@template demo_data_initializer_service}
/// A service responsible for ensuring that essential user-specific data
/// (like [UserAppSettings] and [UserContentPreferences]) exists in the
/// data in-memory clients when a user is first encountered in the demo environment.
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
  }) : _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _logger = Logger('DemoDataInitializerService'); // Initialize logger

  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final Logger _logger; // Add logger instance

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
        '$userId. Creating default settings.',
      );
      final defaultSettings = UserAppSettings(
        id: userId,
        displaySettings: const DisplaySettings(
          baseTheme: AppBaseTheme.system,
          accentTheme: AppAccentTheme.defaultBlue,
          fontFamily: 'SystemDefault',
          textScaleFactor: AppTextScaleFactor.medium,
          fontWeight: AppFontWeight.regular,
        ),
        language: languagesFixturesData.firstWhere(
          (l) => l.code == 'en',
          orElse: () => throw StateError(
            'Default language "en" not found in language fixtures.',
          ),
        ),
        feedPreferences: const FeedDisplayPreferences(
          headlineDensity: HeadlineDensity.standard,
          headlineImageStyle: HeadlineImageStyle.smallThumbnail,
          showSourceInHeadlineFeed: true,
          showPublishDateInHeadlineFeed: true,
        ),
      );
      await _userAppSettingsRepository.create(
        item: defaultSettings,
        userId: userId,
      );
      _logger.info(
        'Default UserAppSettings created for '
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
        'user ID: $userId. Creating default preferences.',
      );
      final defaultPreferences = UserContentPreferences(
        id: userId,
        followedCountries: const [],
        followedSources: const [],
        followedTopics: const [],
        savedHeadlines: const [],
      );
      await _userContentPreferencesRepository.create(
        item: defaultPreferences,
        userId: userId,
      );
      _logger.info(
        'Default UserContentPreferences created '
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
