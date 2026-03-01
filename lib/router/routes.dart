/// Defines named constants for route paths and names used throughout the application.
///
/// Using constants helps prevent typos and makes route management more robust.
abstract final class Routes {
  // --- Onboarding Routes ---
  static const appTour = '/app-tour';
  static const appTourName = 'appTour';
  static const initialPersonalization = '/initial-personalization';
  static const initialPersonalizationName = 'initialPersonalization';

  // --- Authentication Routes ---
  static const authentication = '/authentication';
  static const authenticationName = 'authentication';
  static const accountLinking = '/account-linking';
  static const accountLinkingName = 'accountLinking';

  // Shared Auth Sub-Routes
  static const requestCode = 'request-code';
  static const requestCodeName = 'requestCode';
  static const verifyCode = 'verify-code';
  static const verifyCodeName = 'verifyCode';

  // Account Linking Specific Names (reusing paths)
  static const accountLinkingRequestCodeName = 'accountLinkingRequestCode';
  static const accountLinkingVerifyCodeName = 'accountLinkingVerifyCode';

  // --- Core App Shell Routes ---
  static const feed = '/feed';
  static const feedName = 'feed';

  // --- Feed Sub-Routes ---
  static const savedHeadlineFilters = 'saved-headline-filters';
  static const savedHeadlineFiltersName = 'savedHeadlineFilters';
  static const feedFilter = 'filter';
  static const feedFilterName = 'feedFilter';

  // --- Account & Settings Routes ---
  static const account = '/account';
  static const accountName = 'account';

  // Account Sub-Routes
  static const rewards = 'rewards';
  static const rewardsName = 'rewards';
  static const editProfile = 'edit-profile';
  static const editProfileName = 'editProfile';
  static const notificationsCenter = 'notifications-center';
  static const notificationsCenterName = 'notificationsCenter';
  static const manageFollowedItems = 'manage-followed-items';
  static const manageFollowedItemsName = 'manageFollowedItems';
  static const accountSavedHeadlines = 'saved-headlines';
  static const accountSavedHeadlinesName = 'accountSavedHeadlines';

  // Settings Sub-Routes
  static const settings = 'settings';
  static const settingsName = 'settings';
  static const settingsAccentColorAndFonts = 'theme-and-font';
  static const settingsAccentColorAndFontsName = 'settingsAccentColorAndFonts';
  static const settingsFeed = 'feed';
  static const settingsFeedName = 'settingsFeed';

  // --- Global / Shared Routes ---
  static const entityDetails = '/entity-details/:type/:id';
  static const entityDetailsName = 'entityDetails';
}
