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
  static const account = '/account';
  static const accountName = 'account';
  static const discover = '/discover';
  static const discoverName = 'discover';

  // --- Global, Top-Level Routes ---
  static const entityDetails = '/entity-details/:type/:id';
  static const entityDetailsName = 'entityDetails';
  static const globalArticleDetails = '/article/:id';
  static const globalArticleDetailsName = 'globalArticleDetails';

  // --- Account Sub-Routes ---
  static const accountSavedHeadlines = 'saved-headlines';
  static const accountSavedHeadlinesName = 'accountSavedHeadlines';
  static const settings = 'settings';
  static const settingsName = 'settings';
  static const manageFollowedItems = 'manage-followed-items';
  static const manageFollowedItemsName = 'manageFollowedItems';

  // --- Relative Sub-Routes ---
  // These routes are defined with relative paths and are intended to be
  // nested within other routes.

  // Generic
  static const multiSelectSearchName = 'multiSelectSearch';

  // Feed
  static const articleDetailsName = 'articleDetails';
  static const notifications = 'notifications';
  static const notificationsName = 'notifications';
  static const feedFilter = 'filter';
  static const feedFilterName = 'feedFilter';
  static const feedFilterTopics = 'topics';
  static const feedFilterTopicsName = 'feedFilterTopics';
  static const feedFilterSources = 'sources';
  static const feedFilterSourcesName = 'feedFilterSources';
  static const sourceListFilterName = 'sourceListFilter';
  static const feedFilterEventCountries = 'event-countries';
  static const feedFilterEventCountriesName = 'feedFilterEventCountries';
  static const savedHeadlineFilters = 'saved-headline-filters';
  static const savedHeadlineFiltersName = 'savedHeadlineFilters';

  // Discover
  static const sourceList = 'source-list/:sourceType';
  static const sourceListName = 'sourceList';
  static const sourceListFilter = 'filter';
  static const discoverSourceListFilterName = 'discoverSourceListFilter';

  // Account
  static const accountArticleDetails = 'article/:id';
  static const accountArticleDetailsName = 'accountArticleDetails';

  // Settings
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

  // Manage Followed Items
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
