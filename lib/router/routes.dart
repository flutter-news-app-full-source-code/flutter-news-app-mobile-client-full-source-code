/// Defines named constants for route paths and names used throughout the application.
///
/// Using constants helps prevent typos and makes route management easier.
abstract final class Routes {
  // --- Core App Routes (Bottom Navigation) ---
  static const feed = '/feed';
  static const feedName = 'feed';

  // --- Filter Sub-Routes (relative to /feed) ---
  static const feedFilter = 'filter'; // Path: /feed/filter
  static const feedFilterName = 'feedFilter';

  static const feedFilterCategories =
      'categories'; // Path: /feed/filter/categories
  static const feedFilterCategoriesName = 'feedFilterCategories';

  static const feedFilterSources = 'sources'; // Path: /feed/filter/sources
  static const feedFilterSourcesName = 'feedFilterSources';

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
  static const settings = 'settings'; // Relative path
  static const settingsName = 'settings';
  // Notifications is now relative to account
  static const notifications = 'notifications'; // Relative path
  static const notificationsName = 'notifications';

  // --- Entity Details Routes (can be accessed from multiple places) ---
  static const categoryDetails = '/category-details'; // New
  static const categoryDetailsName = 'categoryDetails'; // New
  static const sourceDetails = '/source-details'; // New
  static const sourceDetailsName = 'sourceDetails'; // New

  // --- Authentication Routes ---
  static const authentication = '/authentication';
  static const authenticationName = 'authentication';
  static const forgotPassword = 'forgot-password';
  static const forgotPasswordName = 'forgotPassword';
  static const resetPassword = 'reset-password';
  static const resetPasswordName = 'resetPassword';
  static const confirmEmail = 'confirm-email';
  static const confirmEmailName = 'confirmEmail';
  static const accountLinking = 'linking'; // Query param context, not a path
  static const accountLinkingName = 'accountLinking'; // Name for context

  // routes for email code verification flow
  static const requestCode = 'request-code';
  static const requestCodeName = 'requestCode';
  static const verifyCode = 'verify-code';
  static const verifyCodeName = 'verifyCode';

  // --- Settings Sub-Routes (relative to /account/settings) ---
  static const settingsAppearance = 'appearance';
  static const settingsAppearanceName = 'settingsAppearance';

  // --- Appearance Sub-Routes (relative to /account/settings/appearance) ---
  static const settingsAppearanceTheme =
      'theme'; // Path: /account/settings/appearance/theme
  static const settingsAppearanceThemeName = 'settingsAppearanceTheme';
  static const settingsAppearanceFont =
      'font'; // Path: /account/settings/appearance/font
  static const settingsAppearanceFontName = 'settingsAppearanceFont';

  static const settingsFeed = 'feed';
  static const settingsFeedName = 'settingsFeed';
  static const settingsArticle = 'article';
  static const settingsArticleName = 'settingsArticle';
  static const settingsNotifications = 'notifications';
  static const settingsNotificationsName = 'settingsNotifications';

  // --- Language Settings Sub-Route (relative to /account/settings) ---
  static const settingsLanguage =
      'language'; // Path: /account/settings/language
  static const settingsLanguageName = 'settingsLanguage';

  // Add names for notification sub-selection routes if needed later
  // static const settingsNotificationCategories = 'categories';
  // static const settingsNotificationCategoriesName = 'settingsNotificationCategories';

  // --- Account Sub-Routes (relative to /account) ---
  static const manageFollowedItems = 'manage-followed-items'; // Renamed
  static const manageFollowedItemsName = 'manageFollowedItems'; // Renamed
  static const accountSavedHeadlines = 'saved-headlines';
  static const accountSavedHeadlinesName = 'accountSavedHeadlines';
  // New route for article details from saved headlines
  static const String accountArticleDetails =
      'article/:id'; // Relative to accountSavedHeadlines
  static const String accountArticleDetailsName = 'accountArticleDetails';

  // --- Manage Followed Items Sub-Routes (relative to /account/manage-followed-items) ---
  static const followedCategoriesList = 'categories';
  static const followedCategoriesListName = 'followedCategoriesList';
  static const addCategoryToFollow = 'add-category';
  static const addCategoryToFollowName = 'addCategoryToFollow';

  static const followedSourcesList = 'sources';
  static const followedSourcesListName = 'followedSourcesList';
  static const addSourceToFollow = 'add-source';
  static const addSourceToFollowName = 'addSourceToFollow';

  static const followedCountriesList = 'countries';
  static const followedCountriesListName = 'followedCountriesList';
  static const addCountryToFollow = 'add-country';
  static const addCountryToFollowName = 'addCountryToFollow';
}
