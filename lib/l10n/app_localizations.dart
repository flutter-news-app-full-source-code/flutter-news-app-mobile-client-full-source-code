import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Title for the account linking page
  ///
  /// In en, this message translates to:
  /// **'Link Your Account'**
  String get accountLinkingPageTitle;

  /// Generic error message shown during account linking
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get accountLinkingGenericError;

  /// Success message shown after sending an email sign-in link
  ///
  /// In en, this message translates to:
  /// **'Check your email for the sign-in link!'**
  String get accountLinkingEmailSentSuccess;

  /// Headline text on the account linking page
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get accountLinkingHeadline;

  /// Body text explaining the benefits of linking an account
  ///
  /// In en, this message translates to:
  /// **'Signing up allows you to access your information across multiple devices and ensures your progress isn\'t lost.'**
  String get accountLinkingBody;

  /// Text for the Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get accountLinkingContinueWithGoogleButton;

  /// Label for the email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get accountLinkingEmailInputLabel;

  /// Hint text for the email input field
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get accountLinkingEmailInputHint;

  /// Validation error message for the email input field
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get accountLinkingEmailValidationError;

  /// Text for the button that sends an email sign-in link
  ///
  /// In en, this message translates to:
  /// **'Send Sign-In Link'**
  String get accountLinkingSendLinkButton;

  /// Title for the account page
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountPageTitle;

  /// Display name shown for an anonymous user
  ///
  /// In en, this message translates to:
  /// **'(Anonymous)'**
  String get accountAnonymousUser;

  /// Default display name shown when user has no name set
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get accountNoNameUser;

  /// Text indicating the user is fully authenticated
  ///
  /// In en, this message translates to:
  /// **'Authenticated'**
  String get accountStatusAuthenticated;

  /// Text indicating the user is in an anonymous session
  ///
  /// In en, this message translates to:
  /// **'Anonymous Session'**
  String get accountStatusAnonymous;

  /// Text indicating the user is not signed in
  ///
  /// In en, this message translates to:
  /// **'Not Signed In'**
  String get accountStatusUnauthenticated;

  /// Title for the settings navigation tile
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettingsTile;

  /// Title for the sign out action tile
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get accountSignOutTile;

  /// Title for the tile prompting anonymous users to create an account
  ///
  /// In en, this message translates to:
  /// **'Create Account to Save Data'**
  String get accountBackupTile;

  /// Title for the content preferences navigation tile in the account page
  ///
  /// In en, this message translates to:
  /// **'Followed content'**
  String get accountContentPreferencesTile;

  /// Title for the saved headlines navigation tile in the account page
  ///
  /// In en, this message translates to:
  /// **'Saved Headlines'**
  String get accountSavedHeadlinesTile;

  /// Label displaying the user's role in the account header
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String accountRoleLabel(String role);

  /// Success message shown after sending an email sign-in link on the authentication page
  ///
  /// In en, this message translates to:
  /// **'Check your email for the sign-in link.'**
  String get authenticationEmailSentSuccess;

  /// Title for the main authentication page
  ///
  /// In en, this message translates to:
  /// **'Sign In / Register'**
  String get authenticationPageTitle;

  /// Label for the email input field on the authentication page
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authenticationEmailLabel;

  /// Text for the button that sends an email sign-in link on the authentication page
  ///
  /// In en, this message translates to:
  /// **'Send Sign-In Link'**
  String get authenticationSendLinkButton;

  /// Text used as a separator between sign-in methods
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authenticationOrDivider;

  /// Text for the Google sign-in button on the authentication page
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get authenticationGoogleSignInButton;

  /// Text for the button to continue without signing in
  ///
  /// In en, this message translates to:
  /// **'Continue Anonymously'**
  String get authenticationAnonymousSignInButton;

  /// Headline text shown in the initial state widget on the details page
  ///
  /// In en, this message translates to:
  /// **'Waiting for Headline'**
  String get headlineDetailsInitialHeadline;

  /// Subheadline text shown in the initial state widget on the details page
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get headlineDetailsInitialSubheadline;

  /// Headline text shown in the loading state widget on the details page
  ///
  /// In en, this message translates to:
  /// **'Loading Headline'**
  String get headlineDetailsLoadingHeadline;

  /// Subheadline text shown in the loading state widget on the details page
  ///
  /// In en, this message translates to:
  /// **'Fetching data...'**
  String get headlineDetailsLoadingSubheadline;

  /// Text for the button to open the full article
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get headlineDetailsContinueReadingButton;

  /// Headline text shown in the loading state widget on the feed page
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get headlinesFeedLoadingHeadline;

  /// Subheadline text shown in the loading state widget on the feed page
  ///
  /// In en, this message translates to:
  /// **'Fetching headlines'**
  String get headlinesFeedLoadingSubheadline;

  /// Title for the filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filter Headlines'**
  String get headlinesFeedFilterTitle;

  /// Label for the category filter dropdown
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get headlinesFeedFilterCategoryLabel;

  /// Text for the 'All' option in filter dropdowns
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get headlinesFeedFilterAllOption;

  /// Filter option for Technology category
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get headlinesFeedFilterCategoryTechnology;

  /// Filter option for Business category
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get headlinesFeedFilterCategoryBusiness;

  /// Filter option for Sports category
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get headlinesFeedFilterCategorySports;

  /// Label for the source filter dropdown
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get headlinesFeedFilterSourceLabel;

  /// Filter option for CNN source
  ///
  /// In en, this message translates to:
  /// **'CNN'**
  String get headlinesFeedFilterSourceCNN;

  /// Filter option for Reuters source
  ///
  /// In en, this message translates to:
  /// **'Reuters'**
  String get headlinesFeedFilterSourceReuters;

  /// Filter page label indication where the hadline event has took place
  ///
  /// In en, this message translates to:
  /// **'Country of Event'**
  String get headlinesFeedFilterEventCountryLabel;

  /// Filter page label indication where the headline source is located
  ///
  /// In en, this message translates to:
  /// **'Source Headquarter'**
  String get headlinesFeedFilterSourceCountryLabel;

  /// Filter option for United States
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get headlinesFeedFilterCountryUS;

  /// Filter option for United Kingdom
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get headlinesFeedFilterCountryUK;

  /// Filter option for Canada
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get headlinesFeedFilterCountryCA;

  /// Text for the button to apply selected filters
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get headlinesFeedFilterApplyButton;

  /// Text for the button to reset all filters
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get headlinesFeedFilterResetButton;

  /// Hint text for the search input field
  ///
  /// In en, this message translates to:
  /// **'Search Headlines...'**
  String get headlinesSearchHintText;

  /// Headline text shown in the initial state widget on the search page
  ///
  /// In en, this message translates to:
  /// **'Find Headlines Instantly'**
  String get headlinesSearchInitialHeadline;

  /// Subheadline text shown in the initial state widget on the search page
  ///
  /// In en, this message translates to:
  /// **'Type keywords above to discover news articles.'**
  String get headlinesSearchInitialSubheadline;

  /// Headline text shown when a search yields no results
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get headlinesSearchNoResultsHeadline;

  /// Subheadline text shown when a search yields no results
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get headlinesSearchNoResultsSubheadline;

  /// Button text for initiating email sign-in flow
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get authenticationEmailSignInButton;

  /// Headline for the authentication page when linking an anonymous account
  ///
  /// In en, this message translates to:
  /// **'Sync Your Data'**
  String get authenticationLinkingHeadline;

  /// Subheadline explaining the benefit of linking an anonymous account
  ///
  /// In en, this message translates to:
  /// **'save your settings, content preferences and more across devices.'**
  String get authenticationLinkingSubheadline;

  /// Headline for the authentication page during standard sign-in
  ///
  /// In en, this message translates to:
  /// **'Veritas'**
  String get authenticationSignInHeadline;

  /// Subheadline for the authentication page during standard sign-in
  ///
  /// In en, this message translates to:
  /// **'Unfiltered news from trusted sources around the world.'**
  String get authenticationSignInSubheadline;

  /// AppBar title for the email sign-in page
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get emailSignInPageTitle;

  /// Explanatory text on the email sign-in page
  ///
  /// In en, this message translates to:
  /// **'Enter your email below. We\'ll send you a secure link to sign in instantly. No password required!'**
  String get emailSignInExplanation;

  /// AppBar title for the email link sent confirmation page
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get emailLinkSentPageTitle;

  /// Confirmation message shown after the email link has been sent
  ///
  /// In en, this message translates to:
  /// **'Link sent! Check your email inbox (and spam folder) for a message from us. Click the link inside to complete your sign-in.'**
  String get emailLinkSentConfirmation;

  /// Title for the tile prompting anonymous users to sign in/connect
  ///
  /// In en, this message translates to:
  /// **'Connect Account'**
  String get accountConnectPrompt;

  /// Subtitle explaining the benefit of connecting an anonymous account
  ///
  /// In en, this message translates to:
  /// **'Save your preferences and reading history across devices.'**
  String get accountConnectBenefit;

  /// Label for the Feed item in the bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get bottomNavFeedLabel;

  /// Label for the Search item in the bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get bottomNavSearchLabel;

  /// Label for the Account item in the bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get bottomNavAccountLabel;

  /// Title for the notifications navigation tile in the account page
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get accountNotificationsTile;

  /// Tooltip text for the search icon button in the search page AppBar
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get headlinesSearchActionTooltip;

  /// Tooltip text for the notifications icon button in the feed page AppBar
  ///
  /// In en, this message translates to:
  /// **'View notifications'**
  String get notificationsTooltip;

  /// Button text shown in the user header for anonymous users to initiate sign-in/sign-up
  ///
  /// In en, this message translates to:
  /// **'Sign Up / Sign In'**
  String get accountSignInPromptButton;

  /// Headline for loading state on category filter page
  ///
  /// In en, this message translates to:
  /// **'Loading Categories...'**
  String get categoryFilterLoadingHeadline;

  /// Subheadline for loading state on category filter page
  ///
  /// In en, this message translates to:
  /// **'Please wait while we fetch the available categories.'**
  String get categoryFilterLoadingSubheadline;

  /// Headline for empty state on category filter page
  ///
  /// In en, this message translates to:
  /// **'No Categories Found'**
  String get categoryFilterEmptyHeadline;

  /// Subheadline for empty state on category filter page
  ///
  /// In en, this message translates to:
  /// **'There are no categories available at the moment.'**
  String get categoryFilterEmptySubheadline;

  /// Headline for loading state on country filter page
  ///
  /// In en, this message translates to:
  /// **'Loading Countries...'**
  String get countryFilterLoadingHeadline;

  /// Subheadline for loading state on country filter page
  ///
  /// In en, this message translates to:
  /// **'Please wait while we fetch the available countries.'**
  String get countryFilterLoadingSubheadline;

  /// Headline for empty state on country filter page
  ///
  /// In en, this message translates to:
  /// **'No Countries Found'**
  String get countryFilterEmptyHeadline;

  /// Subheadline for empty state on country filter page
  ///
  /// In en, this message translates to:
  /// **'There are no countries available at the moment.'**
  String get countryFilterEmptySubheadline;

  /// Title displayed in the AppBar of the main headlines feed
  ///
  /// In en, this message translates to:
  /// **'HT'**
  String get headlinesFeedAppBarTitle;

  /// Tooltip for the filter icon button in the feed AppBar
  ///
  /// In en, this message translates to:
  /// **'Filter Headlines'**
  String get headlinesFeedFilterTooltip;

  /// Label indicating 'All' items are selected in a filter tile
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get headlinesFeedFilterAllLabel;

  /// Label showing the number of selected filters (e.g., "5 selected")
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String headlinesFeedFilterSelectedCountLabel(int count);

  /// Headline for loading state on source filter page
  ///
  /// In en, this message translates to:
  /// **'Loading Sources...'**
  String get sourceFilterLoadingHeadline;

  /// Subheadline for loading state on source filter page
  ///
  /// In en, this message translates to:
  /// **'Please wait while we fetch the available sources.'**
  String get sourceFilterLoadingSubheadline;

  /// Headline for empty state on source filter page
  ///
  /// In en, this message translates to:
  /// **'No Sources Found'**
  String get sourceFilterEmptyHeadline;

  /// Subheadline for empty state on source filter page
  ///
  /// In en, this message translates to:
  /// **'There are no sources available at the moment.'**
  String get sourceFilterEmptySubheadline;

  /// Title for the main settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Headline shown while settings are loading
  ///
  /// In en, this message translates to:
  /// **'Loading Settings...'**
  String get settingsLoadingHeadline;

  /// Subheadline shown while settings are loading
  ///
  /// In en, this message translates to:
  /// **'Please wait while we fetch your preferences.'**
  String get settingsLoadingSubheadline;

  /// Default error message when settings fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load settings.'**
  String get settingsErrorDefault;

  /// Title for the appearance settings section/page
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// Title for the feed settings section/page
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get settingsFeedDisplayTitle;

  /// Title for the article display settings section/page
  ///
  /// In en, this message translates to:
  /// **'Article Display'**
  String get settingsArticleDisplayTitle;

  /// Title for the notification settings section/page
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// Label for the light theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsAppearanceThemeModeLight;

  /// Label for the dark theme mode option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsAppearanceThemeModeDark;

  /// Label for the system theme mode option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsAppearanceThemeModeSystem;

  /// Label for the red color scheme option
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get settingsAppearanceThemeNameRed;

  /// Label for the blue color scheme option
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get settingsAppearanceThemeNameBlue;

  /// Label for the grey color scheme option
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get settingsAppearanceThemeNameGrey;

  /// Label for the small font size option
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get settingsAppearanceFontSizeSmall;

  /// Label for the large font size option
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsAppearanceFontSizeLarge;

  /// Label for the medium font size option
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsAppearanceFontSizeMedium;

  /// Label for the theme mode selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsAppearanceThemeModeLabel;

  /// Label for the color scheme selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Color Scheme'**
  String get settingsAppearanceThemeNameLabel;

  /// Label for the app font size selection dropdown
  ///
  /// In en, this message translates to:
  /// **'App Font Size'**
  String get settingsAppearanceAppFontSizeLabel;

  /// Label for the app font selection dropdown
  ///
  /// In en, this message translates to:
  /// **'App Font'**
  String get settingsAppearanceAppFontTypeLabel;

  /// Label for the font weight setting.
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get settingsAppearanceFontWeightLabel;

  /// Label for the feed tile type with image on top
  ///
  /// In en, this message translates to:
  /// **'Image Top'**
  String get settingsFeedTileTypeImageTop;

  /// Label for the feed tile type with image at the start
  ///
  /// In en, this message translates to:
  /// **'Image Start'**
  String get settingsFeedTileTypeImageStart;

  /// Label for the feed tile type with text only
  ///
  /// In en, this message translates to:
  /// **'Text Only'**
  String get settingsFeedTileTypeTextOnly;

  /// Label for the feed tile layout selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Feed Tile Layout'**
  String get settingsFeedTileTypeLabel;

  /// Label for the article font size selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Article Font Size'**
  String get settingsArticleFontSizeLabel;

  /// Label for the switch to enable/disable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get settingsNotificationsEnableLabel;

  /// Label for the section to select notification categories
  ///
  /// In en, this message translates to:
  /// **'Followed Categories'**
  String get settingsNotificationsCategoriesLabel;

  /// Label for the section to select notification sources
  ///
  /// In en, this message translates to:
  /// **'Followed Sources'**
  String get settingsNotificationsSourcesLabel;

  /// Label for the section to select notification countries
  ///
  /// In en, this message translates to:
  /// **'Followed Countries'**
  String get settingsNotificationsCountriesLabel;

  /// Generic error message shown when an operation fails unexpectedly
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;

  /// Error message shown when pagination fails to load the next set of items
  ///
  /// In en, this message translates to:
  /// **'Failed to load more items.'**
  String get loadMoreError;

  /// Label for the extra large font size option
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get settingsAppearanceFontSizeExtraLarge;

  /// Label for the system default font family option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsAppearanceFontFamilySystemDefault;

  /// Title for the theme settings sub-page under appearance
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get settingsAppearanceThemeSubPageTitle;

  /// Title for the font settings sub-page under appearance
  ///
  /// In en, this message translates to:
  /// **'Font Settings'**
  String get settingsAppearanceFontSubPageTitle;

  /// Title for the language settings page/section
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// AppBar title for the email code verification page
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get emailCodeSentPageTitle;

  /// Confirmation message shown after the email code has been sent
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to {email}. Please enter it below.'**
  String emailCodeSentConfirmation(String email);

  /// Instructions for the user to enter the verification code
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code you received.'**
  String get emailCodeSentInstructions;

  /// Hint text for the email code verification input field
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get emailCodeVerificationHint;

  /// Button text for verifying the email code
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get emailCodeVerificationButtonLabel;

  /// Validation error when the email verification code is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code.'**
  String get emailCodeValidationEmptyError;

  /// Validation error when the email verification code is not 6 digits.
  ///
  /// In en, this message translates to:
  /// **'The code must be 6 digits.'**
  String get emailCodeValidationLengthError;

  /// Headline text shown when headline filters result in an empty list
  ///
  /// In en, this message translates to:
  /// **'No Headlines Match Your Filters'**
  String get headlinesFeedEmptyFilteredHeadline;

  /// Subheadline text shown when headline filters result in an empty list
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter criteria or clearing them to see all headlines.'**
  String get headlinesFeedEmptyFilteredSubheadline;

  /// Button text to clear applied headline filters
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get headlinesFeedClearFiltersButton;

  /// Text shown when filter options are loading
  ///
  /// In en, this message translates to:
  /// **'Loading filter options...'**
  String get headlinesFeedFilterLoadingCriteria;

  /// Generic wait message
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// Error message when filter options fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load filter options.'**
  String get headlinesFeedFilterErrorCriteria;

  /// Label for the country filter selection
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get headlinesFeedFilterCountryLabel;

  /// Label for the source type filter selection
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get headlinesFeedFilterSourceTypeLabel;

  /// Error message when sources fail to load for filtering
  ///
  /// In en, this message translates to:
  /// **'Could not load sources.'**
  String get headlinesFeedFilterErrorSources;

  /// Message shown when no sources match the selected filters
  ///
  /// In en, this message translates to:
  /// **'No sources match your selected filters.'**
  String get headlinesFeedFilterNoSourcesMatch;

  /// Dropdown display name for Headline search type
  ///
  /// In en, this message translates to:
  /// **'Headlines'**
  String get searchModelTypeHeadline;

  /// Dropdown display name for Category search type
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get searchModelTypeCategory;

  /// Dropdown display name for Source search type
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get searchModelTypeSource;

  /// Dropdown display name for Country search type
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get searchModelTypeCountry;

  /// Hint text for searching headlines
  ///
  /// In en, this message translates to:
  /// **'e.g., AI advancements, Mars rover...'**
  String get searchHintTextHeadline;

  /// Generic hint text for search input fields
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHintTextGeneric;

  /// Hint text for searching categories
  ///
  /// In en, this message translates to:
  /// **'e.g., Technology, Sports, Finance...'**
  String get searchHintTextCategory;

  /// Hint text for searching sources
  ///
  /// In en, this message translates to:
  /// **'e.g., BBC News, TechCrunch, Reuters...'**
  String get searchHintTextSource;

  /// Hint text for searching countries
  ///
  /// In en, this message translates to:
  /// **'e.g., USA, Japan, Brazil...'**
  String get searchHintTextCountry;

  /// Generic headline for the initial state of the search page
  ///
  /// In en, this message translates to:
  /// **'Start Your Search'**
  String get searchPageInitialHeadline;

  /// Generic subheadline for the initial state of the search page
  ///
  /// In en, this message translates to:
  /// **'Select a type and enter keywords to begin.'**
  String get searchPageInitialSubheadline;

  /// Title for the page listing followed categories
  ///
  /// In en, this message translates to:
  /// **'Followed Categories'**
  String get followedCategoriesPageTitle;

  /// Tooltip for the button to add new categories to follow
  ///
  /// In en, this message translates to:
  /// **'Add Categories'**
  String get addCategoriesTooltip;

  /// Message displayed when the user has no followed categories
  ///
  /// In en, this message translates to:
  /// **'You are not following any categories yet.'**
  String get noFollowedCategoriesMessage;

  /// Label for the button that navigates to the page for adding categories
  ///
  /// In en, this message translates to:
  /// **'Find Categories to Follow'**
  String get addCategoriesButtonLabel;

  /// Tooltip for the button to unfollow a specific category
  ///
  /// In en, this message translates to:
  /// **'Unfollow {categoryName}'**
  String unfollowCategoryTooltip(String categoryName);

  /// Title for the page where users can add topics to follow
  ///
  /// In en, this message translates to:
  /// **'Follow Topics'**
  String get addTopicsPageTitle;

  /// Headline for loading state on topic filter page
  ///
  /// In en, this message translates to:
  /// **'Loading Topics...'**
  String get topicFilterLoadingHeadline;

  /// Error message when topics fail to load on the filter/add page
  ///
  /// In en, this message translates to:
  /// **'Could not load topics. Please try again.'**
  String get topicFilterError;

  /// Headline for empty state on topic filter page
  ///
  /// In en, this message translates to:
  /// **'No Topics Found'**
  String get topicFilterEmptyHeadline;

  /// Subheadline for empty state on topic filter page
  ///
  /// In en, this message translates to:
  /// **'There are no topics available at the moment.'**
  String get topicFilterEmptySubheadline;

  /// Tooltip for the button to unfollow a specific topic
  ///
  /// In en, this message translates to:
  /// **'Unfollow {topicName}'**
  String unfollowTopicTooltip(String topicName);

  /// Tooltip for the button to follow a specific topic
  ///
  /// In en, this message translates to:
  /// **'Follow {topicName}'**
  String followTopicTooltip(String topicName);

  /// Headline for loading state on followed sources page
  ///
  /// In en, this message translates to:
  /// **'Loading Followed Sources...'**
  String get followedSourcesLoadingHeadline;

  /// Error message when followed sources fail to load
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Followed Sources'**
  String get followedSourcesErrorHeadline;

  /// Headline for empty state on followed sources page
  ///
  /// In en, this message translates to:
  /// **'No Followed Sources'**
  String get followedSourcesEmptyHeadline;

  /// Subheadline for empty state on followed sources page
  ///
  /// In en, this message translates to:
  /// **'Start following sources to see them here.'**
  String get followedSourcesEmptySubheadline;

  /// Label for the topic filter dropdown
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get headlinesFeedFilterTopicLabel;

  /// Title for the page listing followed topics
  ///
  /// In en, this message translates to:
  /// **'Followed Topics'**
  String get followedTopicsPageTitle;

  /// Tooltip for the button to add new topics to follow
  ///
  /// In en, this message translates to:
  /// **'Add Topics'**
  String get addTopicsTooltip;

  /// Headline for loading state on followed topics page
  ///
  /// In en, this message translates to:
  /// **'Loading Followed Topics...'**
  String get followedTopicsLoadingHeadline;

  /// Error message when followed topics fail to load
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Followed Topics'**
  String get followedTopicsErrorHeadline;

  /// Headline for empty state on followed topics page
  ///
  /// In en, this message translates to:
  /// **'No Followed Topics'**
  String get followedTopicsEmptyHeadline;

  /// Subheadline for empty state on followed topics page
  ///
  /// In en, this message translates to:
  /// **'Start following topics to see them here.'**
  String get followedTopicsEmptySubheadline;

  /// Title for the page listing followed sources
  ///
  /// In en, this message translates to:
  /// **'Followed Sources'**
  String get followedSourcesPageTitle;

  /// Tooltip for the button to add new sources to follow
  ///
  /// In en, this message translates to:
  /// **'Add Sources'**
  String get addSourcesTooltip;

  /// Message displayed when the user has no followed sources
  ///
  /// In en, this message translates to:
  /// **'You are not following any sources yet.'**
  String get noFollowedSourcesMessage;

  /// Label for the button that navigates to the page for adding sources
  ///
  /// In en, this message translates to:
  /// **'Find Sources to Follow'**
  String get addSourcesButtonLabel;

  /// Tooltip for the button to unfollow a specific source
  ///
  /// In en, this message translates to:
  /// **'Unfollow {sourceName}'**
  String unfollowSourceTooltip(String sourceName);

  /// Title for the page listing followed countries
  ///
  /// In en, this message translates to:
  /// **'Followed Countries'**
  String get followedCountriesPageTitle;

  /// Tooltip for the button to add new countries to follow
  ///
  /// In en, this message translates to:
  /// **'Add Countries'**
  String get addCountriesTooltip;

  /// Message displayed when the user has no followed countries
  ///
  /// In en, this message translates to:
  /// **'You are not following any countries yet.'**
  String get noFollowedCountriesMessage;

  /// Label for the button that navigates to the page for adding countries
  ///
  /// In en, this message translates to:
  /// **'Find Countries to Follow'**
  String get addCountriesButtonLabel;

  /// Tooltip for the button to unfollow a specific country
  ///
  /// In en, this message translates to:
  /// **'Unfollow {countryName}'**
  String unfollowCountryTooltip(String countryName);

  /// Title for the page where users can add categories to follow
  ///
  /// In en, this message translates to:
  /// **'Add Categories to Follow'**
  String get addCategoriesPageTitle;

  /// Error message when categories fail to load on the filter/add page
  ///
  /// In en, this message translates to:
  /// **'Could not load categories. Please try again.'**
  String get categoryFilterError;

  /// Tooltip for the button to follow a specific category
  ///
  /// In en, this message translates to:
  /// **'Follow {categoryName}'**
  String followCategoryTooltip(String categoryName);

  /// Title for the page where users can add sources to follow
  ///
  /// In en, this message translates to:
  /// **'Add Sources to Follow'**
  String get addSourcesPageTitle;

  /// Error message when sources fail to load on the filter/add page
  ///
  /// In en, this message translates to:
  /// **'Could not load sources. Please try again.'**
  String get sourceFilterError;

  /// Tooltip for the button to follow a specific source
  ///
  /// In en, this message translates to:
  /// **'Follow {sourceName}'**
  String followSourceTooltip(String sourceName);

  /// Title for the page where users can add countries to follow
  ///
  /// In en, this message translates to:
  /// **'Add Countries to Follow'**
  String get addCountriesPageTitle;

  /// Tooltip for the button to follow a specific country
  ///
  /// In en, this message translates to:
  /// **'Follow {countryName}'**
  String followCountryTooltip(String countryName);

  /// Tooltip for the button to save a headline
  ///
  /// In en, this message translates to:
  /// **'Save headline'**
  String get headlineDetailsSaveTooltip;

  /// Tooltip for the button to remove a headline from saved list
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get headlineDetailsRemoveFromSavedTooltip;

  /// Snackbar message shown when a headline is successfully saved
  ///
  /// In en, this message translates to:
  /// **'Headline saved!'**
  String get headlineSavedSuccessSnackbar;

  /// Snackbar message shown when a headline is successfully unsaved
  ///
  /// In en, this message translates to:
  /// **'Headline removed from saved.'**
  String get headlineUnsavedSuccessSnackbar;

  /// Snackbar message shown when saving/unsaving a headline fails
  ///
  /// In en, this message translates to:
  /// **'Could not update saved status. Please try again.'**
  String get headlineSaveErrorSnackbar;

  /// Tooltip for the share button on the headline details page
  ///
  /// In en, this message translates to:
  /// **'Share headline'**
  String get shareActionTooltip;

  /// Snackbar message shown when sharing is unavailable
  ///
  /// In en, this message translates to:
  /// **'Sharing is not available on this device or platform.'**
  String get sharingUnavailableSnackbar;

  /// Title for the similar headlines section on the details page
  ///
  /// In en, this message translates to:
  /// **'You Might Also Like'**
  String get similarHeadlinesSectionTitle;

  /// Message shown when no similar headlines are found
  ///
  /// In en, this message translates to:
  /// **'No similar headlines found.'**
  String get similarHeadlinesEmpty;

  /// Title for the category/source details page
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsPageTitle;

  /// Label for the follow button
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followButtonLabel;

  /// Label for the unfollow button
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollowButtonLabel;

  /// Message displayed when no headlines are available for a category/source
  ///
  /// In en, this message translates to:
  /// **'No headlines found for this item.'**
  String get noHeadlinesFoundMessage;

  /// Error message when loading more headlines fails on details page
  ///
  /// In en, this message translates to:
  /// **'Failed to load more headlines.'**
  String get failedToLoadMoreHeadlines;

  /// Title for the headlines section on details page
  ///
  /// In en, this message translates to:
  /// **'Headlines'**
  String get headlinesSectionTitle;

  /// Label for the checkbox to apply followed items as filters
  ///
  /// In en, this message translates to:
  /// **'Apply my followed items as filters'**
  String get headlinesFeedFilterApplyFollowedLabel;

  /// Error message shown when a logged-in user is required for a feature
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to use this feature.'**
  String get mustBeLoggedInToUseFeatureError;

  /// Snackbar message shown when user tries to apply followed filters but has none.
  ///
  /// In en, this message translates to:
  /// **'You are not following any items to use as a filter.'**
  String get noFollowedItemsForFilterSnackbar;

  /// Headline for the request code page
  ///
  /// In en, this message translates to:
  /// **'Enter Your Email'**
  String get requestCodePageHeadline;

  /// Subheadline for the request code page
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a secure code to your email to verify your identity.'**
  String get requestCodePageSubheadline;

  /// Label for the email input on the request code page
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get requestCodeEmailLabel;

  /// Hint text for the email input on the request code page
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get requestCodeEmailHint;

  /// Button text to send the verification code
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get requestCodeSendCodeButton;

  /// Button text shown during the cooldown period for resending a code
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String requestCodeResendButtonCooldown(int seconds);

  /// Title for category entity type
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get entityDetailsCategoryTitle;

  /// Title for source entity type
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get entityDetailsSourceTitle;

  /// Title for topic entity type
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get entityDetailsTopicTitle;

  /// Title for country entity type
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get entityDetailsCountryTitle;

  /// Headline for loading state on saved headlines page
  ///
  /// In en, this message translates to:
  /// **'Loading Saved Headlines...'**
  String get savedHeadlinesLoadingHeadline;

  /// Subheadline for loading state on saved headlines page
  ///
  /// In en, this message translates to:
  /// **'Please wait while we fetch your saved articles.'**
  String get savedHeadlinesLoadingSubheadline;

  /// Error message when saved headlines fail to load
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Saved Headlines'**
  String get savedHeadlinesErrorHeadline;

  /// Headline for empty state on saved headlines page
  ///
  /// In en, this message translates to:
  /// **'No Saved Headlines'**
  String get savedHeadlinesEmptyHeadline;

  /// Subheadline for empty state on saved headlines page
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any articles yet. Start exploring!'**
  String get savedHeadlinesEmptySubheadline;

  /// Title for the followed countries navigation tile in the account page
  ///
  /// In en, this message translates to:
  /// **'Followed Countries'**
  String get accountFollowedCountriesTile;

  /// Headline for loading state on followed countries page
  ///
  /// In en, this message translates to:
  /// **'Loading Followed Countries...'**
  String get followedCountriesLoadingHeadline;

  /// Error message when followed countries fail to load
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Followed Countries'**
  String get followedCountriesErrorHeadline;

  /// Headline for empty state on followed countries page
  ///
  /// In en, this message translates to:
  /// **'No Followed Countries'**
  String get followedCountriesEmptyHeadline;

  /// Subheadline for empty state on followed countries page
  ///
  /// In en, this message translates to:
  /// **'Start following countries to see them here.'**
  String get followedCountriesEmptySubheadline;

  /// Error message when countries fail to load on the filter/add page
  ///
  /// In en, this message translates to:
  /// **'Could not load countries. Please try again.'**
  String get countryFilterError;

  /// Headline for loading state on followed categories page
  ///
  /// In en, this message translates to:
  /// **'Loading Followed Categories...'**
  String get followedCategoriesLoadingHeadline;

  /// Error message when followed categories fail to load
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Followed Categories'**
  String get followedCategoriesErrorHeadline;

  /// Headline for empty state on followed categories page
  ///
  /// In en, this message translates to:
  /// **'No Followed Categories'**
  String get followedCategoriesEmptyHeadline;

  /// Subheadline for empty state on followed categories page
  ///
  /// In en, this message translates to:
  /// **'Start following categories to see them here.'**
  String get followedCategoriesEmptySubheadline;

  /// Label for Headline content type
  ///
  /// In en, this message translates to:
  /// **'Headlines'**
  String get contentTypeHeadline;

  /// Label for Topic content type
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get contentTypeTopic;

  /// Label for Source content type
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get contentTypeSource;

  /// Label for Country content type
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get contentTypeCountry;

  /// Subheadline for loading state on search page
  ///
  /// In en, this message translates to:
  /// **'Searching for {contentType}...'**
  String searchingFor(String contentType);

  /// Label for the light font weight option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsAppearanceFontWeightLight;

  /// Label for the regular font weight option
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get settingsAppearanceFontWeightRegular;

  /// Label for the bold font weight option
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get settingsAppearanceFontWeightBold;

  /// Headline for the maintenance page
  ///
  /// In en, this message translates to:
  /// **'Under Maintenance'**
  String get maintenanceHeadline;

  /// Subheadline for the maintenance page
  ///
  /// In en, this message translates to:
  /// **'We are currently performing maintenance. Please check back later.'**
  String get maintenanceSubheadline;

  /// Headline for the force update page
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequiredHeadline;

  /// Subheadline for the force update page
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available. Please update to continue using the app.'**
  String get updateRequiredSubheadline;

  /// Button text for the force update page
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateRequiredButton;

  /// Option to dismiss a feed decorator permanently
  ///
  /// In en, this message translates to:
  /// **'Never show this again'**
  String get neverShowAgain;

  /// Text for the follow button on suggestion items
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followButtonText;

  /// Text for the unfollow button on suggestion items
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollowButtonText;

  /// Message displayed in ad slots when ads are loading or fail to load, explaining their purpose.
  ///
  /// In en, this message translates to:
  /// **'Ads help keep this app free !'**
  String get adInfoPlaceholderText;

  /// Text for a button that allows the user to retry a failed operation.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButtonText;

  /// Headline for the loading state when fetching filter options on the headlines filter page.
  ///
  /// In en, this message translates to:
  /// **'Loading Filters'**
  String get headlinesFeedFilterLoadingHeadline;

  /// Title for the suggested topics content collection.
  ///
  /// In en, this message translates to:
  /// **'Suggested Topics'**
  String get suggestedTopicsTitle;

  /// Title for the suggested sources content collection.
  ///
  /// In en, this message translates to:
  /// **'Suggested Sources'**
  String get suggestedSourcesTitle;

  /// Message displayed in a snackbar when the update URL cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open update URL: {url}'**
  String couldNotOpenUpdateUrl(String url);

  /// Label to display the current app version.
  ///
  /// In en, this message translates to:
  /// **'Your current version: {version}'**
  String currentAppVersionLabel(String version);

  /// Label to display the latest required app version.
  ///
  /// In en, this message translates to:
  /// **'Required version: {version}'**
  String latestRequiredVersionLabel(String version);

  /// Title for the bottom sheet when an anonymous user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Do More'**
  String get anonymousLimitTitle;

  /// Body text for the bottom sheet when an anonymous user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to bookmark more and follow more.'**
  String get anonymousLimitBody;

  /// Button text for the bottom sheet when an anonymous user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get anonymousLimitButton;

  /// Body text for the bottom sheet when a standard user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your limit for the free plan. Upgrade to save and follow more.'**
  String get standardLimitBody;

  /// Button text for the bottom sheet when a standard user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get standardLimitButton;

  /// Title for the bottom sheet when a premium user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve Reached the Limit'**
  String get premiumLimitTitle;

  /// Body text for the bottom sheet when a premium user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'To add new items, please review and manage your existing saved and followed content.'**
  String get premiumLimitBody;

  /// Button text for the bottom sheet when a premium user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'Manage My Content'**
  String get premiumLimitButton;

  /// Generic label for a save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// Generic label for a cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonLabel;

  /// Title for the page where users manage their saved filters.
  ///
  /// In en, this message translates to:
  /// **'Manage Filters'**
  String get manageFiltersPageTitle;

  /// Headline for the empty state on the manage saved filters page.
  ///
  /// In en, this message translates to:
  /// **'No Saved Filters'**
  String get manageFiltersEmptyHeadline;

  /// Subheadline for the empty state on the manage saved filters page.
  ///
  /// In en, this message translates to:
  /// **'You can save filters from the filter page.'**
  String get manageFiltersEmptySubheadline;

  /// Tooltip for the button to rename a saved filter.
  ///
  /// In en, this message translates to:
  /// **'Rename Filter'**
  String get manageFiltersRenameTooltip;

  /// Tooltip for the button to delete a saved filter.
  ///
  /// In en, this message translates to:
  /// **'Delete Filter'**
  String get manageFiltersDeleteTooltip;

  /// Title for the dialog when saving a new filter.
  ///
  /// In en, this message translates to:
  /// **'Save Filter'**
  String get saveFilterDialogTitleSave;

  /// Title for the dialog when renaming an existing filter.
  ///
  /// In en, this message translates to:
  /// **'Rename Filter'**
  String get saveFilterDialogTitleRename;

  /// Label for the text input field where the user names a filter.
  ///
  /// In en, this message translates to:
  /// **'Filter Name'**
  String get saveFilterDialogInputLabel;

  /// Validation error message when the filter name is empty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get saveFilterDialogValidationEmpty;

  /// Validation error message when the filter name is too long.
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get saveFilterDialogValidationTooLong;

  /// Generic error message shown in a snackbar if saving a filter fails for an unknown reason.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while saving the filter.'**
  String get saveFilterDialogGenericError;

  /// Tooltip for the save icon on the main filter page.
  ///
  /// In en, this message translates to:
  /// **'Save Filter'**
  String get headlinesFilterSaveTooltip;

  /// Tooltip for the manage icon on the main filter page.
  ///
  /// In en, this message translates to:
  /// **'Manage Filters'**
  String get headlinesFilterManageTooltip;

  /// Tooltip for the icon button on the filters bar that opens the filter page.
  ///
  /// In en, this message translates to:
  /// **'Open Filters'**
  String get savedFiltersBarOpenTooltip;

  /// Label for the 'All' chip in the saved filters bar.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get savedFiltersBarAllLabel;

  /// Label for the 'Custom' chip in the saved filters bar, indicating an unsaved filter is active.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get savedFiltersBarCustomLabel;

  /// Title for the dialog that asks the user how to apply a filter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilterDialogTitle;

  /// Content for the dialog that asks the user how to apply a filter.
  ///
  /// In en, this message translates to:
  /// **'Do you want to apply these filter settings for this session only, or save them for future use?'**
  String get applyFilterDialogContent;

  /// Button text to apply the filter for the current session only.
  ///
  /// In en, this message translates to:
  /// **'Apply Only'**
  String get applyFilterDialogApplyOnlyButton;

  /// Button text to apply and save the filter for future use.
  ///
  /// In en, this message translates to:
  /// **'Apply & Save'**
  String get applyFilterDialogApplyAndSaveButton;

  /// Label for the 'Followed' chip in the saved filters bar.
  ///
  /// In en, this message translates to:
  /// **'Followed'**
  String get savedFiltersBarFollowedLabel;

  /// Title for the page where users can filter the list of sources.
  ///
  /// In en, this message translates to:
  /// **'Filter Sources'**
  String get sourceListFilterPageTitle;

  /// Tooltip for the button that opens the source list filter page.
  ///
  /// In en, this message translates to:
  /// **'Filter source list'**
  String get sourceListFilterPageFilterButtonTooltip;

  /// Title for the page where users filter sources by headquarters country.
  ///
  /// In en, this message translates to:
  /// **'Headquarters location'**
  String get sourceListFilterByHeadquartersPageTitle;

  /// The title for the app bar on the saved filters management page.
  ///
  /// In en, this message translates to:
  /// **'Saved Filters'**
  String get savedFiltersPageTitle;

  /// The main headline text displayed on the saved filters page when the user has no saved filters.
  ///
  /// In en, this message translates to:
  /// **'No Saved Filters'**
  String get savedFiltersEmptyHeadline;

  /// The sub-headline text displayed on the saved filters page when the user has no saved filters.
  ///
  /// In en, this message translates to:
  /// **'Filters you save from the feed will appear here.'**
  String get savedFiltersEmptySubheadline;

  /// The text for the 'Rename' option in the popup menu on a saved filter item.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get savedFiltersMenuRename;

  /// The text for the 'Delete' option in the popup menu on a saved filter item.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savedFiltersMenuDelete;

  /// Title for the discover page
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverPageTitle;

  /// Label for the Discover item in the bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get bottomNavDiscoverLabel;

  /// Hint text for the search bar on the feed page
  ///
  /// In en, this message translates to:
  /// **'Search headlines...'**
  String get feedSearchHint;

  /// Headline for the initial state of the headline search page
  ///
  /// In en, this message translates to:
  /// **'Find headlines from thousands of sources.'**
  String get headlineSearchEnterQuery;

  /// Subheadline for the initial state of the headline search page
  ///
  /// In en, this message translates to:
  /// **'Search by keyword to find articles from thousands of sources.'**
  String get headlineSearchEnterQuerySubheadline;

  /// Headline for when a headline search returns no results
  ///
  /// In en, this message translates to:
  /// **'No headlines found.'**
  String get headlineSearchNoResults;

  /// Subheadline for when a headline search returns no results
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any headlines matching your search. Please try different keywords.'**
  String get headlineSearchNoResultsSubheadline;

  /// Label indicating the user is a guest.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get accountGuestAccount;

  /// Label for a standard user role.
  ///
  /// In en, this message translates to:
  /// **'Standard User'**
  String get accountRoleStandard;

  /// Label for a premium user role.
  ///
  /// In en, this message translates to:
  /// **'Premium User'**
  String get accountRolePremium;

  /// Title for the dialog that asks the user to confirm a delete action.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get deleteConfirmationDialogTitle;

  /// The main text in the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item? This action cannot be undone.'**
  String get deleteConfirmationDialogContent;

  /// The text for the confirm button in the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirmationDialogConfirmButton;

  /// Headline text shown in the initial state widget on the search page
  ///
  /// In en, this message translates to:
  /// **'Search for Headlines'**
  String get headlineSearchInitialHeadline;

  /// Subheadline text shown in the initial state widget on the search page
  ///
  /// In en, this message translates to:
  /// **'Enter keywords to find articles.'**
  String get headlineSearchInitialSubheadline;

  /// Headline for the user header when the user is a guest.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get accountGuestUserHeadline;

  /// Subheadline for the user header prompting guest users to sign in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get accountGuestUserSubheadline;

  /// Hint text for the search bar on the discover page
  ///
  /// In en, this message translates to:
  /// **'Search sources...'**
  String get discoverSearchHint;

  /// Label for the button to see all items in a category
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllButtonLabel;

  /// Error message when loading more sources fails on details page
  ///
  /// In en, this message translates to:
  /// **'Failed to load more sources.'**
  String get failedToLoadMoreSources;

  /// Source type for News Agency
  ///
  /// In en, this message translates to:
  /// **'News Agency'**
  String get sourceTypeNewsAgency;

  /// Source type for Local News Outlet
  ///
  /// In en, this message translates to:
  /// **'Local News Outlet'**
  String get sourceTypeLocalNewsOutlet;

  /// Source type for National News Outlet
  ///
  /// In en, this message translates to:
  /// **'National News Outlet'**
  String get sourceTypeNationalNewsOutlet;

  /// Source type for International News Outlet
  ///
  /// In en, this message translates to:
  /// **'International News Outlet'**
  String get sourceTypeInternationalNewsOutlet;

  /// Source type for Specialized Publisher
  ///
  /// In en, this message translates to:
  /// **'Specialized Publisher'**
  String get sourceTypeSpecializedPublisher;

  /// Source type for Blog
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get sourceTypeBlog;

  /// Source type for Government Source
  ///
  /// In en, this message translates to:
  /// **'Government Source'**
  String get sourceTypeGovernmentSource;

  /// Source type for Aggregator
  ///
  /// In en, this message translates to:
  /// **'Aggregator'**
  String get sourceTypeAggregator;

  /// Source type for Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sourceTypeOther;

  /// Plural source type for News Agency
  ///
  /// In en, this message translates to:
  /// **'News Agencies'**
  String get sourceTypeNewsAgencies;

  /// Plural source type for Local News Outlet
  ///
  /// In en, this message translates to:
  /// **'Local News Outlets'**
  String get sourceTypeLocalNewsOutlets;

  /// Plural source type for National News Outlet
  ///
  /// In en, this message translates to:
  /// **'National News Outlets'**
  String get sourceTypeNationalNewsOutlets;

  /// Plural source type for International News Outlet
  ///
  /// In en, this message translates to:
  /// **'International News Outlets'**
  String get sourceTypeInternationalNewsOutlets;

  /// Plural source type for Specialized Publisher
  ///
  /// In en, this message translates to:
  /// **'Specialized Publishers'**
  String get sourceTypeSpecializedPublishers;

  /// Plural source type for Blog
  ///
  /// In en, this message translates to:
  /// **'Blogs'**
  String get sourceTypeBlogs;

  /// Plural source type for Government Source
  ///
  /// In en, this message translates to:
  /// **'Government Sources'**
  String get sourceTypeGovernmentSources;

  /// Plural source type for Aggregator
  ///
  /// In en, this message translates to:
  /// **'Aggregators'**
  String get sourceTypeAggregators;

  /// Plural source type for Other
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get sourceTypeOthers;

  /// User-friendly confirmation message shown in place of a feed decorator after it has been dismissed.
  ///
  /// In en, this message translates to:
  /// **'Suggestion hidden.'**
  String get decoratorDismissedConfirmation;

  /// The text for the menu item that allows a user to hide or dismiss a feed decorator.
  ///
  /// In en, this message translates to:
  /// **'Hide suggestion'**
  String get decoratorDismissAction;

  /// First variation of the title for the 'Link Account' decorator, focusing on the benefit of saving content.
  ///
  /// In en, this message translates to:
  /// **'Save Your Articles & Preferences'**
  String get decoratorLinkAccountTitle_1;

  /// Second variation of the title for the 'Link Account' decorator, highlighting the benefit of persistence.
  ///
  /// In en, this message translates to:
  /// **'Never Lose Your saved Preferences'**
  String get decoratorLinkAccountTitle_2;

  /// First variation of the description for the 'Link Account' decorator, hinting at increased limits and syncing.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save more articles, follow more topics, and sync your preferences across devices.'**
  String get decoratorLinkAccountDescription_1;

  /// Second variation of the description for the 'Link Account' decorator, hinting at increased limits and consistency.
  ///
  /// In en, this message translates to:
  /// **'Sign up to unlock more saves, expand your followed content, and keep your news feed consistent everywhere.'**
  String get decoratorLinkAccountDescription_2;

  /// First variation of the call-to-action text for the 'Link Account' decorator.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Now'**
  String get decoratorLinkAccountCta_1;

  /// Second variation of the call-to-action text for the 'Link Account' decorator.
  ///
  /// In en, this message translates to:
  /// **'Create Free Account'**
  String get decoratorLinkAccountCta_2;

  /// First variation of the title for the 'Upgrade' decorator, focusing on an uninterrupted, ad-free experience.
  ///
  /// In en, this message translates to:
  /// **'Enjoy an Uninterrupted News Experience'**
  String get decoratorUpgradeTitle_1;

  /// Second variation of the title for the 'Upgrade' decorator, highlighting premium access.
  ///
  /// In en, this message translates to:
  /// **'Unlock Your Premium Access'**
  String get decoratorUpgradeTitle_2;

  /// First variation of the description for the 'Upgrade' decorator, highlighting ad-free and increased limits.
  ///
  /// In en, this message translates to:
  /// **'Go ad-free and greatly expand your limits for saved articles and followed content.'**
  String get decoratorUpgradeDescription_1;

  /// Second variation of the description for the 'Upgrade' decorator, emphasizing ad-free and the ability to save/follow more.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium for an ad-free experience and the ability to save and follow much more of the content you love.'**
  String get decoratorUpgradeDescription_2;

  /// First variation of the call-to-action text for the 'Upgrade' decorator.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get decoratorUpgradeCta_1;

  /// Second variation of the call-to-action text for the 'Upgrade' decorator.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get decoratorUpgradeCta_2;

  /// First variation of the title for the 'Rate App' decorator, engaging the user positively.
  ///
  /// In en, this message translates to:
  /// **'Enjoying the App?'**
  String get decoratorRateAppTitle_1;

  /// Second variation of the title for the 'Rate App' decorator, asking for feedback.
  ///
  /// In en, this message translates to:
  /// **'Share Your Feedback'**
  String get decoratorRateAppTitle_2;

  /// First variation of the description for the 'Rate App' decorator, explaining the impact of their rating.
  ///
  /// In en, this message translates to:
  /// **'Your rating helps us improve the news experience for everyone. Your opinion matters!'**
  String get decoratorRateAppDescription_1;

  /// Second variation of the description for the 'Rate App' decorator, emphasizing the value of their feedback.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps us deliver better news. Take a moment to rate us now!'**
  String get decoratorRateAppDescription_2;

  /// First variation of the call-to-action text for the 'Rate App' decorator.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get decoratorRateAppCta_1;

  /// Second variation of the call-to-action text for the 'Rate App' decorator.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback'**
  String get decoratorRateAppCta_2;

  /// First variation of the title for the 'Enable Notifications' decorator, focusing on breaking news.
  ///
  /// In en, this message translates to:
  /// **'Never Miss Breaking News'**
  String get decoratorEnableNotificationsTitle_1;

  /// Second variation of the title for the 'Enable Notifications' decorator, emphasizing instant updates.
  ///
  /// In en, this message translates to:
  /// **'Stay Informed, Instantly'**
  String get decoratorEnableNotificationsTitle_2;

  /// First variation of the description for the 'Enable Notifications' decorator, detailing types of alerts.
  ///
  /// In en, this message translates to:
  /// **'Get instant alerts for breaking news and updates from your followed topics and sources.'**
  String get decoratorEnableNotificationsDescription_1;

  /// Second variation of the description for the 'Enable Notifications' decorator, highlighting personalized updates.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive personalized news updates directly to your device.'**
  String get decoratorEnableNotificationsDescription_2;

  /// First variation of the call-to-action text for the 'Enable Notifications' decorator.
  ///
  /// In en, this message translates to:
  /// **'Enable Alerts'**
  String get decoratorEnableNotificationsCta_1;

  /// Second variation of the call-to-action text for the 'Enable Notifications' decorator.
  ///
  /// In en, this message translates to:
  /// **'Turn On Notifications'**
  String get decoratorEnableNotificationsCta_2;

  /// First variation of the title for the 'Suggested Topics' decorator, encouraging exploration.
  ///
  /// In en, this message translates to:
  /// **'Discover New Interests'**
  String get decoratorSuggestedTopicsTitle_1;

  /// Second variation of the title for the 'Suggested Topics' decorator, focusing on discovery.
  ///
  /// In en, this message translates to:
  /// **'Broaden Your Knowledge'**
  String get decoratorSuggestedTopicsTitle_2;

  /// First variation of the title for the 'Suggested Sources' decorator, encouraging discovery of new sources.
  ///
  /// In en, this message translates to:
  /// **'Find New Perspectives'**
  String get decoratorSuggestedSourcesTitle_1;

  /// Second variation of the title for the 'Suggested Sources' decorator, focusing on broadening reading.
  ///
  /// In en, this message translates to:
  /// **'Discover Trusted Sources'**
  String get decoratorSuggestedSourcesTitle_2;

  /// The title for the app bar on the saved filters management page.
  ///
  /// In en, this message translates to:
  /// **'Saved Filters'**
  String get savedHeadlineFiltersPageTitle;

  /// The text for the floating action button to create a new filter.
  ///
  /// In en, this message translates to:
  /// **'Create Filter'**
  String get savedHeadlineFiltersCreateNewButton;

  /// The main headline text displayed while the saved filters are loading.
  ///
  /// In en, this message translates to:
  /// **'Loading Your Filters...'**
  String get savedHeadlineFiltersLoadingHeadline;

  /// The main headline text displayed on the saved filters page when the user has no saved filters.
  ///
  /// In en, this message translates to:
  /// **'No Saved Filters Yet'**
  String get savedHeadlineFiltersEmptyHeadline;

  /// The sub-headline text displayed on the saved filters page when the user has no saved filters.
  ///
  /// In en, this message translates to:
  /// **'Filters you create and save will appear here. Tap the button below to get started.'**
  String get savedHeadlineFiltersEmptySubheadline;

  /// The text for the 'Edit' option in the popup menu on a saved filter item.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get savedFiltersMenuEdit;

  /// Label for the switch that allows a user to pin a saved filter to their feed.
  ///
  /// In en, this message translates to:
  /// **'Pin to Filter Bar'**
  String get saveFilterDialogPinToFeedLabel;

  /// The title for the section in the save filter dialog where users configure notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get saveFilterDialogNotificationsLabel;

  /// The user-facing name for the 'breakingOnly' notification delivery type.
  ///
  /// In en, this message translates to:
  /// **'Breaking News'**
  String get notificationDeliveryTypeBreakingOnly;

  /// The user-facing name for the 'dailyDigest' notification delivery type.
  ///
  /// In en, this message translates to:
  /// **'Daily Digest'**
  String get notificationDeliveryTypeDailyDigest;

  /// The user-facing name for the 'weeklyRoundup' notification delivery type.
  ///
  /// In en, this message translates to:
  /// **'Weekly Roundup'**
  String get notificationDeliveryTypeWeeklyRoundup;

  /// Title for the pre-permission dialog asking the user to enable notifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications?'**
  String get prePermissionDialogTitle;

  /// Body text for the pre-permission dialog explaining why notifications are needed for saved filters.
  ///
  /// In en, this message translates to:
  /// **'To send you breaking news alerts and digests for this filter, please allow notifications.'**
  String get prePermissionDialogBody;

  /// Text for the button to deny notification permission in the pre-permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get prePermissionDialogDenyButton;

  /// Text for the button to allow notification permission in the pre-permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get prePermissionDialogAllowButton;

  /// Error message shown when the user denies notification permissions at the OS level.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. You can enable it in your device settings.'**
  String get notificationPermissionDeniedError;

  /// Title for the in-app notification center page.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationCenterPageTitle;

  /// Text for the button to mark all notifications as read.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationCenterMarkAllAsReadButton;

  /// Headline for the loading state on the notification center page.
  ///
  /// In en, this message translates to:
  /// **'Loading Notifications...'**
  String get notificationCenterLoadingHeadline;

  /// Subheadline for the loading state on the notification center page.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get notificationCenterLoadingSubheadline;

  /// Headline for the failure state on the notification center page.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Notifications'**
  String get notificationCenterFailureHeadline;

  /// Subheadline for the failure state on the notification center page.
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve your notifications. Please try again.'**
  String get notificationCenterFailureSubheadline;

  /// Headline for the empty state on the notification center page.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get notificationCenterEmptyHeadline;

  /// Subheadline for the empty state on the notification center page.
  ///
  /// In en, this message translates to:
  /// **'You have no new notifications.'**
  String get notificationCenterEmptySubheadline;

  /// Label for the 'Breaking News' tab in the notification center.
  ///
  /// In en, this message translates to:
  /// **'Breaking News'**
  String get notificationCenterTabBreakingNews;

  /// Label for the 'Digests' tab in the notification center.
  ///
  /// In en, this message translates to:
  /// **'Digests'**
  String get notificationCenterTabDigests;

  /// Tooltip for the button to delete all read notifications in the current tab.
  ///
  /// In en, this message translates to:
  /// **'Delete all read notifications'**
  String get deleteReadNotificationsButtonTooltip;

  /// The main text in the dialog confirming the deletion of read notifications.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all read notifications in this tab? This action cannot be undone.'**
  String get deleteReadNotificationsDialogContent;

  /// Generic label for a delete button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButtonLabel;

  /// Prefix text shown for breaking news headlines.
  ///
  /// In en, this message translates to:
  /// **'Breaking News'**
  String get breakingNewsPrefix;

  /// Label for the setting that controls how article links are opened.
  ///
  /// In en, this message translates to:
  /// **'Open links using'**
  String get settingsFeedClickBehaviorLabel;

  /// Option to use the app's default link-opening behavior.
  ///
  /// In en, this message translates to:
  /// **'App default'**
  String get settingsFeedClickBehaviorDefault;

  /// Option to open links in a browser within the app.
  ///
  /// In en, this message translates to:
  /// **'In-app browser'**
  String get settingsFeedClickBehaviorInApp;

  /// Option to open links in the device's default system browser.
  ///
  /// In en, this message translates to:
  /// **'System browser'**
  String get settingsFeedClickBehaviorSystem;

  /// Button text on an interstitial ad to proceed to the article.
  ///
  /// In en, this message translates to:
  /// **'Continue to Article'**
  String get continueToArticleButtonLabel;

  /// Title for the modal bottom sheet that shows headline actions like share and bookmark.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get headlineActionsModalTitle;

  /// Label for the share action.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareActionLabel;

  /// Label for the action to add a headline to bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmarkActionLabel;

  /// Label for the action to remove a headline from bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Remove Bookmark'**
  String get removeBookmarkActionLabel;

  /// Label for the action to report content.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportActionLabel;

  /// Title for the report content bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Report Content'**
  String get reportContentTitle;

  /// Prompt asking the user to select a reason for reporting.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for your report:'**
  String get reportReasonSelectionPrompt;

  /// Label for the optional additional comments field in the report form.
  ///
  /// In en, this message translates to:
  /// **'Additional Comments (Optional)'**
  String get reportAdditionalCommentsLabel;

  /// Label for the button to submit a content report.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportSubmitButtonLabel;

  /// Snackbar message shown after a report is successfully submitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for your feedback.'**
  String get reportSuccessSnackbar;

  /// Snackbar message shown when submitting a report fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report. Please try again.'**
  String get reportFailureSnackbar;

  /// Title for the comments section or bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// Label for the button to post a new comment.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get commentPostButtonLabel;

  /// Hint text for the comment input field.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get commentInputHint;

  /// Error message shown when a user tries to comment without selecting a reaction.
  ///
  /// In en, this message translates to:
  /// **'Please select a reaction to post a comment.'**
  String get commentRequiresReactionError;

  /// Tooltip or label for the 'Like' action.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeActionLabel;

  /// Tooltip or label for the 'Dislike' action.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get dislikeActionLabel;

  /// Tooltip or label for the 'Comment' action.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentActionLabel;

  /// Tooltip or label for the 'More' actions icon.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActionLabel;

  /// Title for the in-app bottom sheet that prompts the user to rate the app.
  ///
  /// In en, this message translates to:
  /// **'Enjoying the app?'**
  String get rateAppPromptTitle;

  /// Body text for the in-app rating prompt bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps us improve. Would you mind rating us?'**
  String get rateAppPromptBody;

  /// Button text for a positive response to the rating prompt.
  ///
  /// In en, this message translates to:
  /// **'It\'s Great!'**
  String get rateAppPromptYesButton;

  /// Button text for a negative response to the rating prompt.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get rateAppPromptNoButton;

  /// Title for the bottom sheet that asks for detailed feedback after a negative rating prompt response.
  ///
  /// In en, this message translates to:
  /// **'How can we improve?'**
  String get feedbackPromptTitle;

  /// Feedback reason related to UI and design.
  ///
  /// In en, this message translates to:
  /// **'UI / Design'**
  String get feedbackPromptReasonUI;

  /// Feedback reason related to app performance.
  ///
  /// In en, this message translates to:
  /// **'Performance / Speed'**
  String get feedbackPromptReasonPerformance;

  /// Feedback reason related to the quality of news content.
  ///
  /// In en, this message translates to:
  /// **'Content Quality'**
  String get feedbackPromptReasonContent;

  /// Feedback reason for issues not listed.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackPromptReasonOther;

  /// Button text to submit detailed feedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get feedbackPromptSubmitButton;

  /// First variation of the follow-up title for the 'Rate App' prompt after a user has given negative feedback.
  ///
  /// In en, this message translates to:
  /// **'How are we doing now?'**
  String get rateAppNegativeFollowUpTitle_1;

  /// Second variation of the follow-up title for the 'Rate App' prompt after a user has given negative feedback.
  ///
  /// In en, this message translates to:
  /// **'Have we improved?'**
  String get rateAppNegativeFollowUpTitle_2;

  /// First variation of the follow-up body text for the 'Rate App' prompt after a user has given negative feedback.
  ///
  /// In en, this message translates to:
  /// **'We\'ve been working on your feedback. Would you reconsider your rating?'**
  String get rateAppNegativeFollowUpBody_1;

  /// Second variation of the follow-up body text for the 'Rate App' prompt after a user has given negative feedback.
  ///
  /// In en, this message translates to:
  /// **'We value your opinion. Let us know if things are better.'**
  String get rateAppNegativeFollowUpBody_2;

  /// Message displayed when there are no comments on a headline.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// Hint text for the comment input field when the user has not yet reacted.
  ///
  /// In en, this message translates to:
  /// **'React to add a comment'**
  String get commentInputNoReactionHint;

  /// Report reason for factually incorrect content.
  ///
  /// In en, this message translates to:
  /// **'Misinformation or Fake News'**
  String get headlineReportReasonMisinformation;

  /// Report reason for a clickbait headline.
  ///
  /// In en, this message translates to:
  /// **'Clickbait or Misleading Title'**
  String get headlineReportReasonClickbait;

  /// Report reason for offensive content.
  ///
  /// In en, this message translates to:
  /// **'Offensive or Hate Speech'**
  String get headlineReportReasonOffensive;

  /// Report reason for spam or fraudulent content.
  ///
  /// In en, this message translates to:
  /// **'Spam or Scam'**
  String get headlineReportReasonSpam;

  /// Report reason for a non-working article URL.
  ///
  /// In en, this message translates to:
  /// **'Broken Link'**
  String get headlineReportReasonBrokenLink;

  /// Report reason for content that requires a subscription.
  ///
  /// In en, this message translates to:
  /// **'Paywalled Content'**
  String get headlineReportReasonPaywalled;

  /// Report reason for a source with poor content.
  ///
  /// In en, this message translates to:
  /// **'Low-Quality Journalism'**
  String get sourceReportReasonLowQuality;

  /// Report reason for a source with a bad user experience due to ads.
  ///
  /// In en, this message translates to:
  /// **'Excessive Ads or Popups'**
  String get sourceReportReasonHighAdDensity;

  /// Report reason for a source that often requires a subscription.
  ///
  /// In en, this message translates to:
  /// **'Frequent Paywalls'**
  String get sourceReportReasonFrequentPaywalls;

  /// Report reason for a source pretending to be another entity.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get sourceReportReasonImpersonation;

  /// Report reason for a source pretending to be another entity.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get sourceReportReasonMisinformation;

  /// Report reason for a comment that is spam.
  ///
  /// In en, this message translates to:
  /// **'Spam or Advertising'**
  String get commentReportReasonSpam;

  /// Report reason for a comment that is abusive.
  ///
  /// In en, this message translates to:
  /// **'Harassment or Bullying'**
  String get commentReportReasonHarassment;

  /// Report reason for a comment containing hate speech.
  ///
  /// In en, this message translates to:
  /// **'Hate Speech'**
  String get commentReportReasonHateSpeech;

  /// Generic title for when a user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get limitReachedTitle;

  /// Button text that navigates the user to a page where they can manage their content (e.g., unfollow items).
  ///
  /// In en, this message translates to:
  /// **'Manage My Content'**
  String get manageMyContentButton;

  /// Button text prompting the user to upgrade their subscription plan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButton;

  /// Button text prompting an anonymous user to create an account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// A simple acknowledgement button.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotItButton;

  /// Title for the page or bottom sheet that displays comments for a headline.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsPageTitle;

  /// Label for a button that shows the number of comments and opens the comments view.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 Comment}other{{count} Comments}}'**
  String commentsCount(int count);

  /// Title for the bottom sheet when a guest user tries to perform an action reserved for authenticated users (e.g., comment, react).
  ///
  /// In en, this message translates to:
  /// **'Account Required'**
  String get limitReachedGuestUserTitle;

  /// Body text for the bottom sheet when a guest user tries to perform an action reserved for authenticated users.
  ///
  /// In en, this message translates to:
  /// **'Please create a free account or sign in to engage with the community and use this feature.'**
  String get limitReachedGuestUserBody;

  /// Body text when a user tries to follow more items (topics, sources, countries) than their plan allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your limit for followed items. To follow more, please review your existing followed content.'**
  String get limitReachedBodyFollow;

  /// Body text when a user tries to save more articles than their plan allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your limit for saved articles. To save more, please review your existing saved articles.'**
  String get limitReachedBodySave;

  /// Body text when a user tries to save more filters than their plan allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your limit for saved filters. To create new ones, please review your existing filters.'**
  String get limitReachedBodySaveFilters;

  /// Body text when a user tries to pin more filters than their plan allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your limit for pinned filters. To pin a new one, please un-pin an existing filter.'**
  String get limitReachedBodyPinFilters;

  /// Body text when a user tries to subscribe to more notifications than their plan allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your limit for notification subscriptions. To subscribe to new alerts, please review your existing subscriptions.'**
  String get limitReachedBodySubscribeToNotifications;

  /// Body text when a user tries to post more comments than their daily limit allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your daily limit for posting comments. Please try again tomorrow.'**
  String get limitReachedBodyComments;

  /// Body text when a user tries to react more than their daily limit allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your daily limit for reactions. Please try again tomorrow.'**
  String get limitReachedBodyReactions;

  /// Body text when a user tries to submit more reports than their daily limit allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your daily limit for submitting reports. Please try again tomorrow.'**
  String get limitReachedBodyReports;

  /// Label for the button to update an existing comment.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commentEditButtonLabel;

  /// Snackbar message shown when posting a comment fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment. Please try again.'**
  String get commentPostFailureSnackbar;

  /// Snackbar message shown when updating a comment fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update comment. Please try again.'**
  String get commentUpdateFailureSnackbar;

  /// Hint text for the comment input field when the user is a guest.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join the conversation'**
  String get commentInputDisabledHint;

  /// Hint text for the comment input field when the user has already posted a comment.
  ///
  /// In en, this message translates to:
  /// **'You have already commented on this headline.'**
  String get commentInputExistingHint;

  /// Display name for a commenter when their full user object is not available, showing a partial ID.
  ///
  /// In en, this message translates to:
  /// **'User {id}'**
  String commenterName(String id);

  /// Title for the rewards navigation tile in the account page.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Offers'**
  String get accountRewardsTile;

  /// Title for the rewards page.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewardsPageTitle;

  /// Title for a reward offer card, indicating the reward and its duration.
  ///
  /// In en, this message translates to:
  /// **'Get {rewardName} for {duration}'**
  String rewardsOfferTitle(String rewardName, String duration);

  /// Title for an active reward offer card.
  ///
  /// In en, this message translates to:
  /// **'{rewardName} Active'**
  String rewardsOfferActiveTitle(String rewardName);

  /// Text showing the remaining time for an active reward.
  ///
  /// In en, this message translates to:
  /// **'Expires in: {countdown}'**
  String rewardsOfferExpiresIn(String countdown);

  /// Button text to watch a video to earn a reward.
  ///
  /// In en, this message translates to:
  /// **'Watch Video'**
  String get rewardsOfferWatchButton;

  /// Button text shown while a reward is being verified.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get rewardsOfferVerifyingButton;

  /// Button text shown while the ad is being prepared to show.
  ///
  /// In en, this message translates to:
  /// **'Loading Ad...'**
  String get rewardsOfferLoadingButton;

  /// Snackbar message shown when a reward is successfully unlocked.
  ///
  /// In en, this message translates to:
  /// **'Reward Unlocked: {rewardName} is now active.'**
  String rewardsSnackbarSuccess(String rewardName);

  /// Snackbar message shown when reward verification fails.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again in a moment.'**
  String get rewardsSnackbarFailure;

  /// Snackbar message shown when the user dismisses a rewarded ad before completion.
  ///
  /// In en, this message translates to:
  /// **'Ad dismissed. Please watch the full ad to earn the reward.'**
  String get rewardsAdDismissedSnackbar;

  /// Title for the 'Unlock Rewards' decorator.
  ///
  /// In en, this message translates to:
  /// **'Unlock an Ad-Free Experience'**
  String get decoratorUnlockRewardsTitle;

  /// Description for the 'Unlock Rewards' decorator.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video to enjoy the app without ads for {duration}.'**
  String decoratorUnlockRewardsDescription(String duration);

  /// Call-to-action text for the 'Unlock Rewards' decorator.
  ///
  /// In en, this message translates to:
  /// **'Watch Now'**
  String get decoratorUnlockRewardsCta;

  /// Pluralized string for reward duration in days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Day} other{{count} Days}}'**
  String rewardsDurationDays(int count);

  /// The name for the 'Ad-Free' reward type.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free'**
  String get rewardTypeAdFree;

  /// The name for the 'Daily Digest' reward type.
  ///
  /// In en, this message translates to:
  /// **'Daily Digest'**
  String get rewardTypeDailyDigest;

  /// Button text to unlock more features or content limits.
  ///
  /// In en, this message translates to:
  /// **'Unlock More'**
  String get unlockMoreButton;

  /// Label indicating a feature requires an active reward.
  ///
  /// In en, this message translates to:
  /// **'Requires an active reward. You can unlock rewards from the Account page.'**
  String get requiresActiveReward;

  /// Title for the Ad-Free reward offer.
  ///
  /// In en, this message translates to:
  /// **'Enjoy an Ad-Free Experience'**
  String get rewardsAdFreeTitle;

  /// Description for the Ad-Free reward offer.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video to remove all ads from the app for {duration}.'**
  String rewardsAdFreeDescription(String duration);

  /// Title for the Daily Digest reward offer.
  ///
  /// In en, this message translates to:
  /// **'Unlock Daily News Digests'**
  String get rewardsDailyDigestTitle;

  /// Description for the Daily Digest reward offer.
  ///
  /// In en, this message translates to:
  /// **'Receive a daily push notification summarizing the top headlines from your saved filters that have the \'Daily Digest\' option enabled. Active for {duration}.'**
  String rewardsDailyDigestDescription(String duration);

  /// Button text for a reward that is currently active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get rewardsOfferActiveButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
