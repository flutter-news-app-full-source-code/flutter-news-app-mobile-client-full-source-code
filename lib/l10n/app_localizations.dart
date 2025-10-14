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
  /// **'Content Preferences'**
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

  /// Title for the feed display settings section/page
  ///
  /// In en, this message translates to:
  /// **'Feed Display'**
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

  /// Message shown in demo mode to provide the verification code
  ///
  /// In en, this message translates to:
  /// **'Demo Mode: Use code {code}'**
  String demoVerificationCodeMessage(String code);

  /// Message shown in demo mode to suggest an email for sign-in
  ///
  /// In en, this message translates to:
  /// **'Demo Mode: Use email {email}'**
  String demoEmailSuggestionMessage(String email);

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

  /// Text displayed in the native ad placeholder in demo mode.
  ///
  /// In en, this message translates to:
  /// **'NATIVE AD (DEMO)'**
  String get demoNativeAdText;

  /// Text displayed in the banner ad placeholder in demo mode.
  ///
  /// In en, this message translates to:
  /// **'BANNER AD (DEMO)'**
  String get demoBannerAdText;

  /// Text displayed in the interstitial ad placeholder in demo mode.
  ///
  /// In en, this message translates to:
  /// **'INTERSTITIAL AD (DEMO)'**
  String get demoInterstitialAdText;

  /// Description text for the interstitial ad placeholder in demo mode.
  ///
  /// In en, this message translates to:
  /// **'This is a full-screen advertisement placeholder.'**
  String get demoInterstitialAdDescription;

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

  /// Title for the bottom sheet when a standard user hits a content limit.
  ///
  /// In en, this message translates to:
  /// **'Unlock More Access'**
  String get standardLimitTitle;

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
