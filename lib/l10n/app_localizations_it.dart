// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get accountLinkingPageTitle => 'Sincronizza i tuoi progressi';

  @override
  String get accountLinkingGenericError => 'Si è verificato un errore';

  @override
  String get accountLinkingEmailSentSuccess =>
      'Controlla la tua email per il link di accesso!';

  @override
  String get accountLinkingHeadline => 'Salva i tuoi progressi';

  @override
  String get accountLinkingBody =>
      'Crea un account per sincronizzare gli elementi seguiti e le preferenze su tutti i tuoi dispositivi.';

  @override
  String get accountLinkingContinueWithGoogleButton => 'Continua con Google';

  @override
  String get accountLinkingEmailInputLabel => 'Inserisci la tua email';

  @override
  String get accountLinkingEmailInputHint => 'tu@esempio.com';

  @override
  String get accountLinkingEmailValidationError =>
      'Inserisci un indirizzo email valido';

  @override
  String get accountLinkingSendLinkButton => 'Sincronizza con Email';

  @override
  String get accountPageTitle => 'Account';

  @override
  String get accountAnonymousUser => '(Anonimo)';

  @override
  String get accountNoNameUser => 'Nessun nome';

  @override
  String get accountStatusAuthenticated => 'Autenticato';

  @override
  String get accountStatusAnonymous => 'Sessione anonima';

  @override
  String get accountStatusUnauthenticated => 'Non connesso';

  @override
  String get accountSettingsTile => 'Impostazioni';

  @override
  String get accountSignOutTile => 'Esci';

  @override
  String get accountBackupTile => 'Crea un account per salvare i dati';

  @override
  String get accountContentPreferencesTile => 'Contenuti seguiti';

  @override
  String get accountSavedHeadlinesTile => 'Notizie salvate';

  @override
  String accountRoleLabel(String role) {
    return 'Ruolo: $role';
  }

  @override
  String get accountMyContentSectionTitle => 'I miei contenuti';

  @override
  String get accountActivityAndRewardsSectionTitle => 'Attività e ricompense';

  @override
  String get accountGeneralSectionTitle => 'Generale';

  @override
  String get accountEditProfileButton => 'Modifica profilo';

  @override
  String get editProfilePageTitle => 'Modifica profilo';

  @override
  String get editProfileNameInputLabel => 'Nome';

  @override
  String get editProfileEmailInputLabel => 'Email';

  @override
  String get editProfileUpdateSuccessSnackbar =>
      'Profilo aggiornato con successo.';

  @override
  String get editProfileUpdateFailureSnackbar =>
      'Impossibile aggiornare il profilo. Riprova.';

  @override
  String get followedContentPageTitle => 'Elementi seguiti';

  @override
  String get followedContentTopicsTab => 'Argomenti';

  @override
  String get followedContentSourcesTab => 'Fonti';

  @override
  String get authenticationEmailSentSuccess =>
      'Controlla la tua email per il link di accesso.';

  @override
  String get authenticationPageTitle => 'Accedi / Registrati';

  @override
  String get authenticationEmailLabel => 'Email';

  @override
  String get authenticationSendLinkButton => 'Invia link di accesso';

  @override
  String get authenticationOrDivider => 'O';

  @override
  String get authenticationGoogleSignInButton => 'Accedi con Google';

  @override
  String get authenticationAnonymousSignInButton => 'Continua in modo anonimo';

  @override
  String get headlineDetailsInitialHeadline => 'In attesa di dettagli';

  @override
  String get headlineDetailsInitialSubheadline => 'Attendere prego...';

  @override
  String get headlineDetailsLoadingHeadline => 'Caricamento notizia';

  @override
  String get headlineDetailsLoadingSubheadline => 'Recupero dati in corso...';

  @override
  String get headlineDetailsContinueReadingButton => 'Continua a leggere';

  @override
  String get headlinesFeedLoadingHeadline => 'Caricamento...';

  @override
  String get headlinesFeedLoadingSubheadline => 'Recupero notizie in corso';

  @override
  String get headlinesFeedFilterTitle => 'Filtra notizie';

  @override
  String get headlinesFeedFilterCategoryLabel => 'Categoria';

  @override
  String get headlinesFeedFilterAllOption => 'Tutti';

  @override
  String get headlinesFeedFilterCategoryTechnology => 'Tecnologia';

  @override
  String get headlinesFeedFilterCategoryBusiness => 'Affari';

  @override
  String get headlinesFeedFilterCategorySports => 'Sport';

  @override
  String get headlinesFeedFilterSourceLabel => 'Fonti';

  @override
  String get headlinesFeedFilterSourceCNN => 'CNN';

  @override
  String get headlinesFeedFilterSourceReuters => 'Reuters';

  @override
  String get headlinesFeedFilterEventCountryLabel => 'Paesi';

  @override
  String get headlinesFeedFilterSourceCountryLabel => 'Sede della fonte';

  @override
  String get headlinesFeedFilterCountryUS => 'Stati Uniti';

  @override
  String get headlinesFeedFilterCountryUK => 'Regno Unito';

  @override
  String get headlinesFeedFilterCountryCA => 'Canada';

  @override
  String get headlinesFeedFilterApplyButton => 'Applica filtri';

  @override
  String get headlinesFeedFilterResetButton => 'Reimposta filtri';

  @override
  String get headlinesSearchHintText => 'Cerca notizie...';

  @override
  String get headlinesSearchInitialHeadline => 'Trova notizie all\'istante';

  @override
  String get headlinesSearchInitialSubheadline =>
      'Digita le parole chiave qui sopra per scoprire articoli di notizie.';

  @override
  String get headlinesSearchNoResultsHeadline => 'Nessun risultato';

  @override
  String get headlinesSearchNoResultsSubheadline =>
      'Prova un termine di ricerca diverso';

  @override
  String get authenticationEmailSignInButton => 'Continua con l\'email';

  @override
  String get authenticationLinkingHeadline => 'Sincronizza i tuoi progressi';

  @override
  String get authenticationLinkingSubheadline =>
      'Crea un account per salvare le tue impostazioni, preferenze sui contenuti e altro su tutti i dispositivi.';

  @override
  String get authenticationSignInHeadline => 'Verity';

  @override
  String get authenticationSignInSubheadline =>
      'Notizie non filtrate da fonti attendibili di tutto il mondo.';

  @override
  String get emailSignInPageTitle => 'Accedi con l\'email';

  @override
  String get emailSignInExplanation =>
      'Inserisci la tua email qui sotto. Ti invieremo un link sicuro per accedere immediatamente. Nessuna password richiesta!';

  @override
  String get emailLinkSentPageTitle => 'Controlla la tua email';

  @override
  String get emailLinkSentConfirmation =>
      'Link inviato! Controlla la tua casella di posta (e la cartella spam) per un nostro messaggio. Clicca sul link all\'interno per completare l\'accesso.';

  @override
  String get accountConnectPrompt => 'Collega account';

  @override
  String get accountConnectBenefit =>
      'Salva le tue preferenze e la cronologia di lettura su tutti i dispositivi.';

  @override
  String get bottomNavFeedLabel => 'Feed';

  @override
  String get bottomNavSearchLabel => 'Cerca';

  @override
  String get bottomNavAccountLabel => 'Account';

  @override
  String get accountNotificationsTile => 'Notifiche';

  @override
  String get headlinesSearchActionTooltip => 'Cerca';

  @override
  String get notificationsTooltip => 'Visualizza notifiche';

  @override
  String get accountSignInPromptButton => 'Registrati / Accedi';

  @override
  String get categoryFilterLoadingHeadline => 'Caricamento categorie...';

  @override
  String get categoryFilterLoadingSubheadline =>
      'Attendere prego mentre recuperiamo le categorie disponibili.';

  @override
  String get categoryFilterEmptyHeadline => 'Nessuna categoria trovata';

  @override
  String get categoryFilterEmptySubheadline =>
      'Al momento non ci sono categorie disponibili.';

  @override
  String get countryFilterLoadingHeadline => 'Caricamento paesi...';

  @override
  String get countryFilterLoadingSubheadline =>
      'Attendere prego mentre recuperiamo i paesi disponibili.';

  @override
  String get countryFilterEmptyHeadline => 'Nessun paese trovato';

  @override
  String get countryFilterEmptySubheadline =>
      'Al momento non ci sono paesi disponibili.';

  @override
  String get headlinesFeedAppBarTitle => 'HT';

  @override
  String get headlinesFeedFilterTooltip => 'Filtra notizie';

  @override
  String get headlinesFeedFilterAllLabel => 'Tutti';

  @override
  String headlinesFeedFilterSelectedCountLabel(int count) {
    return '$count selezionati';
  }

  @override
  String get sourceFilterLoadingHeadline => 'Caricamento fonti...';

  @override
  String get sourceFilterLoadingSubheadline =>
      'Attendere prego mentre recuperiamo le fonti disponibili.';

  @override
  String get sourceFilterEmptyHeadline => 'Nessuna fonte trovata';

  @override
  String get sourceFilterEmptySubheadline =>
      'Al momento non ci sono fonti disponibili.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLoadingHeadline => 'Caricamento impostazioni...';

  @override
  String get settingsLoadingSubheadline =>
      'Attendere prego mentre recuperiamo le tue preferenze.';

  @override
  String get settingsErrorDefault => 'Impossibile caricare le impostazioni.';

  @override
  String get settingsAppearanceTitle => 'Aspetto';

  @override
  String get settingsFeedDisplayTitle => 'Feed';

  @override
  String get settingsArticleDisplayTitle => 'Visualizzazione articolo';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsAppearanceThemeModeLight => 'Chiaro';

  @override
  String get settingsAppearanceThemeModeDark => 'Scuro';

  @override
  String get settingsAppearanceThemeModeSystem => 'Sistema';

  @override
  String get settingsAppearanceThemeNameRed => 'Rosso';

  @override
  String get settingsAppearanceThemeNameBlue => 'Blu';

  @override
  String get settingsAppearanceThemeNameGrey => 'Grigio';

  @override
  String get settingsAppearanceFontSizeSmall => 'Piccolo';

  @override
  String get settingsAppearanceFontSizeLarge => 'Grande';

  @override
  String get settingsAppearanceFontSizeMedium => 'Medio';

  @override
  String get settingsAppearanceThemeModeLabel => 'Modalità tema';

  @override
  String get settingsAppearanceThemeNameLabel => 'Schema colori';

  @override
  String get settingsAppearanceAppFontSizeLabel => 'Dimensione carattere app';

  @override
  String get settingsAppearanceAppFontTypeLabel => 'Carattere app';

  @override
  String get settingsAppearanceFontWeightLabel => 'Spessore carattere';

  @override
  String get settingsFeedTileTypeImageTop => 'Immagine in alto';

  @override
  String get settingsFeedTileTypeImageStart => 'Immagine all\'inizio';

  @override
  String get settingsFeedTileTypeTextOnly => 'Solo testo';

  @override
  String get settingsFeedTileTypeLabel => 'Layout riquadro feed';

  @override
  String get settingsArticleFontSizeLabel => 'Dimensione carattere articolo';

  @override
  String get settingsNotificationsEnableLabel => 'Abilita notifiche';

  @override
  String get settingsNotificationsCategoriesLabel => 'Categorie seguite';

  @override
  String get settingsNotificationsSourcesLabel => 'Fonti seguite';

  @override
  String get settingsNotificationsCountriesLabel => 'Paesi seguiti';

  @override
  String get settingsAppearanceSectionTitle => 'ASPETTO';

  @override
  String get settingsFeedSectionTitle => 'FEED';

  @override
  String get settingsGeneralSectionTitle => 'GENERALE';

  @override
  String get settingsAccentColorAndFontsTitle =>
      'Colore d\'accento e caratteri';

  @override
  String get settingsAccentColorLabel => 'Colore d\'accento';

  @override
  String get settingsFontFamilyLabel => 'Famiglia di caratteri';

  @override
  String get settingsLayoutAndReadingTitle => 'Layout e lettura';

  @override
  String get appName => 'News App';

  @override
  String get unknownError => 'Si è verificato un errore sconosciuto.';

  @override
  String get loadMoreError => 'Impossibile caricare altri elementi.';

  @override
  String get settingsAppearanceFontSizeExtraLarge => 'Molto grande';

  @override
  String get settingsAppearanceFontFamilySystemDefault =>
      'Predefinito di sistema';

  @override
  String get settingsAppearanceFontFamilyRoboto => 'Roboto';

  @override
  String get settingsAppearanceFontFamilyOpenSans => 'Open Sans';

  @override
  String get settingsAppearanceThemeSubPageTitle => 'Impostazioni tema';

  @override
  String get settingsAppearanceFontSubPageTitle => 'Impostazioni carattere';

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get emailCodeSentPageTitle => 'Inserisci codice';

  @override
  String emailCodeSentConfirmation(String email) {
    return 'Un codice di verifica è stato inviato a $email. Inseriscilo qui sotto.';
  }

  @override
  String get emailCodeSentInstructions =>
      'Inserisci il codice a 6 cifre che hai ricevuto.';

  @override
  String get emailCodeVerificationHint => 'Codice a 6 cifre';

  @override
  String get emailCodeVerificationButtonLabel => 'Verifica codice';

  @override
  String get emailCodeValidationEmptyError => 'Inserisci il codice a 6 cifre.';

  @override
  String get emailCodeValidationLengthError =>
      'Il codice deve essere di 6 cifre.';

  @override
  String get headlinesFeedEmptyFilteredHeadline =>
      'Nessuna notizia corrisponde ai tuoi filtri';

  @override
  String get headlinesFeedEmptyFilteredSubheadline =>
      'Prova a modificare i criteri di filtro o a cancellarli per vedere tutte le notizie.';

  @override
  String get headlinesFeedClearFiltersButton => 'Cancella filtri';

  @override
  String get headlinesFeedFilterLoadingCriteria =>
      'Caricamento opzioni di filtro...';

  @override
  String get pleaseWait => 'Attendere prego...';

  @override
  String get headlinesFeedFilterErrorCriteria =>
      'Impossibile caricare le opzioni di filtro.';

  @override
  String get headlinesFeedFilterCountryLabel => 'Paesi';

  @override
  String get headlinesFeedFilterSourceTypeLabel => 'Tipi';

  @override
  String get headlinesFeedFilterErrorSources =>
      'Impossibile caricare le fonti.';

  @override
  String get headlinesFeedFilterNoSourcesMatch =>
      'Nessuna fonte corrisponde ai filtri selezionati.';

  @override
  String get searchModelTypeHeadline => 'Notizie';

  @override
  String get searchModelTypeCategory => 'Categorie';

  @override
  String get searchModelTypeSource => 'Fonti';

  @override
  String get searchModelTypeCountry => 'Paesi';

  @override
  String get searchHintTextHeadline => 'es. progressi IA, rover su Marte...';

  @override
  String get searchHintTextGeneric => 'Cerca...';

  @override
  String get searchHintTextCategory => 'es. Tecnologia, Sport, Finanza...';

  @override
  String get searchHintTextSource => 'es. BBC News, TechCrunch, Reuters...';

  @override
  String get searchHintTextCountry => 'es. USA, Giappone, Brasile...';

  @override
  String get searchPageInitialHeadline => 'Inizia la tua ricerca';

  @override
  String get searchPageInitialSubheadline =>
      'Seleziona un tipo e inserisci le parole chiave per iniziare.';

  @override
  String get followedCategoriesPageTitle => 'Categorie seguite';

  @override
  String get addCategoriesTooltip => 'Aggiungi categorie';

  @override
  String get noFollowedCategoriesMessage =>
      'Non stai ancora seguendo nessuna categoria.';

  @override
  String get addCategoriesButtonLabel => 'Trova categorie da seguire';

  @override
  String unfollowCategoryTooltip(String categoryName) {
    return 'Smetti di seguire $categoryName';
  }

  @override
  String get addTopicsPageTitle => 'Segui argomenti';

  @override
  String get topicFilterLoadingHeadline => 'Caricamento argomenti...';

  @override
  String get topicFilterError => 'Impossibile caricare gli argomenti. Riprova.';

  @override
  String get topicFilterEmptyHeadline => 'Nessun argomento trovato';

  @override
  String get topicFilterEmptySubheadline =>
      'Al momento non ci sono argomenti disponibili.';

  @override
  String unfollowTopicTooltip(String topicName) {
    return 'Smetti di seguire $topicName';
  }

  @override
  String followTopicTooltip(String topicName) {
    return 'Segui $topicName';
  }

  @override
  String get followedSourcesLoadingHeadline => 'Caricamento fonti seguite...';

  @override
  String get followedSourcesErrorHeadline =>
      'Impossibile caricare le fonti seguite';

  @override
  String get followedSourcesEmptyHeadline => 'Nessuna fonte seguita';

  @override
  String get followedSourcesEmptySubheadline =>
      'Inizia a seguire le fonti per vederle qui.';

  @override
  String get headlinesFeedFilterTopicLabel => 'Argomento';

  @override
  String get followedTopicsPageTitle => 'Argomenti seguiti';

  @override
  String get addTopicsTooltip => 'Aggiungi argomenti';

  @override
  String get followedTopicsLoadingHeadline =>
      'Caricamento argomenti seguiti...';

  @override
  String get followedTopicsErrorHeadline =>
      'Impossibile caricare gli argomenti seguiti';

  @override
  String get followedTopicsEmptyHeadline => 'Nessun argomento seguito';

  @override
  String get followedTopicsEmptySubheadline =>
      'Inizia a seguire gli argomenti per vederli qui.';

  @override
  String get followedSourcesPageTitle => 'Fonti seguite';

  @override
  String get addSourcesTooltip => 'Aggiungi fonti';

  @override
  String get noFollowedSourcesMessage =>
      'Non stai ancora seguendo nessuna fonte.';

  @override
  String get addSourcesButtonLabel => 'Trova fonti da seguire';

  @override
  String unfollowSourceTooltip(String sourceName) {
    return 'Smetti di seguire $sourceName';
  }

  @override
  String get followedCountriesPageTitle => 'Paesi seguiti';

  @override
  String get addCountriesTooltip => 'Aggiungi paesi';

  @override
  String get noFollowedCountriesMessage =>
      'Non stai ancora seguendo nessun paese.';

  @override
  String get addCountriesButtonLabel => 'Trova paesi da seguire';

  @override
  String unfollowCountryTooltip(String countryName) {
    return 'Smetti di seguire $countryName';
  }

  @override
  String get addCategoriesPageTitle => 'Aggiungi categorie da seguire';

  @override
  String get categoryFilterError =>
      'Impossibile caricare le categorie. Riprova.';

  @override
  String followCategoryTooltip(String categoryName) {
    return 'Segui $categoryName';
  }

  @override
  String get addSourcesPageTitle => 'Aggiungi fonti da seguire';

  @override
  String get sourceFilterError => 'Impossibile caricare le fonti. Riprova.';

  @override
  String followSourceTooltip(String sourceName) {
    return 'Segui $sourceName';
  }

  @override
  String get addCountriesPageTitle => 'Aggiungi paesi da seguire';

  @override
  String followCountryTooltip(String countryName) {
    return 'Segui $countryName';
  }

  @override
  String get headlineDetailsSaveTooltip => 'Salva notizia';

  @override
  String get headlineDetailsRemoveFromSavedTooltip => 'Rimuovi dai salvati';

  @override
  String get headlineSavedSuccessSnackbar => 'Notizia salvata!';

  @override
  String get headlineUnsavedSuccessSnackbar => 'Notizia rimossa dai salvati.';

  @override
  String get headlineSaveErrorSnackbar =>
      'Impossibile aggiornare lo stato di salvataggio. Riprova.';

  @override
  String get shareActionTooltip => 'Condividi notizia';

  @override
  String get sharingUnavailableSnackbar =>
      'La condivisione non è disponibile su questo dispositivo o piattaforma.';

  @override
  String get similarHeadlinesSectionTitle => 'Potrebbe piacerti anche';

  @override
  String get similarHeadlinesEmpty => 'Nessuna notizia simile trovata.';

  @override
  String get detailsPageTitle => 'Dettagli';

  @override
  String get followButtonLabel => 'Segui';

  @override
  String get unfollowButtonLabel => 'Smetti di seguire';

  @override
  String get noHeadlinesFoundMessage =>
      'Nessuna notizia trovata per questo elemento.';

  @override
  String get failedToLoadMoreHeadlines => 'Impossibile caricare altre notizie.';

  @override
  String get headlinesSectionTitle => 'Notizie';

  @override
  String get headlinesFeedFilterApplyFollowedLabel =>
      'Applica i miei elementi seguiti come filtri';

  @override
  String get mustBeLoggedInToUseFeatureError =>
      'Devi essere loggato per usare questa funzionalità.';

  @override
  String get noFollowedItemsForFilterSnackbar =>
      'Non stai seguendo alcun elemento da usare come filtro.';

  @override
  String get requestCodePageHeadline => 'Inserisci la tua email';

  @override
  String get requestCodePageSubheadline =>
      'Ti invieremo un codice sicuro alla tua email per verificare la tua identità.';

  @override
  String get requestCodeEmailLabel => 'Indirizzo email';

  @override
  String get requestCodeEmailHint => 'tu@esempio.com';

  @override
  String get requestCodeSendCodeButton => 'Invia codice';

  @override
  String requestCodeResendButtonCooldown(int seconds) {
    return 'Reinvia tra ${seconds}s';
  }

  @override
  String get entityDetailsCategoryTitle => 'Categoria';

  @override
  String get entityDetailsSourceTitle => 'Fonte';

  @override
  String get entityDetailsTopicTitle => 'Argomento';

  @override
  String get entityDetailsCountryTitle => 'Paese';

  @override
  String get savedHeadlinesLoadingHeadline => 'Caricamento notizie salvate...';

  @override
  String get savedHeadlinesLoadingSubheadline =>
      'Attendere prego mentre recuperiamo i tuoi articoli salvati.';

  @override
  String get savedHeadlinesErrorHeadline =>
      'Impossibile caricare le notizie salvate';

  @override
  String get savedHeadlinesEmptyHeadline => 'Nessuna notizia salvata';

  @override
  String get savedHeadlinesEmptySubheadline =>
      'Non hai ancora salvato nessun articolo. Inizia a esplorare!';

  @override
  String get accountFollowedCountriesTile => 'Paesi seguiti';

  @override
  String get followedCountriesLoadingHeadline => 'Caricamento paesi seguiti...';

  @override
  String get followedCountriesErrorHeadline =>
      'Impossibile caricare i paesi seguiti';

  @override
  String get followedCountriesEmptyHeadline => 'Nessun paese seguito';

  @override
  String get followedCountriesEmptySubheadline =>
      'Inizia a seguire i paesi per vederli qui.';

  @override
  String get countryFilterError => 'Impossibile caricare i paesi. Riprova.';

  @override
  String get followedCategoriesLoadingHeadline =>
      'Caricamento categorie seguite...';

  @override
  String get followedCategoriesErrorHeadline =>
      'Impossibile caricare le categorie seguite';

  @override
  String get followedCategoriesEmptyHeadline => 'Nessuna categoria seguita';

  @override
  String get followedCategoriesEmptySubheadline =>
      'Inizia a seguire le categorie per vederle qui.';

  @override
  String get contentTypeHeadline => 'Notizie';

  @override
  String get contentTypeTopic => 'Argomenti';

  @override
  String get contentTypeSource => 'Fonti';

  @override
  String get contentTypeCountry => 'Paesi';

  @override
  String searchingFor(String contentType) {
    return 'Ricerca di $contentType in corso...';
  }

  @override
  String get settingsAppearanceFontWeightLight => 'Leggero';

  @override
  String get settingsAppearanceFontWeightRegular => 'Normale';

  @override
  String get settingsAppearanceFontWeightBold => 'Grassetto';

  @override
  String get maintenanceHeadline => 'In manutenzione';

  @override
  String get maintenanceSubheadline =>
      'Stiamo effettuando manutenzione. Riprova più tardi.';

  @override
  String get updateRequiredHeadline => 'Aggiornamento richiesto';

  @override
  String get updateRequiredSubheadline =>
      'È disponibile una nuova versione dell\'app. Aggiorna per continuare a utilizzare l\'app.';

  @override
  String get updateRequiredButton => 'Aggiorna ora';

  @override
  String get neverShowAgain => 'Non mostrare più';

  @override
  String get followButtonText => 'Segui';

  @override
  String get unfollowButtonText => 'Smetti di seguire';

  @override
  String get adInfoPlaceholderText =>
      'Le pubblicità aiutano a mantenere questa app gratuita!';

  @override
  String get retryButtonText => 'Riprova';

  @override
  String get headlinesFeedFilterLoadingHeadline => 'Caricamento filtri';

  @override
  String get suggestedTopicsTitle => 'Argomenti suggeriti';

  @override
  String get suggestedSourcesTitle => 'Fonti suggerite';

  @override
  String couldNotOpenUpdateUrl(String url) {
    return 'Impossibile aprire l\'URL di aggiornamento: $url';
  }

  @override
  String currentAppVersionLabel(String version) {
    return 'La tua versione attuale: $version';
  }

  @override
  String latestRequiredVersionLabel(String version) {
    return 'Versione richiesta: $version';
  }

  @override
  String get anonymousLimitTitle => 'Accedi per fare di più';

  @override
  String get anonymousLimitBody =>
      'Crea un account gratuito per salvare più segnalibri e seguire più contenuti.';

  @override
  String get anonymousLimitButton => 'Accedi';

  @override
  String get standardLimitBody =>
      'Hai raggiunto il limite per il piano gratuito. Esegui l\'upgrade per salvare e seguire più contenuti.';

  @override
  String get standardLimitButton => 'Passa a Premium';

  @override
  String get premiumLimitTitle => 'Hai raggiunto il limite';

  @override
  String get premiumLimitBody =>
      'Per aggiungere nuovi elementi, controlla e gestisci i tuoi contenuti salvati e seguiti esistenti.';

  @override
  String get premiumLimitButton => 'Gestisci i miei contenuti';

  @override
  String get saveButtonLabel => 'Salva';

  @override
  String get cancelButtonLabel => 'Annulla';

  @override
  String get manageFiltersPageTitle => 'Gestisci filtri';

  @override
  String get manageFiltersEmptyHeadline => 'Nessun filtro salvato';

  @override
  String get manageFiltersEmptySubheadline =>
      'Puoi salvare i filtri dalla pagina dei filtri.';

  @override
  String get manageFiltersRenameTooltip => 'Rinomina filtro';

  @override
  String get manageFiltersDeleteTooltip => 'Elimina filtro';

  @override
  String get saveFilterDialogTitleSave => 'Salva filtro';

  @override
  String get saveFilterDialogTitleRename => 'Rinomina filtro';

  @override
  String get saveFilterDialogInputLabel => 'Nome filtro';

  @override
  String get saveFilterDialogValidationEmpty => 'Il nome non può essere vuoto';

  @override
  String get saveFilterDialogValidationTooLong => 'Il nome è troppo lungo';

  @override
  String get saveFilterDialogGenericError =>
      'Si è verificato un errore imprevisto durante il salvataggio del filtro.';

  @override
  String get headlinesFilterSaveTooltip => 'Salva filtro';

  @override
  String get headlinesFilterManageTooltip => 'Gestisci filtri';

  @override
  String get savedFiltersBarOpenTooltip => 'Apri filtri';

  @override
  String get savedFiltersBarAllLabel => 'Tutti';

  @override
  String get savedFiltersBarCustomLabel => 'Personalizzato';

  @override
  String get applyFilterDialogTitle => 'Applica filtro';

  @override
  String get applyFilterDialogContent =>
      'Vuoi applicare queste impostazioni di filtro solo per questa sessione o salvarle per un uso futuro?';

  @override
  String get applyFilterDialogApplyOnlyButton => 'Applica solo';

  @override
  String get applyFilterDialogApplyAndSaveButton => 'Applica e salva';

  @override
  String get savedFiltersBarFollowedLabel => 'Seguiti';

  @override
  String get sourceListFilterPageTitle => 'Filtra fonti';

  @override
  String get sourceListFilterPageFilterButtonTooltip => 'Filtra elenco fonti';

  @override
  String get sourceListFilterByHeadquartersPageTitle => 'Sede centrale';

  @override
  String get savedFiltersPageTitle => 'Filtri salvati';

  @override
  String get savedFiltersEmptyHeadline => 'Nessun filtro salvato';

  @override
  String get savedFiltersEmptySubheadline =>
      'I filtri che salvi dal feed appariranno qui.';

  @override
  String get savedFiltersMenuRename => 'Rinomina';

  @override
  String get savedFiltersMenuDelete => 'Elimina';

  @override
  String get discoverPageTitle => 'Scopri';

  @override
  String get bottomNavDiscoverLabel => 'Scopri';

  @override
  String get feedSearchHint => 'Cerca notizie...';

  @override
  String get headlineSearchEnterQuery => 'Trova notizie da migliaia di fonti.';

  @override
  String get headlineSearchEnterQuerySubheadline =>
      'Cerca per parola chiave per trovare articoli da migliaia di fonti.';

  @override
  String get headlineSearchNoResults => 'Nessuna notizia trovata.';

  @override
  String get headlineSearchNoResultsSubheadline =>
      'Non siamo riusciti a trovare nessuna notizia corrispondente alla tua ricerca. Prova con parole chiave diverse.';

  @override
  String get accountGuestAccount => 'Account ospite';

  @override
  String get accountRoleStandard => 'Utente standard';

  @override
  String get accountRolePremium => 'Utente Premium';

  @override
  String get deleteConfirmationDialogTitle => 'Conferma eliminazione';

  @override
  String get deleteConfirmationDialogContent =>
      'Sei sicuro di voler eliminare questo elemento? Questa azione non può essere annullata.';

  @override
  String get deleteConfirmationDialogConfirmButton => 'Elimina';

  @override
  String get headlineSearchInitialHeadline => 'Cerca notizie';

  @override
  String get headlineSearchInitialSubheadline =>
      'Inserisci parole chiave per trovare articoli.';

  @override
  String get accountGuestUserHeadline => 'Account ospite';

  @override
  String get accountGuestUserSubheadline =>
      'Accedi per sincronizzare i tuoi dati';

  @override
  String get discoverSearchHint => 'Cerca fonti...';

  @override
  String get seeAllButtonLabel => 'Vedi tutto';

  @override
  String get failedToLoadMoreSources => 'Impossibile caricare altre fonti.';

  @override
  String get sourceTypeNewsAgency => 'Agenzia di stampa';

  @override
  String get sourceTypeLocalNewsOutlet => 'Testata giornalistica locale';

  @override
  String get sourceTypeNationalNewsOutlet => 'Testata giornalistica nazionale';

  @override
  String get sourceTypeInternationalNewsOutlet =>
      'Testata giornalistica internazionale';

  @override
  String get sourceTypeSpecializedPublisher => 'Editore specializzato';

  @override
  String get sourceTypeBlog => 'Blog';

  @override
  String get sourceTypeGovernmentSource => 'Fonte governativa';

  @override
  String get sourceTypeAggregator => 'Aggregatore';

  @override
  String get sourceTypeOther => 'Altro';

  @override
  String get sourceTypeNewsAgencies => 'Agenzie di stampa';

  @override
  String get sourceTypeLocalNewsOutlets => 'Testate giornalistiche locali';

  @override
  String get sourceTypeNationalNewsOutlets =>
      'Testate giornalistiche nazionali';

  @override
  String get sourceTypeInternationalNewsOutlets =>
      'Testate giornalistiche internazionali';

  @override
  String get sourceTypeSpecializedPublishers => 'Editori specializzati';

  @override
  String get sourceTypeBlogs => 'Blog';

  @override
  String get sourceTypeGovernmentSources => 'Fonti governative';

  @override
  String get sourceTypeAggregators => 'Aggregatori';

  @override
  String get sourceTypeOthers => 'Altri';

  @override
  String get sourceTypeFilterEmptyHeadline => 'Nessun tipo di fonte trovato';

  @override
  String get sourceTypeFilterEmptySubheadline =>
      'Al momento non ci sono tipi di fonte disponibili per il filtro.';

  @override
  String get decoratorDismissedConfirmation => 'Suggerimento nascosto.';

  @override
  String get decoratorDismissAction => 'Nascondi suggerimento';

  @override
  String get decoratorLinkAccountTitle_1 =>
      'Salva i tuoi articoli e preferenze';

  @override
  String get decoratorLinkAccountTitle_2 =>
      'Non perdere mai le tue preferenze salvate';

  @override
  String get decoratorLinkAccountDescription_1 =>
      'Crea un account gratuito per salvare più articoli, seguire più argomenti e sincronizzare le tue preferenze su tutti i dispositivi.';

  @override
  String get decoratorLinkAccountDescription_2 =>
      'Registrati per sbloccare più salvataggi, espandere i tuoi contenuti seguiti e mantenere il tuo feed di notizie coerente ovunque.';

  @override
  String get decoratorLinkAccountCta_1 => 'Registrati ora';

  @override
  String get decoratorLinkAccountCta_2 => 'Crea account gratuito';

  @override
  String get decoratorUpgradeTitle_1 =>
      'Goditi un\'esperienza di notizie ininterrotta';

  @override
  String get decoratorUpgradeTitle_2 => 'Sblocca il tuo accesso Premium';

  @override
  String get decoratorUpgradeDescription_1 =>
      'Passa a un\'esperienza senza pubblicità ed espandi notevolmente i tuoi limiti per articoli salvati e contenuti seguiti.';

  @override
  String get decoratorUpgradeDescription_2 =>
      'Passa a Premium per un\'esperienza senza pubblicità e la possibilità di salvare e seguire molti più contenuti che ami.';

  @override
  String get decoratorUpgradeCta_1 => 'Passa a Premium';

  @override
  String get decoratorUpgradeCta_2 => 'Scopri di più';

  @override
  String get decoratorRateAppTitle_1 => 'Ti piace l\'app?';

  @override
  String get decoratorRateAppTitle_2 => 'Condividi il tuo feedback';

  @override
  String get decoratorRateAppDescription_1 =>
      'La tua valutazione ci aiuta a migliorare l\'esperienza delle notizie per tutti. La tua opinione conta!';

  @override
  String get decoratorRateAppDescription_2 =>
      'Il tuo feedback ci aiuta a fornire notizie migliori. Prenditi un momento per valutarci ora!';

  @override
  String get decoratorRateAppCta_1 => 'Valuta ora';

  @override
  String get decoratorRateAppCta_2 => 'Dai un feedback';

  @override
  String get decoratorEnableNotificationsTitle_1 =>
      'Non perdere mai le ultime notizie';

  @override
  String get decoratorEnableNotificationsTitle_2 =>
      'Rimani informato, all\'istante';

  @override
  String get decoratorEnableNotificationsDescription_1 =>
      'Ricevi avvisi istantanei per le ultime notizie e aggiornamenti dai tuoi argomenti e fonti seguiti.';

  @override
  String get decoratorEnableNotificationsDescription_2 =>
      'Abilita le notifiche per ricevere aggiornamenti di notizie personalizzati direttamente sul tuo dispositivo.';

  @override
  String get decoratorEnableNotificationsCta_1 => 'Abilita avvisi';

  @override
  String get decoratorEnableNotificationsCta_2 => 'Attiva notifiche';

  @override
  String get decoratorSuggestedTopicsTitle_1 => 'Scopri nuovi interessi';

  @override
  String get decoratorSuggestedTopicsTitle_2 => 'Amplia le tue conoscenze';

  @override
  String get decoratorSuggestedSourcesTitle_1 => 'Trova nuove prospettive';

  @override
  String get decoratorSuggestedSourcesTitle_2 => 'Scopri fonti attendibili';

  @override
  String get savedHeadlineFiltersPageTitle => 'Filtri salvati';

  @override
  String get savedHeadlineFiltersCreateNewButton => 'Crea filtro';

  @override
  String get savedHeadlineFiltersLoadingHeadline =>
      'Caricamento dei tuoi filtri...';

  @override
  String get savedHeadlineFiltersEmptyHeadline =>
      'Nessun filtro salvato ancora';

  @override
  String get savedHeadlineFiltersEmptySubheadline =>
      'I filtri che crei e salvi appariranno qui. Tocca il pulsante qui sotto per iniziare.';

  @override
  String get savedFiltersMenuEdit => 'Modifica';

  @override
  String get saveFilterDialogPinToFeedLabel => 'Aggiungi alla barra dei filtri';

  @override
  String get saveFilterDialogNotificationsLabel => 'Preferenze di notifica';

  @override
  String get notificationDeliveryTypeBreakingOnly => 'Ultime notizie';

  @override
  String get notificationDeliveryTypeDailyDigest => 'Riepilogo giornaliero';

  @override
  String get notificationDeliveryTypeWeeklyRoundup => 'Riepilogo settimanale';

  @override
  String get prePermissionDialogTitle => 'Abilitare le notifiche?';

  @override
  String get prePermissionDialogBody =>
      'Per inviarti avvisi di ultime notizie e riepiloghi per questo filtro, consenti le notifiche.';

  @override
  String get prePermissionDialogDenyButton => 'Non ora';

  @override
  String get prePermissionDialogAllowButton => 'Consenti';

  @override
  String get notificationPermissionDeniedError =>
      'Il permesso di notifica è stato negato. Puoi abilitarlo nelle impostazioni del tuo dispositivo.';

  @override
  String get notificationCenterPageTitle => 'Notifiche';

  @override
  String get notificationCenterMarkAllAsReadButton => 'Segna tutto come letto';

  @override
  String get notificationCenterLoadingHeadline => 'Caricamento notifiche...';

  @override
  String get notificationCenterLoadingSubheadline => 'Attendere prego...';

  @override
  String get notificationCenterFailureHeadline =>
      'Impossibile caricare le notifiche';

  @override
  String get notificationCenterFailureSubheadline =>
      'Impossibile recuperare le tue notifiche. Riprova.';

  @override
  String get notificationCenterEmptyHeadline => 'Nessuna notifica';

  @override
  String get notificationCenterEmptySubheadline => 'Non hai nuove notifiche.';

  @override
  String get notificationCenterTabBreakingNews => 'Ultime notizie';

  @override
  String get notificationCenterTabDigests => 'Riepiloghi';

  @override
  String get deleteReadNotificationsButtonTooltip =>
      'Elimina tutte le notifiche lette';

  @override
  String get deleteReadNotificationsDialogContent =>
      'Sei sicuro di voler eliminare tutte le notifiche lette in questa scheda? Questa azione non può essere annullata.';

  @override
  String get deleteButtonLabel => 'Elimina';

  @override
  String get breakingNewsPrefix => 'Ultime notizie';

  @override
  String get settingsFeedClickBehaviorLabel => 'Apri link con';

  @override
  String get settingsFeedClickBehaviorDefault => 'Predefinito dell\'app';

  @override
  String get settingsFeedClickBehaviorInApp => 'Browser in-app';

  @override
  String get settingsFeedClickBehaviorSystem => 'Browser di sistema';

  @override
  String get continueToArticleButtonLabel => 'Continua all\'articolo';

  @override
  String get headlineActionsModalTitle => 'Azioni';

  @override
  String get shareActionLabel => 'Condividi';

  @override
  String get bookmarkActionLabel => 'Segnalibro';

  @override
  String get removeBookmarkActionLabel => 'Rimuovi segnalibro';

  @override
  String get reportActionLabel => 'Segnala';

  @override
  String get reportContentTitle => 'Segnala contenuto';

  @override
  String get reportReasonSelectionPrompt =>
      'Seleziona un motivo per la tua segnalazione:';

  @override
  String get reportAdditionalCommentsLabel => 'Commenti aggiuntivi (opzionale)';

  @override
  String get reportSubmitButtonLabel => 'Invia segnalazione';

  @override
  String get reportSuccessSnackbar =>
      'Segnalazione inviata. Grazie per il tuo feedback.';

  @override
  String get reportFailureSnackbar =>
      'Impossibile inviare la segnalazione. Riprova.';

  @override
  String get commentsTitle => 'Commenti';

  @override
  String get commentPostButtonLabel => 'Pubblica';

  @override
  String get commentInputHint => 'Aggiungi un commento...';

  @override
  String get commentRequiresReactionError =>
      'Seleziona una reazione per pubblicare un commento.';

  @override
  String get likeActionLabel => 'Mi piace';

  @override
  String get dislikeActionLabel => 'Non mi piace';

  @override
  String get commentActionLabel => 'Commenta';

  @override
  String get moreActionLabel => 'Altro';

  @override
  String get rateAppPromptTitle => 'Ti piace l\'app?';

  @override
  String get rateAppPromptBody =>
      'Il tuo feedback ci aiuta a migliorare. Ti dispiacerebbe valutarci?';

  @override
  String get rateAppPromptYesButton => 'È fantastica!';

  @override
  String get rateAppPromptNoButton => 'Da migliorare';

  @override
  String get feedbackPromptTitle => 'Come possiamo migliorare?';

  @override
  String get feedbackPromptReasonUI => 'UI / Design';

  @override
  String get feedbackPromptReasonPerformance => 'Prestazioni / Velocità';

  @override
  String get feedbackPromptReasonContent => 'Qualità dei contenuti';

  @override
  String get feedbackPromptReasonOther => 'Altro';

  @override
  String get feedbackPromptSubmitButton => 'Invia feedback';

  @override
  String get rateAppNegativeFollowUpTitle_1 => 'Come stiamo andando ora?';

  @override
  String get rateAppNegativeFollowUpTitle_2 => 'Siamo migliorati?';

  @override
  String get rateAppNegativeFollowUpBody_1 =>
      'Abbiamo lavorato sul tuo feedback. Riconsidereresti la tua valutazione?';

  @override
  String get rateAppNegativeFollowUpBody_2 =>
      'La tua opinione è importante per noi. Facci sapere se le cose sono migliorate.';

  @override
  String get noCommentsYet => 'Nessun commento ancora.';

  @override
  String get commentInputNoReactionHint =>
      'Reagisci per aggiungere un commento';

  @override
  String get headlineReportReasonMisinformation =>
      'Disinformazione o notizie false';

  @override
  String get headlineReportReasonClickbait => 'Clickbait o titolo fuorviante';

  @override
  String get headlineReportReasonOffensive =>
      'Discorso offensivo o di incitamento all\'odio';

  @override
  String get headlineReportReasonSpam => 'Spam o truffa';

  @override
  String get headlineReportReasonBrokenLink => 'Link non funzionante';

  @override
  String get headlineReportReasonPaywalled => 'Contenuto a pagamento';

  @override
  String get sourceReportReasonLowQuality => 'Giornalismo di bassa qualità';

  @override
  String get sourceReportReasonHighAdDensity => 'Annunci o popup eccessivi';

  @override
  String get sourceReportReasonFrequentPaywalls => 'Paywall frequenti';

  @override
  String get sourceReportReasonImpersonation => 'Impersonificazione';

  @override
  String get sourceReportReasonMisinformation => 'Disinformazione';

  @override
  String get commentReportReasonSpam => 'Spam o pubblicità';

  @override
  String get commentReportReasonHarassment => 'Molestie o bullismo';

  @override
  String get commentReportReasonHateSpeech => 'Incitamento all\'odio';

  @override
  String get limitReachedTitle => 'Limite raggiunto';

  @override
  String get manageMyContentButton => 'Gestisci i miei contenuti';

  @override
  String get upgradeButton => 'Aggiorna';

  @override
  String get createAccountButton => 'Crea account';

  @override
  String get gotItButton => 'Capito';

  @override
  String get commentsPageTitle => 'Commenti';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commenti',
      one: '1 commento',
    );
    return '$_temp0';
  }

  @override
  String get limitReachedGuestUserTitle => 'Account richiesto';

  @override
  String get limitReachedGuestUserBody =>
      'Crea un account gratuito o accedi per interagire con la community e utilizzare questa funzione.';

  @override
  String get limitReachedBodyFollow =>
      'Hai raggiunto il limite di elementi seguiti. Per seguirne altri, controlla i contenuti che già segui.';

  @override
  String get limitReachedBodySave =>
      'Hai raggiunto il limite di articoli salvati. Per salvarne altri, controlla gli articoli che hai già salvato.';

  @override
  String get limitReachedBodySaveFilters =>
      'Hai raggiunto il limite di filtri salvati. Per crearne di nuovi, controlla i filtri esistenti.';

  @override
  String get limitReachedBodyPinFilters =>
      'Hai raggiunto il limite di filtri aggiunti. Per aggiungerne uno nuovo, rimuovi un filtro esistente.';

  @override
  String get limitReachedBodySubscribeToNotifications =>
      'Hai raggiunto il limite di iscrizioni alle notifiche. Per iscriverti a nuovi avvisi, controlla le tue iscrizioni esistenti.';

  @override
  String get limitReachedBodyComments =>
      'Hai raggiunto il limite giornaliero di commenti. Riprova domani.';

  @override
  String get limitReachedBodyReactions =>
      'Hai raggiunto il limite giornaliero di reazioni. Riprova domani.';

  @override
  String get limitReachedBodyReports =>
      'Hai raggiunto il limite giornaliero di invio segnalazioni. Riprova domani.';

  @override
  String get commentEditButtonLabel => 'Aggiorna';

  @override
  String get commentPostFailureSnackbar =>
      'Impossibile pubblicare il commento. Riprova.';

  @override
  String get commentUpdateFailureSnackbar =>
      'Impossibile aggiornare il commento. Riprova.';

  @override
  String get commentInputDisabledHint =>
      'Accedi per partecipare alla conversazione';

  @override
  String get commentInputExistingHint => 'Hai già commentato questa notizia.';

  @override
  String commenterName(String id) {
    return 'Utente $id';
  }

  @override
  String get accountRewardsTile => 'Premi e offerte';

  @override
  String get rewardsPageTitle => 'Premi';

  @override
  String rewardsOfferTitle(String rewardName, String duration) {
    return 'Ottieni $rewardName per $duration';
  }

  @override
  String rewardsOfferActiveTitle(String rewardName) {
    return '$rewardName attivo';
  }

  @override
  String rewardsOfferExpiresIn(String countdown) {
    return 'Scade tra: $countdown';
  }

  @override
  String get rewardsOfferWatchButton => 'Guarda video';

  @override
  String get rewardsOfferVerifyingButton => 'Verifica in corso...';

  @override
  String get rewardsOfferLoadingButton => 'Caricamento annuncio...';

  @override
  String rewardsSnackbarSuccess(String rewardName) {
    return 'Premio sbloccato: $rewardName è ora attivo.';
  }

  @override
  String get rewardsSnackbarFailure =>
      'Verifica fallita. Riprova tra un momento.';

  @override
  String get rewardsAdDismissedSnackbar =>
      'Annuncio ignorato. Guarda l\'annuncio completo per ottenere il premio.';

  @override
  String get decoratorUnlockRewardsTitle =>
      'Sblocca un\'esperienza senza pubblicità';

  @override
  String decoratorUnlockRewardsDescription(String duration) {
    return 'Guarda un breve video per goderti l\'app senza pubblicità per $duration.';
  }

  @override
  String get decoratorUnlockRewardsCta => 'Guarda ora';

  @override
  String rewardsDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get rewardTypeAdFree => 'Senza pubblicità';

  @override
  String get rewardTypeDailyDigest => 'Riepilogo giornaliero';

  @override
  String get unlockMoreButton => 'Sblocca di più';

  @override
  String get requiresActiveReward =>
      'Richiede un premio attivo. Puoi sbloccare i premi dalla pagina Account.';

  @override
  String get rewardsAdFreeTitle => 'Goditi un\'esperienza senza pubblicità';

  @override
  String rewardsAdFreeDescription(String duration) {
    return 'Guarda un breve video per rimuovere tutte le pubblicità dall\'app per $duration.';
  }

  @override
  String get rewardsDailyDigestTitle =>
      'Sblocca i riepiloghi giornalieri delle notizie';

  @override
  String rewardsDailyDigestDescription(String duration) {
    return 'Ricevi una notifica push giornaliera che riassume le principali notizie dai tuoi filtri salvati con l\'opzione \'Riepilogo giornaliero\' abilitata. Attivo per $duration.';
  }

  @override
  String get rewardsOfferActiveButton => 'Attivo';

  @override
  String get rewardsAdFreePageTitle => 'Esperienza senza pubblicità';

  @override
  String get rewardsAdFreeInactiveHeadline =>
      'Goditi un\'esperienza senza pubblicità';

  @override
  String rewardsAdFreeInactiveBody(String duration) {
    return 'Guarda un breve annuncio per goderti l\'app senza interruzioni per $duration.';
  }

  @override
  String get rewardsAdFreeActiveHeadline =>
      'L\'esperienza senza pubblicità è attiva';

  @override
  String get rewardsAdFreeActiveBody =>
      'Il tuo accesso senza pubblicità scade tra:';

  @override
  String get appTourStep1Title => 'Le tue notizie, perfettamente su misura';

  @override
  String get appTourStep1Body =>
      'Ottieni un feed creato per te. Segui gli argomenti, le fonti e i paesi che ti interessano di più e noi ci occuperemo del resto.';

  @override
  String get appTourStep2Title => 'Cura e ricevi notifiche';

  @override
  String get appTourStep2Body =>
      'Crea e salva feed di notizie personalizzati per qualsiasi nicchia. Iscriviti per ricevere avvisi di ultime notizie o riepiloghi giornalieri per le storie che non puoi permetterti di perdere.';

  @override
  String get appTourStep3Title => 'Condividi la tua prospettiva';

  @override
  String get appTourStep3Body =>
      'Reagisci e commenta gli articoli per interagire con una community globale. La tua voce aiuta a plasmare la conversazione.';

  @override
  String get appTourSkipButton => 'Salta';

  @override
  String get appTourNextButton => 'Avanti';

  @override
  String get appTourGetStartedButton => 'Inizia';

  @override
  String get initialPersonalizationTitle => 'Personalizza il tuo feed';

  @override
  String get initialPersonalizationSubtitle =>
      'Segui alcuni argomenti, fonti o paesi per iniziare. Puoi sempre cambiarli in seguito.';

  @override
  String get initialPersonalizationStepTopicsTitle => 'Seleziona argomenti';

  @override
  String get initialPersonalizationStepSourcesTitle => 'Seleziona fonti';

  @override
  String get initialPersonalizationStepCountriesTitle => 'Seleziona paesi';

  @override
  String initialPersonalizationTotalSelectionCountLabel(int count) {
    return '$count selezionati';
  }

  @override
  String get initialPersonalizationFinishButton => 'Fine';

  @override
  String get deleteAccountDialogTitle => 'Elimina account';

  @override
  String get deleteAccountDialogContent =>
      'Sei sicuro di voler eliminare definitivamente il tuo account? Questa azione non può essere annullata.';

  @override
  String get deleteAccountDialogConfirm => 'Elimina account';

  @override
  String get deleteAccountButton => 'Elimina account';

  @override
  String get followedContentEmpty =>
      'Non stai ancora seguendo alcun elemento in questa categoria.';

  @override
  String get followedContentEmptySubheadline =>
      'Gli elementi che segui appariranno qui. Usa il pulsante \'+\' per aggiungerne altri.';

  @override
  String multiSelectSearchPageSelectionCount(int count, int total) {
    return '$count/$total';
  }

  @override
  String get guestUserDisplayName => 'Ospite';

  @override
  String get accountPageSyncProgressButton => 'Sincronizza progressi';

  @override
  String get applyButtonLabel => 'Applica';

  @override
  String get commentStatusPending => 'In revisione';

  @override
  String get languageNameEn => 'Inglese';

  @override
  String get languageNameEs => 'Spagnolo';

  @override
  String get languageNameFr => 'Francese';

  @override
  String get languageNameAr => 'Arabo';

  @override
  String get languageNamePt => 'Portoghese';

  @override
  String get languageNameDe => 'Tedesco';

  @override
  String get languageNameIt => 'Italiano';

  @override
  String get languageNameZh => 'Cinese';

  @override
  String get languageNameHi => 'Hindi';

  @override
  String get languageNameJa => 'Giapponese';
}
