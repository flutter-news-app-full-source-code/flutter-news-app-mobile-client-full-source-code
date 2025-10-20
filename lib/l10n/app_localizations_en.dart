// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountLinkingPageTitle => 'Link Your Account';

  @override
  String get accountLinkingGenericError => 'An error occurred';

  @override
  String get accountLinkingEmailSentSuccess =>
      'Check your email for the sign-in link!';

  @override
  String get accountLinkingHeadline => 'Save your progress';

  @override
  String get accountLinkingBody =>
      'Signing up allows you to access your information across multiple devices and ensures your progress isn\'t lost.';

  @override
  String get accountLinkingContinueWithGoogleButton => 'Continue with Google';

  @override
  String get accountLinkingEmailInputLabel => 'Enter your email';

  @override
  String get accountLinkingEmailInputHint => 'you@example.com';

  @override
  String get accountLinkingEmailValidationError =>
      'Please enter a valid email address';

  @override
  String get accountLinkingSendLinkButton => 'Send Sign-In Link';

  @override
  String get accountPageTitle => 'Account';

  @override
  String get accountAnonymousUser => '(Anonymous)';

  @override
  String get accountNoNameUser => 'No Name';

  @override
  String get accountStatusAuthenticated => 'Authenticated';

  @override
  String get accountStatusAnonymous => 'Anonymous Session';

  @override
  String get accountStatusUnauthenticated => 'Not Signed In';

  @override
  String get accountSettingsTile => 'Settings';

  @override
  String get accountSignOutTile => 'Sign Out';

  @override
  String get accountBackupTile => 'Create Account to Save Data';

  @override
  String get accountContentPreferencesTile => 'Content Preferences';

  @override
  String get accountSavedHeadlinesTile => 'Saved Headlines';

  @override
  String accountRoleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get authenticationEmailSentSuccess =>
      'Check your email for the sign-in link.';

  @override
  String get authenticationPageTitle => 'Sign In / Register';

  @override
  String get authenticationEmailLabel => 'Email';

  @override
  String get authenticationSendLinkButton => 'Send Sign-In Link';

  @override
  String get authenticationOrDivider => 'OR';

  @override
  String get authenticationGoogleSignInButton => 'Sign In with Google';

  @override
  String get authenticationAnonymousSignInButton => 'Continue Anonymously';

  @override
  String get headlineDetailsInitialHeadline => 'Waiting for Headline';

  @override
  String get headlineDetailsInitialSubheadline => 'Please wait...';

  @override
  String get headlineDetailsLoadingHeadline => 'Loading Headline';

  @override
  String get headlineDetailsLoadingSubheadline => 'Fetching data...';

  @override
  String get headlineDetailsContinueReadingButton => 'Continue Reading';

  @override
  String get headlinesFeedLoadingHeadline => 'Loading...';

  @override
  String get headlinesFeedLoadingSubheadline => 'Fetching headlines';

  @override
  String get headlinesFeedFilterTitle => 'Filter Headlines';

  @override
  String get headlinesFeedFilterCategoryLabel => 'Category';

  @override
  String get headlinesFeedFilterAllOption => 'All';

  @override
  String get headlinesFeedFilterCategoryTechnology => 'Technology';

  @override
  String get headlinesFeedFilterCategoryBusiness => 'Business';

  @override
  String get headlinesFeedFilterCategorySports => 'Sports';

  @override
  String get headlinesFeedFilterSourceLabel => 'Source';

  @override
  String get headlinesFeedFilterSourceCNN => 'CNN';

  @override
  String get headlinesFeedFilterSourceReuters => 'Reuters';

  @override
  String get headlinesFeedFilterEventCountryLabel => 'Country of Event';

  @override
  String get headlinesFeedFilterSourceCountryLabel => 'Source Headquarter';

  @override
  String get headlinesFeedFilterCountryUS => 'United States';

  @override
  String get headlinesFeedFilterCountryUK => 'United Kingdom';

  @override
  String get headlinesFeedFilterCountryCA => 'Canada';

  @override
  String get headlinesFeedFilterApplyButton => 'Apply Filters';

  @override
  String get headlinesFeedFilterResetButton => 'Reset Filters';

  @override
  String get headlinesSearchHintText => 'Search Headlines...';

  @override
  String get headlinesSearchInitialHeadline => 'Find Headlines Instantly';

  @override
  String get headlinesSearchInitialSubheadline =>
      'Type keywords above to discover news articles.';

  @override
  String get headlinesSearchNoResultsHeadline => 'No results';

  @override
  String get headlinesSearchNoResultsSubheadline =>
      'Try a different search term';

  @override
  String get authenticationEmailSignInButton => 'Continue with Email';

  @override
  String get authenticationLinkingHeadline => 'Sync Your Data';

  @override
  String get authenticationLinkingSubheadline =>
      'save your settings, content preferences and more across devices.';

  @override
  String get authenticationSignInHeadline => 'Veritas';

  @override
  String get authenticationSignInSubheadline =>
      'Unfiltered news from trusted sources around the world.';

  @override
  String get emailSignInPageTitle => 'Sign in with Email';

  @override
  String get emailSignInExplanation =>
      'Enter your email below. We\'ll send you a secure link to sign in instantly. No password required!';

  @override
  String get emailLinkSentPageTitle => 'Check Your Email';

  @override
  String get emailLinkSentConfirmation =>
      'Link sent! Check your email inbox (and spam folder) for a message from us. Click the link inside to complete your sign-in.';

  @override
  String get accountConnectPrompt => 'Connect Account';

  @override
  String get accountConnectBenefit =>
      'Save your preferences and reading history across devices.';

  @override
  String get bottomNavFeedLabel => 'Feed';

  @override
  String get bottomNavSearchLabel => 'Search';

  @override
  String get bottomNavAccountLabel => 'Account';

  @override
  String get accountNotificationsTile => 'Notifications';

  @override
  String get headlinesSearchActionTooltip => 'Search';

  @override
  String get notificationsTooltip => 'View notifications';

  @override
  String get accountSignInPromptButton => 'Sign Up / Sign In';

  @override
  String get categoryFilterLoadingHeadline => 'Loading Categories...';

  @override
  String get categoryFilterLoadingSubheadline =>
      'Please wait while we fetch the available categories.';

  @override
  String get categoryFilterEmptyHeadline => 'No Categories Found';

  @override
  String get categoryFilterEmptySubheadline =>
      'There are no categories available at the moment.';

  @override
  String get countryFilterLoadingHeadline => 'Loading Countries...';

  @override
  String get countryFilterLoadingSubheadline =>
      'Please wait while we fetch the available countries.';

  @override
  String get countryFilterEmptyHeadline => 'No Countries Found';

  @override
  String get countryFilterEmptySubheadline =>
      'There are no countries available at the moment.';

  @override
  String get headlinesFeedAppBarTitle => 'HT';

  @override
  String get headlinesFeedFilterTooltip => 'Filter Headlines';

  @override
  String get headlinesFeedFilterAllLabel => 'All';

  @override
  String headlinesFeedFilterSelectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String get sourceFilterLoadingHeadline => 'Loading Sources...';

  @override
  String get sourceFilterLoadingSubheadline =>
      'Please wait while we fetch the available sources.';

  @override
  String get sourceFilterEmptyHeadline => 'No Sources Found';

  @override
  String get sourceFilterEmptySubheadline =>
      'There are no sources available at the moment.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLoadingHeadline => 'Loading Settings...';

  @override
  String get settingsLoadingSubheadline =>
      'Please wait while we fetch your preferences.';

  @override
  String get settingsErrorDefault => 'Could not load settings.';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsFeedDisplayTitle => 'Feed Display';

  @override
  String get settingsArticleDisplayTitle => 'Article Display';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsAppearanceThemeModeLight => 'Light';

  @override
  String get settingsAppearanceThemeModeDark => 'Dark';

  @override
  String get settingsAppearanceThemeModeSystem => 'System';

  @override
  String get settingsAppearanceThemeNameRed => 'Red';

  @override
  String get settingsAppearanceThemeNameBlue => 'Blue';

  @override
  String get settingsAppearanceThemeNameGrey => 'Grey';

  @override
  String get settingsAppearanceFontSizeSmall => 'Small';

  @override
  String get settingsAppearanceFontSizeLarge => 'Large';

  @override
  String get settingsAppearanceFontSizeMedium => 'Medium';

  @override
  String get settingsAppearanceThemeModeLabel => 'Theme Mode';

  @override
  String get settingsAppearanceThemeNameLabel => 'Color Scheme';

  @override
  String get settingsAppearanceAppFontSizeLabel => 'App Font Size';

  @override
  String get settingsAppearanceAppFontTypeLabel => 'App Font';

  @override
  String get settingsAppearanceFontWeightLabel => 'Font Weight';

  @override
  String get settingsFeedTileTypeImageTop => 'Image Top';

  @override
  String get settingsFeedTileTypeImageStart => 'Image Start';

  @override
  String get settingsFeedTileTypeTextOnly => 'Text Only';

  @override
  String get settingsFeedTileTypeLabel => 'Feed Tile Layout';

  @override
  String get settingsArticleFontSizeLabel => 'Article Font Size';

  @override
  String get settingsNotificationsEnableLabel => 'Enable Notifications';

  @override
  String get settingsNotificationsCategoriesLabel => 'Followed Categories';

  @override
  String get settingsNotificationsSourcesLabel => 'Followed Sources';

  @override
  String get settingsNotificationsCountriesLabel => 'Followed Countries';

  @override
  String get unknownError => 'An unknown error occurred.';

  @override
  String get loadMoreError => 'Failed to load more items.';

  @override
  String get settingsAppearanceFontSizeExtraLarge => 'Extra Large';

  @override
  String get settingsAppearanceFontFamilySystemDefault => 'System Default';

  @override
  String get settingsAppearanceThemeSubPageTitle => 'Theme Settings';

  @override
  String get settingsAppearanceFontSubPageTitle => 'Font Settings';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get emailCodeSentPageTitle => 'Enter Code';

  @override
  String emailCodeSentConfirmation(String email) {
    return 'A verification code has been sent to $email. Please enter it below.';
  }

  @override
  String get emailCodeSentInstructions =>
      'Enter the 6-digit code you received.';

  @override
  String get emailCodeVerificationHint => '6-digit code';

  @override
  String get emailCodeVerificationButtonLabel => 'Verify Code';

  @override
  String get emailCodeValidationEmptyError => 'Please enter the 6-digit code.';

  @override
  String get emailCodeValidationLengthError => 'The code must be 6 digits.';

  @override
  String get headlinesFeedEmptyFilteredHeadline =>
      'No Headlines Match Your Filters';

  @override
  String get headlinesFeedEmptyFilteredSubheadline =>
      'Try adjusting your filter criteria or clearing them to see all headlines.';

  @override
  String get headlinesFeedClearFiltersButton => 'Clear Filters';

  @override
  String get headlinesFeedFilterLoadingCriteria => 'Loading filter options...';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get headlinesFeedFilterErrorCriteria =>
      'Could not load filter options.';

  @override
  String get headlinesFeedFilterCountryLabel => 'Countries';

  @override
  String get headlinesFeedFilterSourceTypeLabel => 'Types';

  @override
  String get headlinesFeedFilterErrorSources => 'Could not load sources.';

  @override
  String get headlinesFeedFilterNoSourcesMatch =>
      'No sources match your selected filters.';

  @override
  String get searchModelTypeHeadline => 'Headlines';

  @override
  String get searchModelTypeCategory => 'Categories';

  @override
  String get searchModelTypeSource => 'Sources';

  @override
  String get searchModelTypeCountry => 'Countries';

  @override
  String get searchHintTextHeadline => 'e.g., AI advancements, Mars rover...';

  @override
  String get searchHintTextGeneric => 'Search...';

  @override
  String get searchHintTextCategory => 'e.g., Technology, Sports, Finance...';

  @override
  String get searchHintTextSource => 'e.g., BBC News, TechCrunch, Reuters...';

  @override
  String get searchHintTextCountry => 'e.g., USA, Japan, Brazil...';

  @override
  String get searchPageInitialHeadline => 'Start Your Search';

  @override
  String get searchPageInitialSubheadline =>
      'Select a type and enter keywords to begin.';

  @override
  String get followedCategoriesPageTitle => 'Followed Categories';

  @override
  String get addCategoriesTooltip => 'Add Categories';

  @override
  String get noFollowedCategoriesMessage =>
      'You are not following any categories yet.';

  @override
  String get addCategoriesButtonLabel => 'Find Categories to Follow';

  @override
  String unfollowCategoryTooltip(String categoryName) {
    return 'Unfollow $categoryName';
  }

  @override
  String get addTopicsPageTitle => 'Follow Topics';

  @override
  String get topicFilterLoadingHeadline => 'Loading Topics...';

  @override
  String get topicFilterError => 'Could not load topics. Please try again.';

  @override
  String get topicFilterEmptyHeadline => 'No Topics Found';

  @override
  String get topicFilterEmptySubheadline =>
      'There are no topics available at the moment.';

  @override
  String unfollowTopicTooltip(String topicName) {
    return 'Unfollow $topicName';
  }

  @override
  String followTopicTooltip(String topicName) {
    return 'Follow $topicName';
  }

  @override
  String get followedSourcesLoadingHeadline => 'Loading Followed Sources...';

  @override
  String get followedSourcesErrorHeadline => 'Could Not Load Followed Sources';

  @override
  String get followedSourcesEmptyHeadline => 'No Followed Sources';

  @override
  String get followedSourcesEmptySubheadline =>
      'Start following sources to see them here.';

  @override
  String get headlinesFeedFilterTopicLabel => 'Topic';

  @override
  String get followedTopicsPageTitle => 'Followed Topics';

  @override
  String get addTopicsTooltip => 'Add Topics';

  @override
  String get followedTopicsLoadingHeadline => 'Loading Followed Topics...';

  @override
  String get followedTopicsErrorHeadline => 'Could Not Load Followed Topics';

  @override
  String get followedTopicsEmptyHeadline => 'No Followed Topics';

  @override
  String get followedTopicsEmptySubheadline =>
      'Start following topics to see them here.';

  @override
  String get followedSourcesPageTitle => 'Followed Sources';

  @override
  String get addSourcesTooltip => 'Add Sources';

  @override
  String get noFollowedSourcesMessage =>
      'You are not following any sources yet.';

  @override
  String get addSourcesButtonLabel => 'Find Sources to Follow';

  @override
  String unfollowSourceTooltip(String sourceName) {
    return 'Unfollow $sourceName';
  }

  @override
  String get followedCountriesPageTitle => 'Followed Countries';

  @override
  String get addCountriesTooltip => 'Add Countries';

  @override
  String get noFollowedCountriesMessage =>
      'You are not following any countries yet.';

  @override
  String get addCountriesButtonLabel => 'Find Countries to Follow';

  @override
  String unfollowCountryTooltip(String countryName) {
    return 'Unfollow $countryName';
  }

  @override
  String get addCategoriesPageTitle => 'Add Categories to Follow';

  @override
  String get categoryFilterError =>
      'Could not load categories. Please try again.';

  @override
  String followCategoryTooltip(String categoryName) {
    return 'Follow $categoryName';
  }

  @override
  String get addSourcesPageTitle => 'Add Sources to Follow';

  @override
  String get sourceFilterError => 'Could not load sources. Please try again.';

  @override
  String followSourceTooltip(String sourceName) {
    return 'Follow $sourceName';
  }

  @override
  String get addCountriesPageTitle => 'Add Countries to Follow';

  @override
  String followCountryTooltip(String countryName) {
    return 'Follow $countryName';
  }

  @override
  String get headlineDetailsSaveTooltip => 'Save headline';

  @override
  String get headlineDetailsRemoveFromSavedTooltip => 'Remove from saved';

  @override
  String get headlineSavedSuccessSnackbar => 'Headline saved!';

  @override
  String get headlineUnsavedSuccessSnackbar => 'Headline removed from saved.';

  @override
  String get headlineSaveErrorSnackbar =>
      'Could not update saved status. Please try again.';

  @override
  String get shareActionTooltip => 'Share headline';

  @override
  String get sharingUnavailableSnackbar =>
      'Sharing is not available on this device or platform.';

  @override
  String get similarHeadlinesSectionTitle => 'You Might Also Like';

  @override
  String get similarHeadlinesEmpty => 'No similar headlines found.';

  @override
  String get detailsPageTitle => 'Details';

  @override
  String get followButtonLabel => 'Follow';

  @override
  String get unfollowButtonLabel => 'Unfollow';

  @override
  String get noHeadlinesFoundMessage => 'No headlines found for this item.';

  @override
  String get failedToLoadMoreHeadlines => 'Failed to load more headlines.';

  @override
  String get headlinesSectionTitle => 'Headlines';

  @override
  String get headlinesFeedFilterApplyFollowedLabel =>
      'Apply my followed items as filters';

  @override
  String get mustBeLoggedInToUseFeatureError =>
      'You must be logged in to use this feature.';

  @override
  String get noFollowedItemsForFilterSnackbar =>
      'You are not following any items to use as a filter.';

  @override
  String get requestCodePageHeadline => 'Enter Your Email';

  @override
  String get requestCodePageSubheadline =>
      'We\'ll send a secure code to your email to verify your identity.';

  @override
  String get requestCodeEmailLabel => 'Email Address';

  @override
  String get requestCodeEmailHint => 'you@example.com';

  @override
  String get requestCodeSendCodeButton => 'Send Code';

  @override
  String requestCodeResendButtonCooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get entityDetailsCategoryTitle => 'Category';

  @override
  String get entityDetailsSourceTitle => 'Source';

  @override
  String get entityDetailsTopicTitle => 'Topic';

  @override
  String get entityDetailsCountryTitle => 'Country';

  @override
  String get savedHeadlinesLoadingHeadline => 'Loading Saved Headlines...';

  @override
  String get savedHeadlinesLoadingSubheadline =>
      'Please wait while we fetch your saved articles.';

  @override
  String get savedHeadlinesErrorHeadline => 'Could Not Load Saved Headlines';

  @override
  String get savedHeadlinesEmptyHeadline => 'No Saved Headlines';

  @override
  String get savedHeadlinesEmptySubheadline =>
      'You haven\'t saved any articles yet. Start exploring!';

  @override
  String get accountFollowedCountriesTile => 'Followed Countries';

  @override
  String get followedCountriesLoadingHeadline =>
      'Loading Followed Countries...';

  @override
  String get followedCountriesErrorHeadline =>
      'Could Not Load Followed Countries';

  @override
  String get followedCountriesEmptyHeadline => 'No Followed Countries';

  @override
  String get followedCountriesEmptySubheadline =>
      'Start following countries to see them here.';

  @override
  String get countryFilterError =>
      'Could not load countries. Please try again.';

  @override
  String get followedCategoriesLoadingHeadline =>
      'Loading Followed Categories...';

  @override
  String get followedCategoriesErrorHeadline =>
      'Could Not Load Followed Categories';

  @override
  String get followedCategoriesEmptyHeadline => 'No Followed Categories';

  @override
  String get followedCategoriesEmptySubheadline =>
      'Start following categories to see them here.';

  @override
  String demoVerificationCodeMessage(String code) {
    return 'Demo Mode: Use code $code';
  }

  @override
  String demoEmailSuggestionMessage(String email) {
    return 'Demo Mode: Use email $email';
  }

  @override
  String get contentTypeHeadline => 'Headlines';

  @override
  String get contentTypeTopic => 'Topics';

  @override
  String get contentTypeSource => 'Sources';

  @override
  String get contentTypeCountry => 'Countries';

  @override
  String searchingFor(String contentType) {
    return 'Searching for $contentType...';
  }

  @override
  String get settingsAppearanceFontWeightLight => 'Light';

  @override
  String get settingsAppearanceFontWeightRegular => 'Regular';

  @override
  String get settingsAppearanceFontWeightBold => 'Bold';

  @override
  String get maintenanceHeadline => 'Under Maintenance';

  @override
  String get maintenanceSubheadline =>
      'We are currently performing maintenance. Please check back later.';

  @override
  String get updateRequiredHeadline => 'Update Required';

  @override
  String get updateRequiredSubheadline =>
      'A new version of the app is available. Please update to continue using the app.';

  @override
  String get updateRequiredButton => 'Update Now';

  @override
  String get neverShowAgain => 'Never show this again';

  @override
  String get followButtonText => 'Follow';

  @override
  String get unfollowButtonText => 'Unfollow';

  @override
  String get demoNativeAdText => 'NATIVE AD (DEMO)';

  @override
  String get demoBannerAdText => 'BANNER AD (DEMO)';

  @override
  String get demoInterstitialAdText => 'INTERSTITIAL AD (DEMO)';

  @override
  String get demoInterstitialAdDescription =>
      'This is a full-screen advertisement placeholder.';

  @override
  String get adInfoPlaceholderText => 'Ads help keep this app free !';

  @override
  String get retryButtonText => 'Retry';

  @override
  String get headlinesFeedFilterLoadingHeadline => 'Loading Filters';

  @override
  String get suggestedTopicsTitle => 'Suggested Topics';

  @override
  String get suggestedSourcesTitle => 'Suggested Sources';

  @override
  String couldNotOpenUpdateUrl(String url) {
    return 'Could not open update URL: $url';
  }

  @override
  String currentAppVersionLabel(String version) {
    return 'Your current version: $version';
  }

  @override
  String latestRequiredVersionLabel(String version) {
    return 'Required version: $version';
  }

  @override
  String get anonymousLimitTitle => 'Sign in to Do More';

  @override
  String get anonymousLimitBody =>
      'Create a free account to bookmark more and follow more.';

  @override
  String get anonymousLimitButton => 'Sign In';

  @override
  String get standardLimitTitle => 'Unlock More Access';

  @override
  String get standardLimitBody =>
      'You\'ve reached your limit for the free plan. Upgrade to save and follow more.';

  @override
  String get standardLimitButton => 'Upgrade to Premium';

  @override
  String get premiumLimitTitle => 'You\'ve Reached the Limit';

  @override
  String get premiumLimitBody =>
      'To add new items, please review and manage your existing saved and followed content.';

  @override
  String get premiumLimitButton => 'Manage My Content';

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get manageFiltersPageTitle => 'Manage Filters';

  @override
  String get manageFiltersEmptyHeadline => 'No Saved Filters';

  @override
  String get manageFiltersEmptySubheadline =>
      'You can save filters from the filter page.';

  @override
  String get manageFiltersRenameTooltip => 'Rename Filter';

  @override
  String get manageFiltersDeleteTooltip => 'Delete Filter';

  @override
  String get saveFilterDialogTitleSave => 'Save Filter';

  @override
  String get saveFilterDialogTitleRename => 'Rename Filter';

  @override
  String get saveFilterDialogInputLabel => 'Filter Name';

  @override
  String get saveFilterDialogValidationEmpty => 'Name cannot be empty';

  @override
  String get saveFilterDialogValidationTooLong => 'Name is too long';

  @override
  String get headlinesFilterSaveTooltip => 'Save Filter';

  @override
  String get headlinesFilterManageTooltip => 'Manage Filters';

  @override
  String get savedFiltersBarOpenTooltip => 'Open Filters';

  @override
  String get savedFiltersBarAllLabel => 'All';

  @override
  String get savedFiltersBarCustomLabel => 'Custom';

  @override
  String get applyFilterDialogTitle => 'Apply Filter';

  @override
  String get applyFilterDialogContent =>
      'Do you want to apply these filter settings for this session only, or save them for future use?';

  @override
  String get applyFilterDialogApplyOnlyButton => 'Apply Only';

  @override
  String get applyFilterDialogApplyAndSaveButton => 'Apply & Save';

  @override
  String get savedFiltersBarFollowedLabel => 'Followed';

  @override
  String get sourceListFilterPageTitle => 'Filter Sources';

  @override
  String get sourceListFilterPageFilterButtonTooltip => 'Filter source list';

  @override
  String get accountSavedFiltersTile => 'Saved Filters';

  @override
  String get savedFiltersPageTitle => 'Saved Filters';

  @override
  String get savedFiltersEmptyHeadline => 'No Saved Filters';

  @override
  String get savedFiltersEmptySubheadline =>
      'Filters you save from the feed will appear here.';

  @override
  String get savedFiltersMenuRename => 'Rename';

  @override
  String get savedFiltersMenuDelete => 'Delete';

  @override
  String get discoverPageTitle => 'Discover';

  @override
  String get bottomNavDiscoverLabel => 'Discover';

  @override
  String get feedSearchHint => 'Search headlines...';

  @override
  String get headlineSearchEnterQuery =>
      'Find headlines from thousands of sources.';

  @override
  String get headlineSearchEnterQuerySubheadline =>
      'Search by keyword to find articles from thousands of sources.';

  @override
  String get headlineSearchNoResults => 'No headlines found.';

  @override
  String get headlineSearchNoResultsSubheadline =>
      'We couldn\'t find any headlines matching your search. Please try different keywords.';

  @override
  String get accountGuestAccount => 'Guest Account';

  @override
  String get accountRoleStandard => 'Standard User';

  @override
  String get accountRolePremium => 'Premium User';

  @override
  String get deleteConfirmationDialogTitle => 'Confirm Deletion';

  @override
  String get deleteConfirmationDialogContent =>
      'Are you sure you want to delete this item? This action cannot be undone.';

  @override
  String get deleteConfirmationDialogConfirmButton => 'Delete';

  @override
  String get headlineSearchInitialHeadline => 'Search for Headlines';

  @override
  String get headlineSearchInitialSubheadline =>
      'Enter keywords to find articles.';

  @override
  String get accountGuestUserHeadline => 'Guest Account';

  @override
  String get accountGuestUserSubheadline => 'Sign in to sync your data';
}
