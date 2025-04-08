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

  static const feedFilterCountries =
      'countries'; // Path: /feed/filter/countries
  static const feedFilterCountriesName = 'feedFilterCountries';

  static const search = '/search';
  static const searchName = 'search';
  static const account = '/account';
  static const accountName = 'account';

  // --- Sub Routes ---
  // Article details is now relative to feed
  static const articleDetailsName = 'articleDetails';
  // Settings is now relative to account
  static const settings = 'settings'; // Relative path
  static const settingsName = 'settings';
  // Notifications is now relative to account
  static const notifications = 'notifications'; // Relative path
  static const notificationsName = 'notifications';

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

  // routes for email sign-in flow
  static const emailSignIn = 'email-sign-in';
  static const emailSignInName = 'emailSignIn';
  static const emailLinkSent = 'email-link-sent';
  static const emailLinkSentName = 'emailLinkSent';
}
