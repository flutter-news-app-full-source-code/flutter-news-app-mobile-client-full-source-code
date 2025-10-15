/// Defines named constants for route paths and names used throughout the application.
///
/// Using constants helps prevent typos and makes route management more robust.
abstract final class Routes {
  // --- Authentication Routes ---
  static const authentication = '/authentication';
  static const authenticationName = 'authentication';
  static const accountLinking = '/account-linking';
  static const accountLinkingName = 'accountLinking';
  static const requestCode = 'request-code';
  static const requestCodeName = 'requestCode';
  static const verifyCode = 'verify-code';
  static const verifyCodeName = 'verifyCode';
  static const accountLinkingRequestCodeName = 'accountLinkingRequestCode';
  static const accountLinkingVerifyCodeName = 'accountLinkingVerifyCode';

  // --- Core App Shell Routes ---
  static const feed = '/feed';
  static const feedName = 'feed';
  static const search = '/search';
  static const searchName = 'search';
  static const account = '/account';
  static const accountName = 'account';

  // --- Global, Top-Level Routes ---
  static const entityDetails = '/entity-details/:type/:id';
  static const entityDetailsName = 'entityDetails';
  static const globalArticleDetails = '/article/:id';
  static const globalArticleDetailsName = 'globalArticleDetails';

  // --- Feed Sub-Routes ---
  static const articleDetailsName = 'articleDetails';
  static const notifications = 'notifications';
  static const notificationsName = 'notifications';

  // --- Feed Filter Sub-Routes ---
  static const feedFilter = 'filter';
  static const feedFilterName = 'feedFilter';
  static const manageSavedFilters = 'manage-saved-filters';
  static const manageSavedFiltersName = 'manageSavedFilters';
  static const feedFilterTopics = 'topics';
  static const feedFilterTopicsName = 'feedFilterTopics';
  static const feedFilterSources = 'sources';
  static const feedFilterSourcesName = 'feedFilterSources';
  static const sourceListFilterName = 'sourceListFilter';
  static const feedFilterEventCountries = 'event-countries';
  static const feedFilterEventCountriesName = 'feedFilterEventCountries';

  // --- Search Sub-Routes ---
  static const searchArticleDetailsName = 'searchArticleDetails';

  // --- Account Sub-Routes ---
  static const accountSavedHeadlines = 'saved-headlines';
  static const accountSavedHeadlinesName = 'accountSavedHeadlines';
  static const accountArticleDetails = 'article/:id';
  static const accountArticleDetailsName = 'accountArticleDetails';

  // --- Settings Routes (nested under Account) ---
  static const settings = 'settings';
  static const settingsName = 'settings';
  static const settingsAppearance = 'appearance';
  static const settingsAppearanceName = 'settingsAppearance';
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
  static const settingsLanguage = 'language';
  static const settingsLanguageName = 'settingsLanguage';

  // --- Manage Followed Items Routes (nested under Account) ---
  static const manageFollowedItems = 'manage-followed-items';
  static const manageFollowedItemsName = 'manageFollowedItems';
  static const followedTopicsList = 'topics';
  static const followedTopicsListName = 'followedTopicsList';
  static const addTopicToFollow = 'add-topic';
  static const addTopicToFollowName = 'addTopicToFollow';
  static const followedSourcesList = 'sources';
  static const followedSourcesListName = 'followedSourcesList';
  static const addSourceToFollow = 'add-source';
  static const addSourceToFollowName = 'addSourceToFollow';
  static const followedCountriesList = 'countries';
  static const followedCountriesListName = 'followedCountriesList';
  static const addCountryToFollow = 'add-country';
  static const addCountryToFollowName = 'addCountryToFollow';
}
