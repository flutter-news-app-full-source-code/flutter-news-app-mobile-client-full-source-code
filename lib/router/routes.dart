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
  static const accountSavedHeadlines = 'saved-headlines';
  static const accountSavedHeadlinesName = 'accountSavedHeadlines';
  static const entityDetails = '/entity-details/:type/:id';
  static const entityDetailsName = 'entityDetails';
  static const settings = 'settings';
  static const settingsName = 'settings';
  static const manageFollowedItems = 'manage-followed-items';
  static const manageFollowedItemsName = 'manageFollowedItems';
  static const notificationsCenter = 'notifications-center';
  static const notificationsCenterName = 'notificationsCenter';
  static const rewards = 'rewards';
  static const rewardsName = 'rewards';
  static const editProfile = 'edit-profile';
  static const editProfileName = 'editProfile';

  // --- Onboarding Routes ---
  static const appTour = '/app-tour';
  static const appTourName = 'appTour';
  static const initialPersonalization = '/initial-personalization';
  static const initialPersonalizationName = 'initialPersonalization';

  // --- Relative Sub-Routes ---
  // These routes are defined with relative paths and are intended to be
  // nested within other routes.

  // --- Generic, Top-Level Routes ---
  static const multiSelectSearchName = 'multiSelectSearch';

  // --- Feed Sub-Routes ---
  static const feedFilter = 'filter';
  static const feedFilterName = 'feedFilter';
  static const savedHeadlineFilters = 'saved-headline-filters';
  static const savedHeadlineFiltersName = 'savedHeadlineFilters';
  static const engagement = 'engagement/:headlineId';
  static const engagementName = 'engagement';

  // --- Discover Sub-Routes ---
  static const sourceList = 'source-list/:sourceType';
  static const sourceListName = 'sourceList';
  static const sourceListFilter = 'filter';
  static const discoverSourceListFilterName = 'discoverSourceListFilter';

  // --- Settings Sub-Routes ---
  static const settingsAccentColorAndFonts = 'theme-and-font';
  static const settingsAccentColorAndFontsName = 'settingsAccentColorAndFonts';
  static const settingsFeed = 'feed';
  static const settingsFeedName = 'settingsFeed';
  static const settingsArticle = 'article';
  static const settingsArticleName = 'settingsArticle';
  static const settingsLanguage = 'language';
  static const settingsLanguageName = 'settingsLanguage';

  // --- Manage Followed Items Sub-Routes ---
  static const followedTopicsList = 'topics';
  static const followedTopicsListName = 'followedTopicsList';
}
