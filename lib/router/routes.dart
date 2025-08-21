/// Defines named constants for route paths and names used throughout the application.
///
/// Using constants helps prevent typos and makes route management easier.
abstract final class Routes {
  // --- Core App Routes (Bottom Navigation) ---
  static const feed = '/feed';
  static const feedName = 'feed';

  // --- Filter Sub-Routes (relative to /feed) ---
  static const feedFilter = 'filter';
  static const feedFilterName = 'feedFilter';

  static const feedFilterTopics = 'topics';
  static const feedFilterTopicsName = 'feedFilterTopics';

  static const feedFilterSources = 'sources';
  static const feedFilterSourcesName = 'feedFilterSources';

  // New routes for country filtering
  static const feedFilterEventCountries = 'event-countries';
  static const feedFilterEventCountriesName = 'feedFilterEventCountries';

  static const search = '/search';
  static const searchName = 'search';
  static const account = '/account';
  static const accountName = 'account';

  // --- Sub Routes ---
  // Article details is now relative to feed
  static const articleDetailsName = 'articleDetails';
  // Add a new name for article details when accessed from search
  static const searchArticleDetailsName = 'searchArticleDetails';
  // Settings is now relative to account
  static const settings = 'settings';
  static const settingsName = 'settings';
  // Notifications is now relative to account
  static const notifications = 'notifications';
  static const notificationsName = 'notifications';

  // --- Entity Details Routes (can be accessed from multiple places) ---
  static const topicDetails = '/topic-details';
  static const topicDetailsName = 'topicDetails';
  static const sourceDetails = '/source-details';
  static const sourceDetailsName = 'sourceDetails';
  static const countryDetails = '/country-details';
  static const countryDetailsName = 'countryDetails';

  // --- Authentication Routes ---
  static const authentication = '/authentication';
  static const authenticationName = 'authentication';
  static const forgotPassword = 'forgot-password';
  static const forgotPasswordName = 'forgotPassword';
  static const resetPassword = 'reset-password';
  static const resetPasswordName = 'resetPassword';
  static const confirmEmail = 'confirm-email';
  static const confirmEmailName = 'confirmEmail';
  static const accountLinking = 'linking';
  static const accountLinkingName = 'accountLinking';

  // routes for email code verification flow
  static const requestCode = 'request-code';
  static const requestCodeName = 'requestCode';
  static const verifyCode = 'verify-code';
  static const verifyCodeName = 'verifyCode';

  // Linking-specific authentication routes
  static const linkingRequestCode = 'linking/request-code';
  static const linkingRequestCodeName = 'linkingRequestCode';
  static const linkingVerifyCode = 'linking/verify-code';
  static const linkingVerifyCodeName = 'linkingVerifyCode';

  // --- Settings Sub-Routes (relative to /account/settings) ---
  static const settingsAppearance = 'appearance';
  static const settingsAppearanceName = 'settingsAppearance';

  // --- Appearance Sub-Routes (relative to /account/settings/appearance) ---
  static const settingsAppearanceTheme = 'theme';
  static const settingsAppearanceThemeName = 'settingsAppearanceTheme';
  static const settingsAppearanceFont = 'font';
  static const settingsAppearanceFontName = 'settingsAppearanceFont';

  static const settingsFeed = 'feed';
  static const settingsFeedName = 'settingsFeed';
  static const settingsArticle = 'article';
  static const settingsArticleName = 'settingsArticle';
  static const settingsNotifications = 'notifications';
  static const settingsNotificationsName = 'settingsNotifications';

  // --- Language Settings Sub-Route (relative to /account/settings) ---
  static const settingsLanguage = 'language';
  static const settingsLanguageName = 'settingsLanguage';

  // Add names for notification sub-selection routes if needed later
  // static const settingsNotificationCategories = 'categories';
  // static const settingsNotificationCategoriesName = 'settingsNotificationCategories';

  // --- Account Sub-Routes (relative to /account) ---
  static const manageFollowedItems = 'manage-followed-items';
  static const manageFollowedItemsName = 'manageFollowedItems';
  static const accountSavedHeadlines = 'saved-headlines';
  static const accountSavedHeadlinesName = 'accountSavedHeadlines';
  // New route for article details from saved headlines
  static const String accountArticleDetails = 'article/:id';
  static const String accountArticleDetailsName = 'accountArticleDetails';

  // --- Global Article Details ---
  // This route is intended for accessing article details from contexts
  // outside the main bottom navigation shell (e.g., from entity detail pages).
  static const globalArticleDetails = '/article/:id';
  static const globalArticleDetailsName = 'globalArticleDetails';

  // --- Manage Followed Items Sub-Routes (relative to /account/manage-followed-items) ---
  static const followedTopicsList = 'topics';
  static const followedTopicsListName = 'followedTopicsList';
  static const addTopicToFollow = 'add-topic';
  static const addTopicToFollowName = 'addTopicToFollow';

  static const followedSourcesList = 'sources';
  static const followedSourcesListName = 'followedSourcesList';
  static const addSourceToFollow = 'add-source';
  static const addSourceToFollowName = 'addSourceToFollow';

  // static const followedCountriesList = 'countries';
  // static const followedCountriesListName = 'followedCountriesList';
  // static const addCountryToFollow = 'add-country';
  // static const addCountryToFollowName = 'addCountryToFollow';
}
