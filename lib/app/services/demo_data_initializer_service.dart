import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart'; // Required for ThemeMode, AppBaseTheme, etc.

/// {@template demo_data_initializer_service}
/// A service responsible for ensuring that essential user-specific data
/// (like [UserAppSettings], [UserContentPreferences], and the [User] object
/// itself) exists in the data in-memory clients when a user is first encountered
/// in the demo environment.
///
/// This service is specifically designed for the in-memory data clients
/// used in the demo environment. In production/development environments,
/// the backend API is responsible for initializing user data.
/// {@endtemplate}
class DemoDataInitializerService {
  /// {@macro demo_data_initializer_service}
  const DemoDataInitializerService({
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<UserContentPreferences>
        userContentPreferencesRepository,
    required DataRepository<User> userRepository,
  })  : _userAppSettingsRepository = userAppSettingsRepository,
        _userContentPreferencesRepository = userContentPreferencesRepository,
        _userRepository = userRepository;

  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
      _userContentPreferencesRepository;
  final DataRepository<User> _userRepository;

  /// Initializes essential user-specific data in the in-memory clients
  /// for the given [user].
  ///
  /// This method checks if [UserAppSettings], [UserContentPreferences],
  /// and the [User] object itself exist for the provided user ID. If any
  /// are missing, it creates them with default values.
  ///
  /// This prevents "READ FAILED" errors when the application attempts to
  /// access these user-specific data points for a newly signed-in anonymous
  /// user in the demo environment.
  Future<void> initializeUserSpecificData(User user) async {
    print(
      '[DemoDataInitializerService] Initializing user-specific data for '
      'user ID: ${user.id}',
    );

    // Ensure UserAppSettings exist
    await _ensureUserAppSettingsExist(user.id);

    // Ensure UserContentPreferences exist
    await _ensureUserContentPreferencesExist(user.id);

    // Ensure the User object itself is up-to-date in the user client
    await _ensureUserClientUserExists(user);

    print(
      '[DemoDataInitializerService] User-specific data initialization '
      'completed for user ID: ${user.id}',
    );
  }

  /// Ensures that [UserAppSettings] exist for the given [userId].
  /// If not found, creates default settings.
  Future<void> _ensureUserAppSettingsExist(String userId) async {
    try {
      await _userAppSettingsRepository.read(id: userId, userId: userId);
      print(
        '[DemoDataInitializerService] UserAppSettings found for user ID: $userId.',
      );
    } on NotFoundException {
      print(
        '[DemoDataInitializerService] UserAppSettings not found for user ID: '
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
      await _userAppSettingsRepository.create(item: defaultSettings, userId: userId);
      print(
        '[DemoDataInitializerService] Default UserAppSettings created for '
        'user ID: $userId.',
      );
    } catch (e, s) {
      print(
        '[DemoDataInitializerService] Error ensuring UserAppSettings exist '
        'for user ID: $userId: $e\n$s',
      );
      rethrow;
    }
  }

  /// Ensures that [UserContentPreferences] exist for the given [userId].
  /// If not found, creates default preferences.
  Future<void> _ensureUserContentPreferencesExist(String userId) async {
    try {
      await _userContentPreferencesRepository.read(id: userId, userId: userId);
      print(
        '[DemoDataInitializerService] UserContentPreferences found for user ID: $userId.',
      );
    } on NotFoundException {
      print(
        '[DemoDataInitializerService] UserContentPreferences not found for '
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
      print(
        '[DemoDataInitializerService] Default UserContentPreferences created '
        'for user ID: $userId.',
      );
    } catch (e, s) {
      print(
        '[DemoDataInitializerService] Error ensuring UserContentPreferences '
        'exist for user ID: $userId: $e\n$s',
      );
      rethrow;
    }
  }

  /// Ensures that the [User] object for the given [user] exists in the
  /// user client. If not found, creates it. If found, updates it.
  ///
  /// This is important because the `AuthInmemory` client might create a
  /// basic user, but the `DataInMemory<User>` client might not have it
  /// immediately.
  Future<void> _ensureUserClientUserExists(User user) async {
    try {
      await _userRepository.read(id: user.id, userId: user.id);
      // If user exists, ensure it's up-to-date (e.g., if roles changed)
      await _userRepository.update(id: user.id, item: user, userId: user.id);
      print(
        '[DemoDataInitializerService] User object found and updated in '
        'user client for ID: ${user.id}.',
      );
    } on NotFoundException {
      print(
        '[DemoDataInitializerService] User object not found in user client '
        'for ID: ${user.id}. Creating it.',
      );
      await _userRepository.create(item: user, userId: user.id);
      print(
        '[DemoDataInitializerService] User object created in user client '
        'for ID: ${user.id}.',
      );
    } catch (e, s) {
      print(
        '[DemoDataInitializerService] Error ensuring User object exists in '
        'user client for ID: ${user.id}: $e\n$s',
      );
      rethrow;
    }
  }
}
