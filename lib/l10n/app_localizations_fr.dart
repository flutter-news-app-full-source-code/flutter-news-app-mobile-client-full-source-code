// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get accountLinkingPageTitle => 'Synchronisez votre progression';

  @override
  String get accountLinkingGenericError => 'Une erreur est survenue';

  @override
  String get accountLinkingEmailSentSuccess =>
      'Consultez vos e-mails pour le lien !';

  @override
  String get accountLinkingHeadline => 'Sauvegardez votre progression';

  @override
  String get accountLinkingBody =>
      'Créez un compte pour synchroniser vos éléments suivis et vos préférences sur tous vos appareils.';

  @override
  String get accountLinkingContinueWithGoogleButton => 'Continuer avec Google';

  @override
  String get accountLinkingEmailInputLabel => 'Entrez votre e-mail';

  @override
  String get accountLinkingEmailInputHint => 'vous@exemple.com';

  @override
  String get accountLinkingEmailValidationError =>
      'Veuillez entrer une adresse e-mail valide';

  @override
  String get accountLinkingSendLinkButton => 'Synchroniser par e-mail';

  @override
  String get accountPageTitle => 'Compte';

  @override
  String get accountAnonymousUser => '(Anonyme)';

  @override
  String get accountNoNameUser => 'Sans nom';

  @override
  String get accountStatusAuthenticated => 'Authentifié';

  @override
  String get accountStatusAnonymous => 'Session anonyme';

  @override
  String get accountStatusUnauthenticated => 'Non connecté';

  @override
  String get accountSettingsTile => 'Paramètres';

  @override
  String get accountSignOutTile => 'Déconnexion';

  @override
  String get accountBackupTile =>
      'Créer un compte pour sauvegarder les données';

  @override
  String get accountContentPreferencesTile => 'Contenu suivi';

  @override
  String get accountSavedHeadlinesTile => 'Titres enregistrés';

  @override
  String accountRoleLabel(String role) {
    return 'Rôle : $role';
  }

  @override
  String get accountMyContentSectionTitle => 'Mon contenu';

  @override
  String get accountActivityAndRewardsSectionTitle => 'Activité et récompenses';

  @override
  String get accountGeneralSectionTitle => 'Général';

  @override
  String get accountEditProfileButton => 'Modifier le profil';

  @override
  String get editProfilePageTitle => 'Modifier le profil';

  @override
  String get editProfileNameInputLabel => 'Nom';

  @override
  String get editProfileEmailInputLabel => 'E-mail';

  @override
  String get editProfileUpdateSuccessSnackbar =>
      'Profil mis à jour avec succès.';

  @override
  String get editProfileUpdateFailureSnackbar =>
      'Échec de la mise à jour du profil.';

  @override
  String get followedContentPageTitle => 'Éléments suivis';

  @override
  String get followedContentTopicsTab => 'Sujets';

  @override
  String get followedContentSourcesTab => 'Sources';

  @override
  String get authenticationEmailSentSuccess =>
      'Consultez vos e-mails pour le lien.';

  @override
  String get authenticationPageTitle => 'Connexion / Inscription';

  @override
  String get authenticationEmailLabel => 'E-mail';

  @override
  String get authenticationSendLinkButton => 'Envoyer le lien de connexion';

  @override
  String get authenticationOrDivider => 'OU';

  @override
  String get authenticationGoogleSignInButton => 'Se connecter avec Google';

  @override
  String get authenticationAnonymousSignInButton => 'Continuer anonymement';

  @override
  String get headlineDetailsInitialHeadline => 'En attente de détails';

  @override
  String get headlineDetailsInitialSubheadline => 'Veuillez patienter...';

  @override
  String get headlineDetailsLoadingHeadline => 'Chargement du titre';

  @override
  String get headlineDetailsLoadingSubheadline => 'Récupération des données...';

  @override
  String get headlineDetailsContinueReadingButton => 'Continuer la lecture';

  @override
  String get headlinesFeedLoadingHeadline => 'Chargement...';

  @override
  String get headlinesFeedLoadingSubheadline => 'Récupération des titres';

  @override
  String get headlinesFeedFilterTitle => 'Filtrer les titres';

  @override
  String get headlinesFeedFilterCategoryLabel => 'Catégorie';

  @override
  String get headlinesFeedFilterAllOption => 'Tous';

  @override
  String get headlinesFeedFilterCategoryTechnology => 'Technologie';

  @override
  String get headlinesFeedFilterCategoryBusiness => 'Affaires';

  @override
  String get headlinesFeedFilterCategorySports => 'Sports';

  @override
  String get headlinesFeedFilterSourceLabel => 'Sources';

  @override
  String get headlinesFeedFilterSourceCNN => 'CNN';

  @override
  String get headlinesFeedFilterSourceReuters => 'Reuters';

  @override
  String get headlinesFeedFilterEventCountryLabel => 'Pays';

  @override
  String get headlinesFeedFilterSourceCountryLabel => 'Siège de la source';

  @override
  String get headlinesFeedFilterCountryUS => 'États-Unis';

  @override
  String get headlinesFeedFilterCountryUK => 'Royaume-Uni';

  @override
  String get headlinesFeedFilterCountryCA => 'Canada';

  @override
  String get headlinesFeedFilterApplyButton => 'Appliquer les filtres';

  @override
  String get headlinesFeedFilterResetButton => 'Réinitialiser les filtres';

  @override
  String get headlinesSearchHintText => 'Rechercher des titres...';

  @override
  String get headlinesSearchInitialHeadline =>
      'Trouvez des titres instantanément';

  @override
  String get headlinesSearchInitialSubheadline =>
      'Tapez des mots-clés pour découvrir des articles.';

  @override
  String get headlinesSearchNoResultsHeadline => 'Aucun résultat';

  @override
  String get headlinesSearchNoResultsSubheadline =>
      'Essayez un autre terme de recherche';

  @override
  String get authenticationEmailSignInButton => 'Continuer avec l\'e-mail';

  @override
  String get authenticationLinkingHeadline => 'Synchronisez votre progression';

  @override
  String get authenticationLinkingSubheadline =>
      'Créez un compte pour sauvegarder vos paramètres et préférences.';

  @override
  String get authenticationSignInHeadline => 'Veritas';

  @override
  String get authenticationSignInSubheadline =>
      'Des nouvelles non filtrées de sources fiables.';

  @override
  String get emailSignInPageTitle => 'Se connecter par e-mail';

  @override
  String get emailSignInExplanation =>
      'Entrez votre e-mail. Nous vous enverrons un lien sécurisé.';

  @override
  String get emailLinkSentPageTitle => 'Vérifiez vos e-mails';

  @override
  String get emailLinkSentConfirmation =>
      'Lien envoyé ! Vérifiez votre boîte de réception.';

  @override
  String get accountConnectPrompt => 'Connecter le compte';

  @override
  String get accountConnectBenefit =>
      'Sauvegardez vos préférences sur tous vos appareils.';

  @override
  String get bottomNavFeedLabel => 'Flux';

  @override
  String get bottomNavSearchLabel => 'Recherche';

  @override
  String get bottomNavAccountLabel => 'Compte';

  @override
  String get accountNotificationsTile => 'Notifications';

  @override
  String get headlinesSearchActionTooltip => 'Rechercher';

  @override
  String get notificationsTooltip => 'Voir les notifications';

  @override
  String get accountSignInPromptButton => 'S\'inscrire / Se connecter';

  @override
  String get categoryFilterLoadingHeadline => 'Chargement des catégories...';

  @override
  String get categoryFilterLoadingSubheadline => 'Veuillez patienter...';

  @override
  String get categoryFilterEmptyHeadline => 'Aucune catégorie trouvée';

  @override
  String get categoryFilterEmptySubheadline =>
      'Il n\'y a aucune catégorie disponible.';

  @override
  String get countryFilterLoadingHeadline => 'Chargement des pays...';

  @override
  String get countryFilterLoadingSubheadline => 'Veuillez patienter...';

  @override
  String get countryFilterEmptyHeadline => 'Aucun pays trouvé';

  @override
  String get countryFilterEmptySubheadline =>
      'Il n\'y a aucun pays disponible.';

  @override
  String get headlinesFeedAppBarTitle => 'HT';

  @override
  String get headlinesFeedFilterTooltip => 'Filtrer les titres';

  @override
  String get headlinesFeedFilterAllLabel => 'Tout';

  @override
  String headlinesFeedFilterSelectedCountLabel(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get sourceFilterLoadingHeadline => 'Chargement des sources...';

  @override
  String get sourceFilterLoadingSubheadline => 'Veuillez patienter...';

  @override
  String get sourceFilterEmptyHeadline => 'Aucune source trouvée';

  @override
  String get sourceFilterEmptySubheadline =>
      'Il n\'y a aucune source disponible.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLoadingHeadline => 'Chargement des paramètres...';

  @override
  String get settingsLoadingSubheadline => 'Veuillez patienter...';

  @override
  String get settingsErrorDefault => 'Impossible de charger les paramètres.';

  @override
  String get settingsAppearanceTitle => 'Apparence';

  @override
  String get settingsFeedDisplayTitle => 'Flux';

  @override
  String get settingsArticleDisplayTitle => 'Affichage de l\'article';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsAppearanceThemeModeLight => 'Clair';

  @override
  String get settingsAppearanceThemeModeDark => 'Sombre';

  @override
  String get settingsAppearanceThemeModeSystem => 'Système';

  @override
  String get settingsAppearanceThemeNameRed => 'Rouge';

  @override
  String get settingsAppearanceThemeNameBlue => 'Bleu';

  @override
  String get settingsAppearanceThemeNameGrey => 'Gris';

  @override
  String get settingsAppearanceFontSizeSmall => 'Petit';

  @override
  String get settingsAppearanceFontSizeLarge => 'Grand';

  @override
  String get settingsAppearanceFontSizeMedium => 'Moyen';

  @override
  String get settingsAppearanceThemeModeLabel => 'Mode du thème';

  @override
  String get settingsAppearanceThemeNameLabel => 'Schéma de couleurs';

  @override
  String get settingsAppearanceAppFontSizeLabel => 'Taille de police de l\'app';

  @override
  String get settingsAppearanceAppFontTypeLabel => 'Police de l\'app';

  @override
  String get settingsAppearanceFontWeightLabel => 'Graisse de la police';

  @override
  String get settingsFeedTileTypeImageTop => 'Image en haut';

  @override
  String get settingsFeedTileTypeImageStart => 'Image au début';

  @override
  String get settingsFeedTileTypeTextOnly => 'Texte uniquement';

  @override
  String get settingsFeedTileTypeLabel => 'Mise en page du flux';

  @override
  String get settingsArticleFontSizeLabel => 'Taille de police de l\'article';

  @override
  String get settingsNotificationsEnableLabel => 'Activer les notifications';

  @override
  String get settingsNotificationsCategoriesLabel => 'Catégories suivies';

  @override
  String get settingsNotificationsSourcesLabel => 'Sources suivies';

  @override
  String get settingsNotificationsCountriesLabel => 'Pays suivis';

  @override
  String get settingsAppearanceSectionTitle => 'APPARENCE';

  @override
  String get settingsFeedSectionTitle => 'FLUX';

  @override
  String get settingsGeneralSectionTitle => 'GÉNÉRAL';

  @override
  String get settingsAccentColorAndFontsTitle =>
      'Couleur d\'accentuation et polices';

  @override
  String get settingsAccentColorLabel => 'Couleur d\'accentuation';

  @override
  String get settingsFontFamilyLabel => 'Famille de polices';

  @override
  String get settingsLayoutAndReadingTitle => 'Mise en page et lecture';

  @override
  String get appName => 'Headlines Toolkit';

  @override
  String get unknownError => 'Une erreur inconnue est survenue.';

  @override
  String get loadMoreError => 'Échec du chargement de plus d\'éléments.';

  @override
  String get settingsAppearanceFontSizeExtraLarge => 'Très grand';

  @override
  String get settingsAppearanceFontFamilySystemDefault => 'Défaut système';

  @override
  String get settingsAppearanceFontFamilyRoboto => 'Roboto';

  @override
  String get settingsAppearanceFontFamilyOpenSans => 'Open Sans';

  @override
  String get settingsAppearanceThemeSubPageTitle => 'Paramètres du thème';

  @override
  String get settingsAppearanceFontSubPageTitle => 'Paramètres de police';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get emailCodeSentPageTitle => 'Entrez le code';

  @override
  String emailCodeSentConfirmation(String email) {
    return 'Un code a été envoyé à $email. Saisissez-le.';
  }

  @override
  String get emailCodeSentInstructions => 'Entrez le code à 6 chiffres reçu.';

  @override
  String get emailCodeVerificationHint => 'Code à 6 chiffres';

  @override
  String get emailCodeVerificationButtonLabel => 'Vérifier le code';

  @override
  String get emailCodeValidationEmptyError => 'Veuillez entrer le code.';

  @override
  String get emailCodeValidationLengthError =>
      'Le code doit comporter 6 chiffres.';

  @override
  String get headlinesFeedEmptyFilteredHeadline => 'Aucun titre ne correspond';

  @override
  String get headlinesFeedEmptyFilteredSubheadline =>
      'Essayez d\'ajuster vos filtres.';

  @override
  String get headlinesFeedClearFiltersButton => 'Effacer les filtres';

  @override
  String get headlinesFeedFilterLoadingCriteria => 'Chargement des critères...';

  @override
  String get pleaseWait => 'Veuillez patienter...';

  @override
  String get headlinesFeedFilterErrorCriteria =>
      'Impossible de charger les critères.';

  @override
  String get headlinesFeedFilterCountryLabel => 'Pays';

  @override
  String get headlinesFeedFilterSourceTypeLabel => 'Types';

  @override
  String get headlinesFeedFilterErrorSources =>
      'Impossible de charger les sources.';

  @override
  String get headlinesFeedFilterNoSourcesMatch =>
      'Aucune source ne correspond.';

  @override
  String get searchModelTypeHeadline => 'Titres';

  @override
  String get searchModelTypeCategory => 'Catégories';

  @override
  String get searchModelTypeSource => 'Sources';

  @override
  String get searchModelTypeCountry => 'Pays';

  @override
  String get searchHintTextHeadline => 'ex: IA, Mars rover...';

  @override
  String get searchHintTextGeneric => 'Rechercher...';

  @override
  String get searchHintTextCategory => 'ex: Technologie, Sports...';

  @override
  String get searchHintTextSource => 'ex: BBC News, Reuters...';

  @override
  String get searchHintTextCountry => 'ex: France, Japon...';

  @override
  String get searchPageInitialHeadline => 'Commencez votre recherche';

  @override
  String get searchPageInitialSubheadline =>
      'Sélectionnez un type et entrez des mots-clés.';

  @override
  String get followedCategoriesPageTitle => 'Catégories suivies';

  @override
  String get addCategoriesTooltip => 'Ajouter des catégories';

  @override
  String get noFollowedCategoriesMessage => 'Vous ne suivez aucune catégorie.';

  @override
  String get addCategoriesButtonLabel => 'Trouver des catégories à suivre';

  @override
  String unfollowCategoryTooltip(String categoryName) {
    return 'Ne plus suivre $categoryName';
  }

  @override
  String get addTopicsPageTitle => 'Suivre des sujets';

  @override
  String get topicFilterLoadingHeadline => 'Chargement des sujets...';

  @override
  String get topicFilterError => 'Impossible de charger les sujets.';

  @override
  String get topicFilterEmptyHeadline => 'Aucun sujet trouvé';

  @override
  String get topicFilterEmptySubheadline =>
      'Aucun sujet disponible pour le moment.';

  @override
  String unfollowTopicTooltip(String topicName) {
    return 'Ne plus suivre $topicName';
  }

  @override
  String followTopicTooltip(String topicName) {
    return 'Suivre $topicName';
  }

  @override
  String get followedSourcesLoadingHeadline =>
      'Chargement des sources suivies...';

  @override
  String get followedSourcesErrorHeadline =>
      'Impossible de charger les sources suivies';

  @override
  String get followedSourcesEmptyHeadline => 'Aucune source suivie';

  @override
  String get followedSourcesEmptySubheadline =>
      'Commencez à suivre des sources.';

  @override
  String get headlinesFeedFilterTopicLabel => 'Sujet';

  @override
  String get followedTopicsPageTitle => 'Sujets suivis';

  @override
  String get addTopicsTooltip => 'Ajouter des sujets';

  @override
  String get followedTopicsLoadingHeadline => 'Chargement des sujets suivis...';

  @override
  String get followedTopicsErrorHeadline =>
      'Impossible de charger les sujets suivis';

  @override
  String get followedTopicsEmptyHeadline => 'Aucun sujet suivi';

  @override
  String get followedTopicsEmptySubheadline => 'Commencez à suivre des sujets.';

  @override
  String get followedSourcesPageTitle => 'Sources suivies';

  @override
  String get addSourcesTooltip => 'Ajouter des sources';

  @override
  String get noFollowedSourcesMessage => 'Vous ne suivez aucune source.';

  @override
  String get addSourcesButtonLabel => 'Trouver des sources à suivre';

  @override
  String unfollowSourceTooltip(String sourceName) {
    return 'Ne plus suivre $sourceName';
  }

  @override
  String get followedCountriesPageTitle => 'Pays suivis';

  @override
  String get addCountriesTooltip => 'Ajouter des pays';

  @override
  String get noFollowedCountriesMessage => 'Vous ne suivez aucun pays.';

  @override
  String get addCountriesButtonLabel => 'Trouver des pays à suivre';

  @override
  String unfollowCountryTooltip(String countryName) {
    return 'Ne plus suivre $countryName';
  }

  @override
  String get addCategoriesPageTitle => 'Ajouter des catégories';

  @override
  String get categoryFilterError => 'Impossible de charger les catégories.';

  @override
  String followCategoryTooltip(String categoryName) {
    return 'Suivre $categoryName';
  }

  @override
  String get addSourcesPageTitle => 'Ajouter des sources';

  @override
  String get sourceFilterError => 'Impossible de charger les sources.';

  @override
  String followSourceTooltip(String sourceName) {
    return 'Suivre $sourceName';
  }

  @override
  String get addCountriesPageTitle => 'Ajouter des pays';

  @override
  String followCountryTooltip(String countryName) {
    return 'Suivre $countryName';
  }

  @override
  String get headlineDetailsSaveTooltip => 'Enregistrer le titre';

  @override
  String get headlineDetailsRemoveFromSavedTooltip =>
      'Supprimer des enregistrements';

  @override
  String get headlineSavedSuccessSnackbar => 'Titre enregistré !';

  @override
  String get headlineUnsavedSuccessSnackbar =>
      'Titre supprimé des enregistrements.';

  @override
  String get headlineSaveErrorSnackbar => 'Erreur lors de la mise à jour.';

  @override
  String get shareActionTooltip => 'Partager le titre';

  @override
  String get sharingUnavailableSnackbar =>
      'Le partage n\'est pas disponible sur cet appareil.';

  @override
  String get similarHeadlinesSectionTitle => 'Vous pourriez aussi aimer';

  @override
  String get similarHeadlinesEmpty => 'Aucun titre similaire trouvé.';

  @override
  String get detailsPageTitle => 'Détails';

  @override
  String get followButtonLabel => 'Suivre';

  @override
  String get unfollowButtonLabel => 'Ne plus suivre';

  @override
  String get noHeadlinesFoundMessage => 'Aucun titre trouvé pour cet élément.';

  @override
  String get failedToLoadMoreHeadlines =>
      'Échec du chargement de plus de titres.';

  @override
  String get headlinesSectionTitle => 'Titres';

  @override
  String get headlinesFeedFilterApplyFollowedLabel =>
      'Appliquer mes éléments suivis comme filtres';

  @override
  String get mustBeLoggedInToUseFeatureError =>
      'Vous devez être connecté pour utiliser cette fonctionnalité.';

  @override
  String get noFollowedItemsForFilterSnackbar =>
      'Vous ne suivez aucun élément à utiliser comme filtre.';

  @override
  String get requestCodePageHeadline => 'Entrez votre e-mail';

  @override
  String get requestCodePageSubheadline =>
      'Nous vous enverrons un code sécurisé.';

  @override
  String get requestCodeEmailLabel => 'Adresse e-mail';

  @override
  String get requestCodeEmailHint => 'vous@exemple.com';

  @override
  String get requestCodeSendCodeButton => 'Envoyer le code';

  @override
  String requestCodeResendButtonCooldown(int seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get entityDetailsCategoryTitle => 'Catégorie';

  @override
  String get entityDetailsSourceTitle => 'Source';

  @override
  String get entityDetailsTopicTitle => 'Sujet';

  @override
  String get entityDetailsCountryTitle => 'Pays';

  @override
  String get savedHeadlinesLoadingHeadline =>
      'Chargement des titres enregistrés...';

  @override
  String get savedHeadlinesLoadingSubheadline => 'Veuillez patienter...';

  @override
  String get savedHeadlinesErrorHeadline =>
      'Impossible de charger les titres enregistrés';

  @override
  String get savedHeadlinesEmptyHeadline => 'Aucun titre enregistré';

  @override
  String get savedHeadlinesEmptySubheadline => 'Commencez à explorer !';

  @override
  String get accountFollowedCountriesTile => 'Pays suivis';

  @override
  String get followedCountriesLoadingHeadline =>
      'Chargement des pays suivis...';

  @override
  String get followedCountriesErrorHeadline =>
      'Impossible de charger les pays suivis';

  @override
  String get followedCountriesEmptyHeadline => 'Aucun pays suivi';

  @override
  String get followedCountriesEmptySubheadline =>
      'Commencez à suivre des pays.';

  @override
  String get countryFilterError => 'Impossible de charger les pays.';

  @override
  String get followedCategoriesLoadingHeadline =>
      'Chargement des catégories suivies...';

  @override
  String get followedCategoriesErrorHeadline =>
      'Impossible de charger les catégories suivies';

  @override
  String get followedCategoriesEmptyHeadline => 'Aucune catégorie suivie';

  @override
  String get followedCategoriesEmptySubheadline =>
      'Commencez à suivre des catégories.';

  @override
  String get contentTypeHeadline => 'Titres';

  @override
  String get contentTypeTopic => 'Sujets';

  @override
  String get contentTypeSource => 'Sources';

  @override
  String get contentTypeCountry => 'Pays';

  @override
  String searchingFor(String contentType) {
    return 'Recherche de $contentType...';
  }

  @override
  String get settingsAppearanceFontWeightLight => 'Léger';

  @override
  String get settingsAppearanceFontWeightRegular => 'Régulier';

  @override
  String get settingsAppearanceFontWeightBold => 'Gras';

  @override
  String get maintenanceHeadline => 'En maintenance';

  @override
  String get maintenanceSubheadline =>
      'Nous effectuons une maintenance. Revenez plus tard.';

  @override
  String get updateRequiredHeadline => 'Mise à jour requise';

  @override
  String get updateRequiredSubheadline =>
      'Une nouvelle version est disponible.';

  @override
  String get updateRequiredButton => 'Mettre à jour maintenant';

  @override
  String get neverShowAgain => 'Ne plus jamais afficher';

  @override
  String get followButtonText => 'Suivre';

  @override
  String get unfollowButtonText => 'Ne plus suivre';

  @override
  String get adInfoPlaceholderText =>
      'Les publicités aident à garder cette application gratuite !';

  @override
  String get retryButtonText => 'Réessayer';

  @override
  String get headlinesFeedFilterLoadingHeadline => 'Chargement des filtres';

  @override
  String get suggestedTopicsTitle => 'Sujets suggérés';

  @override
  String get suggestedSourcesTitle => 'Sources suggérées';

  @override
  String couldNotOpenUpdateUrl(String url) {
    return 'Impossible d\'ouvrir l\'URL : $url';
  }

  @override
  String currentAppVersionLabel(String version) {
    return 'Version actuelle : $version';
  }

  @override
  String latestRequiredVersionLabel(String version) {
    return 'Version requise : $version';
  }

  @override
  String get anonymousLimitTitle => 'Connectez-vous pour en faire plus';

  @override
  String get anonymousLimitBody =>
      'Créez un compte gratuit pour enregistrer et suivre plus d\'éléments.';

  @override
  String get anonymousLimitButton => 'Se connecter';

  @override
  String get standardLimitBody =>
      'Limite atteinte pour le plan gratuit. Passez à Premium.';

  @override
  String get standardLimitButton => 'Passer à Premium';

  @override
  String get premiumLimitTitle => 'Limite atteinte';

  @override
  String get premiumLimitBody =>
      'Veuillez gérer votre contenu existant pour ajouter de nouveaux éléments.';

  @override
  String get premiumLimitButton => 'Gérer mon contenu';

  @override
  String get saveButtonLabel => 'Enregistrer';

  @override
  String get cancelButtonLabel => 'Annuler';

  @override
  String get manageFiltersPageTitle => 'Gérer les filtres';

  @override
  String get manageFiltersEmptyHeadline => 'Aucun filtre enregistré';

  @override
  String get manageFiltersEmptySubheadline =>
      'Vous pouvez enregistrer des filtres depuis la page de flux.';

  @override
  String get manageFiltersRenameTooltip => 'Renommer le filtre';

  @override
  String get manageFiltersDeleteTooltip => 'Supprimer le filtre';

  @override
  String get saveFilterDialogTitleSave => 'Enregistrer le filtre';

  @override
  String get saveFilterDialogTitleRename => 'Renommer le filtre';

  @override
  String get saveFilterDialogInputLabel => 'Nom du filtre';

  @override
  String get saveFilterDialogValidationEmpty => 'Le nom ne peut pas être vide';

  @override
  String get saveFilterDialogValidationTooLong => 'Le nom est trop long';

  @override
  String get saveFilterDialogGenericError =>
      'Une erreur est survenue lors de l\'enregistrement.';

  @override
  String get headlinesFilterSaveTooltip => 'Enregistrer le filtre';

  @override
  String get headlinesFilterManageTooltip => 'Gérer les filtres';

  @override
  String get savedFiltersBarOpenTooltip => 'Ouvrir les filtres';

  @override
  String get savedFiltersBarAllLabel => 'Tout';

  @override
  String get savedFiltersBarCustomLabel => 'Personnalisé';

  @override
  String get applyFilterDialogTitle => 'Appliquer le filtre';

  @override
  String get applyFilterDialogContent =>
      'Voulez-vous appliquer ces paramètres pour cette session ou les enregistrer ?';

  @override
  String get applyFilterDialogApplyOnlyButton => 'Appliquer uniquement';

  @override
  String get applyFilterDialogApplyAndSaveButton => 'Appliquer et enregistrer';

  @override
  String get savedFiltersBarFollowedLabel => 'Suivi';

  @override
  String get sourceListFilterPageTitle => 'Filtrer les sources';

  @override
  String get sourceListFilterPageFilterButtonTooltip =>
      'Filtrer la liste des sources';

  @override
  String get sourceListFilterByHeadquartersPageTitle => 'Lieu du siège';

  @override
  String get savedFiltersPageTitle => 'Filtres enregistrés';

  @override
  String get savedFiltersEmptyHeadline => 'Aucun filtre enregistré';

  @override
  String get savedFiltersEmptySubheadline =>
      'Les filtres enregistrés apparaîtront ici.';

  @override
  String get savedFiltersMenuRename => 'Renommer';

  @override
  String get savedFiltersMenuDelete => 'Supprimer';

  @override
  String get discoverPageTitle => 'Découvrir';

  @override
  String get bottomNavDiscoverLabel => 'Découvrir';

  @override
  String get feedSearchHint => 'Rechercher des titres...';

  @override
  String get headlineSearchEnterQuery =>
      'Trouvez des titres parmi des milliers de sources.';

  @override
  String get headlineSearchEnterQuerySubheadline => 'Recherchez par mot-clé.';

  @override
  String get headlineSearchNoResults => 'Aucun titre trouvé.';

  @override
  String get headlineSearchNoResultsSubheadline =>
      'Essayez d\'autres mots-clés.';

  @override
  String get accountGuestAccount => 'Compte invité';

  @override
  String get accountRoleStandard => 'Utilisateur Standard';

  @override
  String get accountRolePremium => 'Utilisateur Premium';

  @override
  String get deleteConfirmationDialogTitle => 'Confirmer la suppression';

  @override
  String get deleteConfirmationDialogContent =>
      'Êtes-vous sûr ? Cette action est irréversible.';

  @override
  String get deleteConfirmationDialogConfirmButton => 'Supprimer';

  @override
  String get headlineSearchInitialHeadline => 'Rechercher des titres';

  @override
  String get headlineSearchInitialSubheadline => 'Entrez des mots-clés.';

  @override
  String get accountGuestUserHeadline => 'Compte invité';

  @override
  String get accountGuestUserSubheadline =>
      'Connectez-vous pour synchroniser vos données';

  @override
  String get discoverSearchHint => 'Rechercher des sources...';

  @override
  String get seeAllButtonLabel => 'Voir tout';

  @override
  String get failedToLoadMoreSources =>
      'Échec du chargement de plus de sources.';

  @override
  String get sourceTypeNewsAgency => 'Agence de presse';

  @override
  String get sourceTypeLocalNewsOutlet => 'Média local';

  @override
  String get sourceTypeNationalNewsOutlet => 'Média national';

  @override
  String get sourceTypeInternationalNewsOutlet => 'Média international';

  @override
  String get sourceTypeSpecializedPublisher => 'Éditeur spécialisé';

  @override
  String get sourceTypeBlog => 'Blog';

  @override
  String get sourceTypeGovernmentSource => 'Source gouvernementale';

  @override
  String get sourceTypeAggregator => 'Agrégateur';

  @override
  String get sourceTypeOther => 'Autre';

  @override
  String get sourceTypeNewsAgencies => 'Agences de presse';

  @override
  String get sourceTypeLocalNewsOutlets => 'Médias locaux';

  @override
  String get sourceTypeNationalNewsOutlets => 'Médias nationaux';

  @override
  String get sourceTypeInternationalNewsOutlets => 'Médias internationaux';

  @override
  String get sourceTypeSpecializedPublishers => 'Éditeurs spécialisés';

  @override
  String get sourceTypeBlogs => 'Blogs';

  @override
  String get sourceTypeGovernmentSources => 'Sources gouvernementales';

  @override
  String get sourceTypeAggregators => 'Agrégateurs';

  @override
  String get sourceTypeOthers => 'Autres';

  @override
  String get sourceTypeFilterEmptyHeadline => 'Aucun type de source trouvé';

  @override
  String get sourceTypeFilterEmptySubheadline =>
      'Aucun type de source disponible.';

  @override
  String get decoratorDismissedConfirmation => 'Suggestion masquée.';

  @override
  String get decoratorDismissAction => 'Masquer la suggestion';

  @override
  String get decoratorLinkAccountTitle_1 =>
      'Sauvegardez vos articles et préférences';

  @override
  String get decoratorLinkAccountTitle_2 => 'Ne perdez jamais vos préférences';

  @override
  String get decoratorLinkAccountDescription_1 =>
      'Créez un compte gratuit pour synchroniser vos données.';

  @override
  String get decoratorLinkAccountDescription_2 =>
      'Inscrivez-vous pour débloquer plus de sauvegardes.';

  @override
  String get decoratorLinkAccountCta_1 => 'S\'inscrire maintenant';

  @override
  String get decoratorLinkAccountCta_2 => 'Créer un compte gratuit';

  @override
  String get decoratorUpgradeTitle_1 =>
      'Profitez d\'une expérience sans interruption';

  @override
  String get decoratorUpgradeTitle_2 => 'Débloquez votre accès Premium';

  @override
  String get decoratorUpgradeDescription_1 =>
      'Passez au sans publicité et augmentez vos limites.';

  @override
  String get decoratorUpgradeDescription_2 =>
      'Passez à Premium pour une expérience optimale.';

  @override
  String get decoratorUpgradeCta_1 => 'Passer à Premium';

  @override
  String get decoratorUpgradeCta_2 => 'En savoir plus';

  @override
  String get decoratorRateAppTitle_1 => 'Vous aimez l\'application ?';

  @override
  String get decoratorRateAppTitle_2 => 'Partagez votre avis';

  @override
  String get decoratorRateAppDescription_1 =>
      'Votre note nous aide à nous améliorer.';

  @override
  String get decoratorRateAppDescription_2 =>
      'Prenez un moment pour nous évaluer !';

  @override
  String get decoratorRateAppCta_1 => 'Noter maintenant';

  @override
  String get decoratorRateAppCta_2 => 'Donner un avis';

  @override
  String get decoratorEnableNotificationsTitle_1 =>
      'Ne manquez aucune actualité';

  @override
  String get decoratorEnableNotificationsTitle_2 =>
      'Restez informé instantanément';

  @override
  String get decoratorEnableNotificationsDescription_1 =>
      'Recevez des alertes pour les actualités brûlantes.';

  @override
  String get decoratorEnableNotificationsDescription_2 =>
      'Activez les notifications personnalisées.';

  @override
  String get decoratorEnableNotificationsCta_1 => 'Activer les alertes';

  @override
  String get decoratorEnableNotificationsCta_2 => 'Activer les notifications';

  @override
  String get decoratorSuggestedTopicsTitle_1 =>
      'Découvrez de nouveaux intérêts';

  @override
  String get decoratorSuggestedTopicsTitle_2 => 'Élargissez vos connaissances';

  @override
  String get decoratorSuggestedSourcesTitle_1 =>
      'Trouvez de nouvelles perspectives';

  @override
  String get decoratorSuggestedSourcesTitle_2 =>
      'Découvrez des sources fiables';

  @override
  String get savedHeadlineFiltersPageTitle => 'Filtres enregistrés';

  @override
  String get savedHeadlineFiltersCreateNewButton => 'Créer un filtre';

  @override
  String get savedHeadlineFiltersLoadingHeadline =>
      'Chargement de vos filtres...';

  @override
  String get savedHeadlineFiltersEmptyHeadline => 'Aucun filtre enregistré';

  @override
  String get savedHeadlineFiltersEmptySubheadline =>
      'Vos filtres apparaîtront ici.';

  @override
  String get savedFiltersMenuEdit => 'Modifier';

  @override
  String get saveFilterDialogPinToFeedLabel => 'Épingler à la barre de filtres';

  @override
  String get saveFilterDialogNotificationsLabel =>
      'Préférences de notification';

  @override
  String get notificationDeliveryTypeBreakingOnly => 'Actualités brûlantes';

  @override
  String get notificationDeliveryTypeDailyDigest => 'Résumé quotidien';

  @override
  String get notificationDeliveryTypeWeeklyRoundup => 'Synthèse hebdomadaire';

  @override
  String get prePermissionDialogTitle => 'Activer les notifications ?';

  @override
  String get prePermissionDialogBody =>
      'Pour recevoir des alertes, veuillez autoriser les notifications.';

  @override
  String get prePermissionDialogDenyButton => 'Pas maintenant';

  @override
  String get prePermissionDialogAllowButton => 'Autoriser';

  @override
  String get notificationPermissionDeniedError =>
      'Permission refusée. Activez-la dans les paramètres.';

  @override
  String get notificationCenterPageTitle => 'Notifications';

  @override
  String get notificationCenterMarkAllAsReadButton => 'Tout marquer comme lu';

  @override
  String get notificationCenterLoadingHeadline =>
      'Chargement des notifications...';

  @override
  String get notificationCenterLoadingSubheadline => 'Veuillez patienter...';

  @override
  String get notificationCenterFailureHeadline => 'Échec du chargement';

  @override
  String get notificationCenterFailureSubheadline =>
      'Impossible de récupérer vos notifications.';

  @override
  String get notificationCenterEmptyHeadline => 'Aucune notification';

  @override
  String get notificationCenterEmptySubheadline =>
      'Vous n\'avez aucune nouvelle notification.';

  @override
  String get notificationCenterTabBreakingNews => 'Actualités brûlantes';

  @override
  String get notificationCenterTabDigests => 'Résumés';

  @override
  String get deleteReadNotificationsButtonTooltip =>
      'Supprimer les notifications lues';

  @override
  String get deleteReadNotificationsDialogContent =>
      'Voulez-vous supprimer toutes les notifications lues ?';

  @override
  String get deleteButtonLabel => 'Supprimer';

  @override
  String get breakingNewsPrefix => 'Flash Info';

  @override
  String get settingsFeedClickBehaviorLabel => 'Ouvrir les liens avec';

  @override
  String get settingsFeedClickBehaviorDefault => 'Défaut de l\'app';

  @override
  String get settingsFeedClickBehaviorInApp => 'Navigateur intégré';

  @override
  String get settingsFeedClickBehaviorSystem => 'Navigateur système';

  @override
  String get continueToArticleButtonLabel => 'Continuer vers l\'article';

  @override
  String get headlineActionsModalTitle => 'Actions';

  @override
  String get shareActionLabel => 'Partager';

  @override
  String get bookmarkActionLabel => 'Signet';

  @override
  String get removeBookmarkActionLabel => 'Supprimer le signet';

  @override
  String get reportActionLabel => 'Signaler';

  @override
  String get reportContentTitle => 'Signaler le contenu';

  @override
  String get reportReasonSelectionPrompt => 'Veuillez sélectionner un motif :';

  @override
  String get reportAdditionalCommentsLabel =>
      'Commentaires supplémentaires (Optionnel)';

  @override
  String get reportSubmitButtonLabel => 'Envoyer le signalement';

  @override
  String get reportSuccessSnackbar =>
      'Signalement envoyé. Merci pour votre retour.';

  @override
  String get reportFailureSnackbar => 'Échec de l\'envoi du signalement.';

  @override
  String get commentsTitle => 'Commentaires';

  @override
  String get commentPostButtonLabel => 'Publier';

  @override
  String get commentInputHint => 'Ajouter un commentaire...';

  @override
  String get commentRequiresReactionError =>
      'Veuillez sélectionner une réaction.';

  @override
  String get likeActionLabel => 'J\'aime';

  @override
  String get dislikeActionLabel => 'Je n\'aime pas';

  @override
  String get commentActionLabel => 'Commenter';

  @override
  String get moreActionLabel => 'Plus';

  @override
  String get rateAppPromptTitle => 'Vous aimez l\'application ?';

  @override
  String get rateAppPromptBody => 'Votre avis nous aide à nous améliorer.';

  @override
  String get rateAppPromptYesButton => 'C\'est génial !';

  @override
  String get rateAppPromptNoButton => 'À améliorer';

  @override
  String get feedbackPromptTitle => 'Comment pouvons-nous nous améliorer ?';

  @override
  String get feedbackPromptReasonUI => 'Interface / Design';

  @override
  String get feedbackPromptReasonPerformance => 'Performance / Vitesse';

  @override
  String get feedbackPromptReasonContent => 'Qualité du contenu';

  @override
  String get feedbackPromptReasonOther => 'Autre';

  @override
  String get feedbackPromptSubmitButton => 'Envoyer l\'avis';

  @override
  String get rateAppNegativeFollowUpTitle_1 =>
      'Comment allons-nous maintenant ?';

  @override
  String get rateAppNegativeFollowUpTitle_2 => 'Nous sommes-nous améliorés ?';

  @override
  String get rateAppNegativeFollowUpBody_1 =>
      'Nous avons travaillé sur vos retours.';

  @override
  String get rateAppNegativeFollowUpBody_2 =>
      'Dites-nous si les choses vont mieux.';

  @override
  String get noCommentsYet => 'Aucun commentaire pour l\'instant.';

  @override
  String get commentInputNoReactionHint => 'Réagissez pour commenter';

  @override
  String get headlineReportReasonMisinformation =>
      'Désinformation ou fausse nouvelle';

  @override
  String get headlineReportReasonClickbait => 'Titre trompeur ou putaclic';

  @override
  String get headlineReportReasonOffensive => 'Contenu offensant ou haineux';

  @override
  String get headlineReportReasonSpam => 'Spam ou arnaque';

  @override
  String get headlineReportReasonBrokenLink => 'Lien mort';

  @override
  String get headlineReportReasonPaywalled => 'Contenu payant';

  @override
  String get sourceReportReasonLowQuality => 'Journalisme de basse qualité';

  @override
  String get sourceReportReasonHighAdDensity => 'Publicités excessives';

  @override
  String get sourceReportReasonFrequentPaywalls => 'Paywalls fréquents';

  @override
  String get sourceReportReasonImpersonation => 'Usurpation d\'identité';

  @override
  String get sourceReportReasonMisinformation => 'Désinformation';

  @override
  String get commentReportReasonSpam => 'Spam ou publicité';

  @override
  String get commentReportReasonHarassment => 'Harcèlement ou intimidation';

  @override
  String get commentReportReasonHateSpeech => 'Discours de haine';

  @override
  String get limitReachedTitle => 'Limite atteinte';

  @override
  String get manageMyContentButton => 'Gérer mon contenu';

  @override
  String get upgradeButton => 'Mettre à niveau';

  @override
  String get createAccountButton => 'Créer un compte';

  @override
  String get gotItButton => 'Compris';

  @override
  String get commentsPageTitle => 'Commentaires';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires',
      one: '1 commentaire',
    );
    return '$_temp0';
  }

  @override
  String get limitReachedGuestUserTitle => 'Compte requis';

  @override
  String get limitReachedGuestUserBody =>
      'Veuillez créer un compte pour interagir avec la communauté.';

  @override
  String get limitReachedBodyFollow => 'Limite d\'éléments suivis atteinte.';

  @override
  String get limitReachedBodySave => 'Limite d\'articles enregistrés atteinte.';

  @override
  String get limitReachedBodySaveFilters =>
      'Limite de filtres enregistrés atteinte.';

  @override
  String get limitReachedBodyPinFilters =>
      'Limite de filtres épinglés atteinte.';

  @override
  String get limitReachedBodySubscribeToNotifications =>
      'Limite d\'abonnements aux notifications atteinte.';

  @override
  String get limitReachedBodyComments =>
      'Limite quotidienne de commentaires atteinte.';

  @override
  String get limitReachedBodyReactions =>
      'Limite quotidienne de réactions atteinte.';

  @override
  String get limitReachedBodyReports =>
      'Limite quotidienne de signalements atteinte.';

  @override
  String get commentEditButtonLabel => 'Mettre à jour';

  @override
  String get commentPostFailureSnackbar =>
      'Échec de la publication du commentaire.';

  @override
  String get commentUpdateFailureSnackbar =>
      'Échec de la mise à jour du commentaire.';

  @override
  String get commentInputDisabledHint => 'Connectez-vous pour participer';

  @override
  String get commentInputExistingHint => 'Vous avez déjà commenté ce titre.';

  @override
  String commenterName(String id) {
    return 'Utilisateur $id';
  }

  @override
  String get accountRewardsTile => 'Récompenses et offres';

  @override
  String get rewardsPageTitle => 'Récompenses';

  @override
  String rewardsOfferTitle(String rewardName, String duration) {
    return 'Obtenez $rewardName pour $duration';
  }

  @override
  String rewardsOfferActiveTitle(String rewardName) {
    return '$rewardName actif';
  }

  @override
  String rewardsOfferExpiresIn(String countdown) {
    return 'Expire dans : $countdown';
  }

  @override
  String get rewardsOfferWatchButton => 'Regarder la vidéo';

  @override
  String get rewardsOfferVerifyingButton => 'Vérification...';

  @override
  String get rewardsOfferLoadingButton => 'Chargement de la pub...';

  @override
  String rewardsSnackbarSuccess(String rewardName) {
    return 'Récompense débloquée : $rewardName.';
  }

  @override
  String get rewardsSnackbarFailure => 'Échec de la vérification.';

  @override
  String get rewardsAdDismissedSnackbar =>
      'Publicité fermée. Regardez-la en entier pour la récompense.';

  @override
  String get decoratorUnlockRewardsTitle =>
      'Débloquez une expérience sans publicité';

  @override
  String decoratorUnlockRewardsDescription(String duration) {
    return 'Regardez une vidéo pour supprimer les pubs pendant $duration.';
  }

  @override
  String get decoratorUnlockRewardsCta => 'Regarder maintenant';

  @override
  String rewardsDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get rewardTypeAdFree => 'Sans publicité';

  @override
  String get rewardTypeDailyDigest => 'Résumé quotidien';

  @override
  String get unlockMoreButton => 'Débloquer plus';

  @override
  String get requiresActiveReward => 'Nécessite une récompense active.';

  @override
  String get rewardsAdFreeTitle => 'Profitez d\'une expérience sans publicité';

  @override
  String rewardsAdFreeDescription(String duration) {
    return 'Regardez une vidéo pour supprimer les pubs pendant $duration.';
  }

  @override
  String get rewardsDailyDigestTitle => 'Débloquez les résumés quotidiens';

  @override
  String rewardsDailyDigestDescription(String duration) {
    return 'Recevez une notification quotidienne résumant les titres. Actif pour $duration.';
  }

  @override
  String get rewardsOfferActiveButton => 'Actif';

  @override
  String get rewardsAdFreePageTitle => 'Expérience sans publicité';

  @override
  String get rewardsAdFreeInactiveHeadline => 'Profitez du sans publicité';

  @override
  String rewardsAdFreeInactiveBody(String duration) {
    return 'Regardez une pub pour $duration sans interruption.';
  }

  @override
  String get rewardsAdFreeActiveHeadline => 'Le sans publicité est actif';

  @override
  String get rewardsAdFreeActiveBody => 'Votre accès expire dans :';

  @override
  String get appTourStep1Title => 'Vos actualités, parfaitement adaptées';

  @override
  String get appTourStep1Body =>
      'Suivez les sujets, sources et pays qui vous importent.';

  @override
  String get appTourStep2Title => 'Organisez et soyez notifié';

  @override
  String get appTourStep2Body =>
      'Créez des flux personnalisés et abonnez-vous aux alertes.';

  @override
  String get appTourStep3Title => 'Partagez votre perspective';

  @override
  String get appTourStep3Body =>
      'Réagissez et commentez pour engager la conversation.';

  @override
  String get appTourSkipButton => 'Passer';

  @override
  String get appTourNextButton => 'Suivant';

  @override
  String get appTourGetStartedButton => 'Commencer';

  @override
  String get initialPersonalizationTitle => 'Personnalisez votre flux';

  @override
  String get initialPersonalizationSubtitle =>
      'Suivez des éléments pour commencer.';

  @override
  String get initialPersonalizationStepTopicsTitle => 'Sujets';

  @override
  String get initialPersonalizationStepSourcesTitle => 'Sources';

  @override
  String get initialPersonalizationStepCountriesTitle => 'Pays';

  @override
  String initialPersonalizationTotalSelectionCountLabel(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get initialPersonalizationFinishButton => 'Terminer';

  @override
  String get deleteAccountDialogTitle => 'Supprimer le compte';

  @override
  String get deleteAccountDialogContent =>
      'Voulez-vous supprimer définitivement votre compte ?';

  @override
  String get deleteAccountDialogConfirm => 'Supprimer le compte';

  @override
  String get deleteAccountButton => 'Supprimer le compte';

  @override
  String get followedContentEmpty =>
      'Vous ne suivez aucun élément dans cette catégorie.';

  @override
  String get followedContentEmptySubheadline =>
      'Utilisez le bouton \'+\' pour en ajouter.';

  @override
  String multiSelectSearchPageSelectionCount(int count, int total) {
    return '$count/$total';
  }

  @override
  String get guestUserDisplayName => 'Invité';

  @override
  String get accountPageSyncProgressButton => 'Synchroniser la progression';

  @override
  String get applyButtonLabel => 'Appliquer';

  @override
  String get commentStatusPending => 'En cours de révision';
}
