// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get accountLinkingPageTitle => '進捗を同期する';

  @override
  String get accountLinkingGenericError => 'エラーが発生しました';

  @override
  String get accountLinkingEmailSentSuccess => 'サインインリンクをメールで送信しました！';

  @override
  String get accountLinkingHeadline => '進捗を保存';

  @override
  String get accountLinkingBody => 'アカウントを作成して、フォロー中のアイテムや設定をすべてのデバイスで同期しましょう。';

  @override
  String get accountLinkingContinueWithGoogleButton => 'Googleで続行';

  @override
  String get accountLinkingEmailInputLabel => 'メールアドレスを入力';

  @override
  String get accountLinkingEmailInputHint => 'you@example.com';

  @override
  String get accountLinkingEmailValidationError => '有効なメールアドレスを入力してください';

  @override
  String get accountLinkingSendLinkButton => 'メールで同期';

  @override
  String get accountPageTitle => 'アカウント';

  @override
  String get accountAnonymousUser => '(匿名)';

  @override
  String get accountNoNameUser => '名前なし';

  @override
  String get accountStatusAuthenticated => '認証済み';

  @override
  String get accountStatusAnonymous => '匿名セッション';

  @override
  String get accountStatusUnauthenticated => 'サインインしていません';

  @override
  String get accountSettingsTile => '設定';

  @override
  String get accountSignOutTile => 'サインアウト';

  @override
  String get accountBackupTile => 'データを保存するためにアカウントを作成';

  @override
  String get accountContentPreferencesTile => 'フォロー中のコンテンツ';

  @override
  String get accountSavedHeadlinesTile => '保存した見出し';

  @override
  String accountRoleLabel(String role) {
    return 'ロール: $role';
  }

  @override
  String get accountMyContentSectionTitle => 'マイコンテンツ';

  @override
  String get accountActivityAndRewardsSectionTitle => 'アクティビティと特典';

  @override
  String get accountGeneralSectionTitle => '一般';

  @override
  String get accountEditProfileButton => 'プロフィールを編集';

  @override
  String get editProfilePageTitle => 'プロフィールを編集';

  @override
  String get editProfileNameInputLabel => '名前';

  @override
  String get editProfileEmailInputLabel => 'メールアドレス';

  @override
  String get editProfileUpdateSuccessSnackbar => 'プロフィールを更新しました。';

  @override
  String get editProfileUpdateFailureSnackbar =>
      'プロフィールの更新に失敗しました。もう一度お試しください。';

  @override
  String get followedContentPageTitle => 'フォロー中のアイテム';

  @override
  String get followedContentTopicsTab => 'トピック';

  @override
  String get followedContentSourcesTab => 'ソース';

  @override
  String get authenticationEmailSentSuccess => 'サインインリンクをメールで送信しました。';

  @override
  String get authenticationPageTitle => 'サインイン / 登録';

  @override
  String get authenticationEmailLabel => 'メールアドレス';

  @override
  String get authenticationSendLinkButton => 'サインインリンクを送信';

  @override
  String get authenticationOrDivider => 'または';

  @override
  String get authenticationGoogleSignInButton => 'Googleでサインイン';

  @override
  String get authenticationAnonymousSignInButton => '匿名で続行';

  @override
  String get headlineDetailsInitialHeadline => '詳細を待機中';

  @override
  String get headlineDetailsInitialSubheadline => 'お待ちください...';

  @override
  String get headlineDetailsLoadingHeadline => '見出しを読み込み中';

  @override
  String get headlineDetailsLoadingSubheadline => 'データを取得しています...';

  @override
  String get headlineDetailsContinueReadingButton => '続きを読む';

  @override
  String get headlinesFeedLoadingHeadline => '読み込み中...';

  @override
  String get headlinesFeedLoadingSubheadline => '見出しを取得しています';

  @override
  String get headlinesFeedFilterTitle => '見出しをフィルタ';

  @override
  String get headlinesFeedFilterCategoryLabel => 'カテゴリ';

  @override
  String get headlinesFeedFilterAllOption => 'すべて';

  @override
  String get headlinesFeedFilterCategoryTechnology => 'テクノロジー';

  @override
  String get headlinesFeedFilterCategoryBusiness => 'ビジネス';

  @override
  String get headlinesFeedFilterCategorySports => 'スポーツ';

  @override
  String get headlinesFeedFilterSourceLabel => 'ソース';

  @override
  String get headlinesFeedFilterSourceCNN => 'CNN';

  @override
  String get headlinesFeedFilterSourceReuters => 'ロイター';

  @override
  String get headlinesFeedFilterEventCountryLabel => '国';

  @override
  String get headlinesFeedFilterSourceCountryLabel => 'ソースの本拠地';

  @override
  String get headlinesFeedFilterCountryUS => 'アメリカ';

  @override
  String get headlinesFeedFilterCountryUK => 'イギリス';

  @override
  String get headlinesFeedFilterCountryCA => 'カナダ';

  @override
  String get headlinesFeedFilterApplyButton => 'フィルタを適用';

  @override
  String get headlinesFeedFilterResetButton => 'フィルタをリセット';

  @override
  String get headlinesSearchHintText => '見出しを検索...';

  @override
  String get headlinesSearchInitialHeadline => '見出しをすぐに見つける';

  @override
  String get headlinesSearchInitialSubheadline => 'キーワードを入力してニュース記事を探しましょう。';

  @override
  String get headlinesSearchNoResultsHeadline => '結果なし';

  @override
  String get headlinesSearchNoResultsSubheadline => '別の検索ワードを試してください';

  @override
  String get authenticationEmailSignInButton => 'メールで続行';

  @override
  String get authenticationLinkingHeadline => '進捗を同期する';

  @override
  String get authenticationLinkingSubheadline =>
      'アカウントを作成して、設定やコンテンツの好みを保存しましょう。';

  @override
  String get authenticationSignInHeadline => 'Verity';

  @override
  String get authenticationSignInSubheadline => '世界中の信頼できるソースからのニュース。';

  @override
  String get emailSignInPageTitle => 'メールでサインイン';

  @override
  String get emailSignInExplanation => 'メールアドレスを入力してください。サインイン用のリンクを送信します。';

  @override
  String get emailLinkSentPageTitle => 'メールを確認してください';

  @override
  String get emailLinkSentConfirmation => 'リンクを送信しました！受信トレイを確認してください。';

  @override
  String get accountConnectPrompt => 'アカウントを連携';

  @override
  String get accountConnectBenefit => '設定や読書履歴をデバイス間で保存します。';

  @override
  String get bottomNavFeedLabel => 'フィード';

  @override
  String get bottomNavSearchLabel => '検索';

  @override
  String get bottomNavAccountLabel => 'アカウント';

  @override
  String get accountNotificationsTile => '通知';

  @override
  String get headlinesSearchActionTooltip => '検索';

  @override
  String get notificationsTooltip => '通知を表示';

  @override
  String get accountSignInPromptButton => '登録 / サインイン';

  @override
  String get categoryFilterLoadingHeadline => 'カテゴリを読み込み中...';

  @override
  String get categoryFilterLoadingSubheadline => '利用可能なカテゴリを取得しています。';

  @override
  String get categoryFilterEmptyHeadline => 'カテゴリが見つかりません';

  @override
  String get categoryFilterEmptySubheadline => '現在利用可能なカテゴリはありません。';

  @override
  String get countryFilterLoadingHeadline => '国を読み込み中...';

  @override
  String get countryFilterLoadingSubheadline => '利用可能な国を取得しています。';

  @override
  String get countryFilterEmptyHeadline => '国が見つかりません';

  @override
  String get countryFilterEmptySubheadline => '現在利用可能な国はありません。';

  @override
  String get headlinesFeedAppBarTitle => 'HT';

  @override
  String get headlinesFeedFilterTooltip => '見出しをフィルタ';

  @override
  String get headlinesFeedFilterAllLabel => 'すべて';

  @override
  String headlinesFeedFilterSelectedCountLabel(int count) {
    return '$count件選択済み';
  }

  @override
  String get sourceFilterLoadingHeadline => 'ソースを読み込み中...';

  @override
  String get sourceFilterLoadingSubheadline => '利用可能なソースを取得しています。';

  @override
  String get sourceFilterEmptyHeadline => 'ソースが見つかりません';

  @override
  String get sourceFilterEmptySubheadline => '現在利用可能なソースはありません。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLoadingHeadline => '設定を読み込み中...';

  @override
  String get settingsLoadingSubheadline => '設定を取得しています。';

  @override
  String get settingsErrorDefault => '設定を読み込めませんでした。';

  @override
  String get settingsAppearanceTitle => '外観';

  @override
  String get settingsFeedDisplayTitle => 'フィード';

  @override
  String get settingsArticleDisplayTitle => '記事の表示';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsAppearanceThemeModeLight => 'ライト';

  @override
  String get settingsAppearanceThemeModeDark => 'ダーク';

  @override
  String get settingsAppearanceThemeModeSystem => 'システム';

  @override
  String get settingsAppearanceThemeNameRed => 'レッド';

  @override
  String get settingsAppearanceThemeNameBlue => 'ブルー';

  @override
  String get settingsAppearanceThemeNameGrey => 'グレー';

  @override
  String get settingsAppearanceFontSizeSmall => '小';

  @override
  String get settingsAppearanceFontSizeLarge => '大';

  @override
  String get settingsAppearanceFontSizeMedium => '中';

  @override
  String get settingsAppearanceThemeModeLabel => 'テーマモード';

  @override
  String get settingsAppearanceThemeNameLabel => 'カラースキーム';

  @override
  String get settingsAppearanceAppFontSizeLabel => 'アプリのフォントサイズ';

  @override
  String get settingsAppearanceAppFontTypeLabel => 'アプリのフォント';

  @override
  String get settingsAppearanceFontWeightLabel => 'フォントの太さ';

  @override
  String get settingsFeedTileTypeImageTop => '画像上部';

  @override
  String get settingsFeedTileTypeImageStart => '画像左側';

  @override
  String get settingsFeedTileTypeTextOnly => 'テキストのみ';

  @override
  String get settingsFeedTileTypeLabel => 'フィードタイルのレイアウト';

  @override
  String get settingsArticleFontSizeLabel => '記事のフォントサイズ';

  @override
  String get settingsNotificationsEnableLabel => '通知を有効にする';

  @override
  String get settingsNotificationsCategoriesLabel => 'フォロー中のカテゴリ';

  @override
  String get settingsNotificationsSourcesLabel => 'フォロー中のソース';

  @override
  String get settingsNotificationsCountriesLabel => 'フォロー中の国';

  @override
  String get settingsAppearanceSectionTitle => '外観';

  @override
  String get settingsFeedSectionTitle => 'フィード';

  @override
  String get settingsGeneralSectionTitle => '一般';

  @override
  String get settingsAccentColorAndFontsTitle => 'アクセントカラーとフォント';

  @override
  String get settingsAccentColorLabel => 'アクセントカラー';

  @override
  String get settingsFontFamilyLabel => 'フォントファミリー';

  @override
  String get settingsLayoutAndReadingTitle => 'レイアウトと読書';

  @override
  String get appName => 'News App';

  @override
  String get unknownError => '不明なエラーが発生しました。';

  @override
  String get loadMoreError => 'さらに読み込むことができませんでした。';

  @override
  String get settingsAppearanceFontSizeExtraLarge => '特大';

  @override
  String get settingsAppearanceFontFamilySystemDefault => 'システムデフォルト';

  @override
  String get settingsAppearanceFontFamilyRoboto => 'Roboto';

  @override
  String get settingsAppearanceFontFamilyOpenSans => 'Open Sans';

  @override
  String get settingsAppearanceThemeSubPageTitle => 'テーマ設定';

  @override
  String get settingsAppearanceFontSubPageTitle => 'フォント設定';

  @override
  String get settingsLanguageTitle => '言語';

  @override
  String get emailCodeSentPageTitle => 'コードを入力';

  @override
  String emailCodeSentConfirmation(String email) {
    return '$emailに確認コードを送信しました。';
  }

  @override
  String get emailCodeSentInstructions => '受信した6桁のコードを入力してください。';

  @override
  String get emailCodeVerificationHint => '6桁のコード';

  @override
  String get emailCodeVerificationButtonLabel => 'コードを確認';

  @override
  String get emailCodeValidationEmptyError => '6桁のコードを入力してください。';

  @override
  String get emailCodeValidationLengthError => 'コードは6桁である必要があります。';

  @override
  String get headlinesFeedEmptyFilteredHeadline => 'フィルタに一致する見出しがありません';

  @override
  String get headlinesFeedEmptyFilteredSubheadline => 'フィルタ条件を調整するか、クリアしてください。';

  @override
  String get headlinesFeedClearFiltersButton => 'フィルタをクリア';

  @override
  String get headlinesFeedFilterLoadingCriteria => 'フィルタオプションを読み込み中...';

  @override
  String get pleaseWait => 'お待ちください...';

  @override
  String get headlinesFeedFilterErrorCriteria => 'フィルタオプションを読み込めませんでした。';

  @override
  String get headlinesFeedFilterCountryLabel => '国';

  @override
  String get headlinesFeedFilterSourceTypeLabel => 'タイプ';

  @override
  String get headlinesFeedFilterErrorSources => 'ソースを読み込めませんでした。';

  @override
  String get headlinesFeedFilterNoSourcesMatch => '選択したフィルタに一致するソースはありません。';

  @override
  String get searchModelTypeHeadline => '見出し';

  @override
  String get searchModelTypeCategory => 'カテゴリ';

  @override
  String get searchModelTypeSource => 'ソース';

  @override
  String get searchModelTypeCountry => '国';

  @override
  String get searchHintTextHeadline => '例: AIの進歩、火星探査機...';

  @override
  String get searchHintTextGeneric => '検索...';

  @override
  String get searchHintTextCategory => '例: テクノロジー、スポーツ、金融...';

  @override
  String get searchHintTextSource => '例: BBC News、ロイター...';

  @override
  String get searchHintTextCountry => '例: 日本、アメリカ、ブラジル...';

  @override
  String get searchPageInitialHeadline => '検索を開始';

  @override
  String get searchPageInitialSubheadline => 'タイプを選択し、キーワードを入力してください。';

  @override
  String get followedCategoriesPageTitle => 'フォロー中のカテゴリ';

  @override
  String get addCategoriesTooltip => 'カテゴリを追加';

  @override
  String get noFollowedCategoriesMessage => 'まだカテゴリをフォローしていません。';

  @override
  String get addCategoriesButtonLabel => 'フォローするカテゴリを探す';

  @override
  String unfollowCategoryTooltip(String categoryName) {
    return '$categoryNameのフォローを解除';
  }

  @override
  String get addTopicsPageTitle => 'トピックをフォロー';

  @override
  String get topicFilterLoadingHeadline => 'トピックを読み込み中...';

  @override
  String get topicFilterError => 'トピックを読み込めませんでした。';

  @override
  String get topicFilterEmptyHeadline => 'トピックが見つかりません';

  @override
  String get topicFilterEmptySubheadline => '現在利用可能なトピックはありません。';

  @override
  String unfollowTopicTooltip(String topicName) {
    return '$topicNameのフォローを解除';
  }

  @override
  String followTopicTooltip(String topicName) {
    return '$topicNameをフォロー';
  }

  @override
  String get followedSourcesLoadingHeadline => 'フォロー中のソースを読み込み中...';

  @override
  String get followedSourcesErrorHeadline => 'フォロー中のソースを読み込めませんでした';

  @override
  String get followedSourcesEmptyHeadline => 'フォロー中のソースなし';

  @override
  String get followedSourcesEmptySubheadline => 'ソースをフォローするとここに表示されます。';

  @override
  String get headlinesFeedFilterTopicLabel => 'トピック';

  @override
  String get followedTopicsPageTitle => 'フォロー中のトピック';

  @override
  String get addTopicsTooltip => 'トピックを追加';

  @override
  String get followedTopicsLoadingHeadline => 'フォロー中のトピックを読み込み中...';

  @override
  String get followedTopicsErrorHeadline => 'フォロー中のトピックを読み込めませんでした';

  @override
  String get followedTopicsEmptyHeadline => 'フォロー中のトピックなし';

  @override
  String get followedTopicsEmptySubheadline => 'トピックをフォローするとここに表示されます。';

  @override
  String get followedSourcesPageTitle => 'フォロー中のソース';

  @override
  String get addSourcesTooltip => 'ソースを追加';

  @override
  String get noFollowedSourcesMessage => 'まだソースをフォローしていません。';

  @override
  String get addSourcesButtonLabel => 'フォローするソースを探す';

  @override
  String unfollowSourceTooltip(String sourceName) {
    return '$sourceNameのフォローを解除';
  }

  @override
  String get followedCountriesPageTitle => 'フォロー中の国';

  @override
  String get addCountriesTooltip => '国を追加';

  @override
  String get noFollowedCountriesMessage => 'まだ国をフォローしていません。';

  @override
  String get addCountriesButtonLabel => 'フォローする国を探す';

  @override
  String unfollowCountryTooltip(String countryName) {
    return '$countryNameのフォローを解除';
  }

  @override
  String get addCategoriesPageTitle => 'フォローするカテゴリを追加';

  @override
  String get categoryFilterError => 'カテゴリを読み込めませんでした。';

  @override
  String followCategoryTooltip(String categoryName) {
    return '$categoryNameをフォロー';
  }

  @override
  String get addSourcesPageTitle => 'フォローするソースを追加';

  @override
  String get sourceFilterError => 'ソースを読み込めませんでした。';

  @override
  String followSourceTooltip(String sourceName) {
    return '$sourceNameをフォロー';
  }

  @override
  String get addCountriesPageTitle => 'フォローする国を追加';

  @override
  String followCountryTooltip(String countryName) {
    return '$countryNameをフォロー';
  }

  @override
  String get headlineDetailsSaveTooltip => '見出しを保存';

  @override
  String get headlineDetailsRemoveFromSavedTooltip => '保存から削除';

  @override
  String get headlineSavedSuccessSnackbar => '見出しを保存しました！';

  @override
  String get headlineUnsavedSuccessSnackbar => '見出しを保存から削除しました。';

  @override
  String get headlineSaveErrorSnackbar => '保存状態を更新できませんでした。';

  @override
  String get shareActionTooltip => '見出しを共有';

  @override
  String get sharingUnavailableSnackbar => 'このデバイスでは共有を利用できません。';

  @override
  String get similarHeadlinesSectionTitle => 'こちらもおすすめ';

  @override
  String get similarHeadlinesEmpty => '類似の見出しは見つかりませんでした。';

  @override
  String get detailsPageTitle => '詳細';

  @override
  String get followButtonLabel => 'フォロー';

  @override
  String get unfollowButtonLabel => 'フォロー解除';

  @override
  String get noHeadlinesFoundMessage => 'このアイテムの見出しは見つかりませんでした。';

  @override
  String get failedToLoadMoreHeadlines => '見出しの読み込みに失敗しました。';

  @override
  String get headlinesSectionTitle => '見出し';

  @override
  String get headlinesFeedFilterApplyFollowedLabel => 'フォロー中のアイテムをフィルタとして適用';

  @override
  String get mustBeLoggedInToUseFeatureError => 'この機能を使用するにはログインが必要です。';

  @override
  String get noFollowedItemsForFilterSnackbar => 'フィルタとして使用するフォロー中のアイテムがありません。';

  @override
  String get requestCodePageHeadline => 'メールアドレスを入力';

  @override
  String get requestCodePageSubheadline => '本人確認のため、メールに確認コードを送信します。';

  @override
  String get requestCodeEmailLabel => 'メールアドレス';

  @override
  String get requestCodeEmailHint => 'you@example.com';

  @override
  String get requestCodeSendCodeButton => 'コードを送信';

  @override
  String requestCodeResendButtonCooldown(int seconds) {
    return '$seconds秒後に再送';
  }

  @override
  String get entityDetailsCategoryTitle => 'カテゴリ';

  @override
  String get entityDetailsSourceTitle => 'ソース';

  @override
  String get entityDetailsTopicTitle => 'トピック';

  @override
  String get entityDetailsCountryTitle => '国';

  @override
  String get savedHeadlinesLoadingHeadline => '保存した見出しを読み込み中...';

  @override
  String get savedHeadlinesLoadingSubheadline => '保存した記事を取得しています。';

  @override
  String get savedHeadlinesErrorHeadline => '保存した見出しを読み込めませんでした';

  @override
  String get savedHeadlinesEmptyHeadline => '保存した見出しなし';

  @override
  String get savedHeadlinesEmptySubheadline => 'まだ記事を保存していません。';

  @override
  String get accountFollowedCountriesTile => 'フォロー中の国';

  @override
  String get followedCountriesLoadingHeadline => 'フォロー中の国を読み込み中...';

  @override
  String get followedCountriesErrorHeadline => 'フォロー中の国を読み込めませんでした';

  @override
  String get followedCountriesEmptyHeadline => 'フォロー中の国なし';

  @override
  String get followedCountriesEmptySubheadline => '国をフォローするとここに表示されます。';

  @override
  String get countryFilterError => '国を読み込めませんでした。';

  @override
  String get followedCategoriesLoadingHeadline => 'フォロー中のカテゴリを読み込み中...';

  @override
  String get followedCategoriesErrorHeadline => 'フォロー中のカテゴリを読み込めませんでした';

  @override
  String get followedCategoriesEmptyHeadline => 'フォロー中のカテゴリなし';

  @override
  String get followedCategoriesEmptySubheadline => 'カテゴリをフォローするとここに表示されます。';

  @override
  String get contentTypeHeadline => '見出し';

  @override
  String get contentTypeTopic => 'トピック';

  @override
  String get contentTypeSource => 'ソース';

  @override
  String get contentTypeCountry => '国';

  @override
  String searchingFor(String contentType) {
    return '$contentTypeを検索中...';
  }

  @override
  String get settingsAppearanceFontWeightLight => 'ライト';

  @override
  String get settingsAppearanceFontWeightRegular => 'レギュラー';

  @override
  String get settingsAppearanceFontWeightBold => 'ボールド';

  @override
  String get maintenanceHeadline => 'メンテナンス中';

  @override
  String get maintenanceSubheadline => '現在メンテナンスを行っています。後ほどご確認ください。';

  @override
  String get updateRequiredHeadline => 'アップデートが必要です';

  @override
  String get updateRequiredSubheadline => '新しいバージョンのアプリが利用可能です。';

  @override
  String get updateRequiredButton => '今すぐアップデート';

  @override
  String get neverShowAgain => '二度と表示しない';

  @override
  String get followButtonText => 'フォロー';

  @override
  String get unfollowButtonText => 'フォロー解除';

  @override
  String get adInfoPlaceholderText => '広告はこのアプリを無料で維持するのに役立ちます！';

  @override
  String get retryButtonText => '再試行';

  @override
  String get headlinesFeedFilterLoadingHeadline => 'フィルタを読み込み中';

  @override
  String get suggestedTopicsTitle => 'おすすめのトピック';

  @override
  String get suggestedSourcesTitle => 'おすすめのソース';

  @override
  String couldNotOpenUpdateUrl(String url) {
    return 'アップデートURLを開けませんでした: $url';
  }

  @override
  String currentAppVersionLabel(String version) {
    return '現在のバージョン: $version';
  }

  @override
  String latestRequiredVersionLabel(String version) {
    return '必要なバージョン: $version';
  }

  @override
  String get anonymousLimitTitle => 'サインインしてさらに活用';

  @override
  String get anonymousLimitBody => '無料アカウントを作成して、より多くのブックマークやフォローをしましょう。';

  @override
  String get anonymousLimitButton => 'サインイン';

  @override
  String get standardLimitBody => '無料プランの制限に達しました。アップグレードして保存やフォローを増やしましょう。';

  @override
  String get standardLimitButton => 'プレミアムにアップグレード';

  @override
  String get premiumLimitTitle => '制限に達しました';

  @override
  String get premiumLimitBody => '新しいアイテムを追加するには、既存のコンテンツを管理してください。';

  @override
  String get premiumLimitButton => 'マイコンテンツを管理';

  @override
  String get saveButtonLabel => '保存';

  @override
  String get cancelButtonLabel => 'キャンセル';

  @override
  String get manageFiltersPageTitle => 'フィルタを管理';

  @override
  String get manageFiltersEmptyHeadline => '保存されたフィルタなし';

  @override
  String get manageFiltersEmptySubheadline => 'フィルタページからフィルタを保存できます。';

  @override
  String get manageFiltersRenameTooltip => 'フィルタ名を変更';

  @override
  String get manageFiltersDeleteTooltip => 'フィルタを削除';

  @override
  String get saveFilterDialogTitleSave => 'フィルタを保存';

  @override
  String get saveFilterDialogTitleRename => 'フィルタ名を変更';

  @override
  String get saveFilterDialogInputLabel => 'フィルタ名';

  @override
  String get saveFilterDialogValidationEmpty => '名前を入力してください';

  @override
  String get saveFilterDialogValidationTooLong => '名前が長すぎます';

  @override
  String get saveFilterDialogGenericError => 'フィルタの保存中に予期しないエラーが発生しました。';

  @override
  String get headlinesFilterSaveTooltip => 'フィルタを保存';

  @override
  String get headlinesFilterManageTooltip => 'フィルタを管理';

  @override
  String get savedFiltersBarOpenTooltip => 'フィルタを開く';

  @override
  String get savedFiltersBarAllLabel => 'すべて';

  @override
  String get savedFiltersBarCustomLabel => 'カスタム';

  @override
  String get applyFilterDialogTitle => 'フィルタを適用';

  @override
  String get applyFilterDialogContent => 'この設定を今回のみ適用しますか、それとも保存しますか？';

  @override
  String get applyFilterDialogApplyOnlyButton => '適用のみ';

  @override
  String get applyFilterDialogApplyAndSaveButton => '適用して保存';

  @override
  String get savedFiltersBarFollowedLabel => 'フォロー中';

  @override
  String get sourceListFilterPageTitle => 'ソースをフィルタ';

  @override
  String get sourceListFilterPageFilterButtonTooltip => 'ソースリストをフィルタ';

  @override
  String get sourceListFilterByHeadquartersPageTitle => '本拠地の場所';

  @override
  String get savedFiltersPageTitle => '保存されたフィルタ';

  @override
  String get savedFiltersEmptyHeadline => '保存されたフィルタなし';

  @override
  String get savedFiltersEmptySubheadline => 'フィードから保存したフィルタがここに表示されます。';

  @override
  String get savedFiltersMenuRename => '名前を変更';

  @override
  String get savedFiltersMenuDelete => '削除';

  @override
  String get discoverPageTitle => '見つける';

  @override
  String get bottomNavDiscoverLabel => '見つける';

  @override
  String get feedSearchHint => '見出しを検索...';

  @override
  String get headlineSearchEnterQuery => '数千のソースから見出しを見つける。';

  @override
  String get headlineSearchEnterQuerySubheadline => 'キーワードで検索して記事を見つけましょう。';

  @override
  String get headlineSearchNoResults => '見出しが見つかりませんでした。';

  @override
  String get headlineSearchNoResultsSubheadline =>
      '一致する見出しがありません。別のキーワードを試してください。';

  @override
  String get accountGuestAccount => 'ゲストアカウント';

  @override
  String get accountRoleStandard => '標準ユーザー';

  @override
  String get accountRolePremium => 'プレミアムユーザー';

  @override
  String get deleteConfirmationDialogTitle => '削除の確認';

  @override
  String get deleteConfirmationDialogContent =>
      'このアイテムを削除してもよろしいですか？この操作は取り消せません。';

  @override
  String get deleteConfirmationDialogConfirmButton => '削除';

  @override
  String get headlineSearchInitialHeadline => '見出しを検索';

  @override
  String get headlineSearchInitialSubheadline => 'キーワードを入力して記事を探します。';

  @override
  String get accountGuestUserHeadline => 'ゲストアカウント';

  @override
  String get accountGuestUserSubheadline => 'サインインしてデータを同期';

  @override
  String get discoverSearchHint => 'ソースを検索...';

  @override
  String get seeAllButtonLabel => 'すべて見る';

  @override
  String get failedToLoadMoreSources => 'ソースの読み込みに失敗しました。';

  @override
  String get sourceTypeNewsAgency => '通信社';

  @override
  String get sourceTypeLocalNewsOutlet => '地方ニュース';

  @override
  String get sourceTypeNationalNewsOutlet => '全国ニュース';

  @override
  String get sourceTypeInternationalNewsOutlet => '国際ニュース';

  @override
  String get sourceTypeSpecializedPublisher => '専門出版社';

  @override
  String get sourceTypeBlog => 'ブログ';

  @override
  String get sourceTypeGovernmentSource => '政府ソース';

  @override
  String get sourceTypeAggregator => 'アグリゲーター';

  @override
  String get sourceTypeOther => 'その他';

  @override
  String get sourceTypeNewsAgencies => '通信社';

  @override
  String get sourceTypeLocalNewsOutlets => '地方ニュース';

  @override
  String get sourceTypeNationalNewsOutlets => '全国ニュース';

  @override
  String get sourceTypeInternationalNewsOutlets => '国際ニュース';

  @override
  String get sourceTypeSpecializedPublishers => '専門出版社';

  @override
  String get sourceTypeBlogs => 'ブログ';

  @override
  String get sourceTypeGovernmentSources => '政府ソース';

  @override
  String get sourceTypeAggregators => 'アグリゲーター';

  @override
  String get sourceTypeOthers => 'その他';

  @override
  String get sourceTypeFilterEmptyHeadline => 'ソースタイプが見つかりません';

  @override
  String get sourceTypeFilterEmptySubheadline => '現在利用可能なソースタイプはありません。';

  @override
  String get decoratorDismissedConfirmation => '提案を非表示にしました。';

  @override
  String get decoratorDismissAction => '提案を非表示';

  @override
  String get decoratorLinkAccountTitle_1 => '記事と設定を保存';

  @override
  String get decoratorLinkAccountTitle_2 => '保存した設定を失わないために';

  @override
  String get decoratorLinkAccountDescription_1 =>
      '無料アカウントを作成して、より多くの記事を保存し、デバイス間で同期しましょう。';

  @override
  String get decoratorLinkAccountDescription_2 =>
      'サインアップして、ニュースフィードをどこでも一貫して保ちましょう。';

  @override
  String get decoratorLinkAccountCta_1 => '今すぐ登録';

  @override
  String get decoratorLinkAccountCta_2 => '無料アカウントを作成';

  @override
  String get decoratorUpgradeTitle_1 => '途切れることのないニュース体験を';

  @override
  String get decoratorUpgradeTitle_2 => 'プレミアムアクセスを解除';

  @override
  String get decoratorUpgradeDescription_1 => '広告を非表示にし、保存やフォローの制限を大幅に拡大します。';

  @override
  String get decoratorUpgradeDescription_2 =>
      'プレミアムにアップグレードして、広告なしでより多くのコンテンツを楽しみましょう。';

  @override
  String get decoratorUpgradeCta_1 => 'プレミアムにアップグレード';

  @override
  String get decoratorUpgradeCta_2 => '詳細を見る';

  @override
  String get decoratorRateAppTitle_1 => 'アプリを楽しんでいますか？';

  @override
  String get decoratorRateAppTitle_2 => 'フィードバックをお寄せください';

  @override
  String get decoratorRateAppDescription_1 => 'あなたの評価は、ニュース体験の向上に役立ちます。';

  @override
  String get decoratorRateAppDescription_2 => 'より良いニュースを届けるために、評価をお願いします！';

  @override
  String get decoratorRateAppCta_1 => '今すぐ評価';

  @override
  String get decoratorRateAppCta_2 => 'フィードバックを送る';

  @override
  String get decoratorEnableNotificationsTitle_1 => '速報を見逃さない';

  @override
  String get decoratorEnableNotificationsTitle_2 => '常に最新情報を';

  @override
  String get decoratorEnableNotificationsDescription_1 =>
      'フォロー中のトピックやソースから速報アラートを受け取ります。';

  @override
  String get decoratorEnableNotificationsDescription_2 =>
      '通知を有効にして、パーソナライズされたニュースを受け取りましょう。';

  @override
  String get decoratorEnableNotificationsCta_1 => 'アラートを有効にする';

  @override
  String get decoratorEnableNotificationsCta_2 => '通知をオンにする';

  @override
  String get decoratorSuggestedTopicsTitle_1 => '新しい興味を見つける';

  @override
  String get decoratorSuggestedTopicsTitle_2 => '知識を広げる';

  @override
  String get decoratorSuggestedSourcesTitle_1 => '新しい視点を見つける';

  @override
  String get decoratorSuggestedSourcesTitle_2 => '信頼できるソースを見つける';

  @override
  String get savedHeadlineFiltersPageTitle => '保存されたフィルタ';

  @override
  String get savedHeadlineFiltersCreateNewButton => 'フィルタを作成';

  @override
  String get savedHeadlineFiltersLoadingHeadline => 'フィルタを読み込み中...';

  @override
  String get savedHeadlineFiltersEmptyHeadline => '保存されたフィルタはまだありません';

  @override
  String get savedHeadlineFiltersEmptySubheadline => '作成したフィルタがここに表示されます。';

  @override
  String get savedFiltersMenuEdit => '編集';

  @override
  String get saveFilterDialogPinToFeedLabel => 'フィルタバーに固定';

  @override
  String get saveFilterDialogNotificationsLabel => '通知設定';

  @override
  String get notificationDeliveryTypeBreakingOnly => 'ニュース速報';

  @override
  String get notificationDeliveryTypeDailyDigest => 'デイリーダイジェスト';

  @override
  String get notificationDeliveryTypeWeeklyRoundup => 'ウィークリーラウンドアップ';

  @override
  String get prePermissionDialogTitle => '通知を有効にしますか？';

  @override
  String get prePermissionDialogBody => '速報アラートやダイジェストを送信するために、通知を許可してください。';

  @override
  String get prePermissionDialogDenyButton => '今はしない';

  @override
  String get prePermissionDialogAllowButton => '許可する';

  @override
  String get notificationPermissionDeniedError =>
      '通知権限が拒否されました。デバイスの設定で有効にできます。';

  @override
  String get notificationCenterPageTitle => '通知';

  @override
  String get notificationCenterMarkAllAsReadButton => 'すべて既読にする';

  @override
  String get notificationCenterLoadingHeadline => '通知を読み込み中...';

  @override
  String get notificationCenterLoadingSubheadline => 'お待ちください...';

  @override
  String get notificationCenterFailureHeadline => '通知の読み込みに失敗しました';

  @override
  String get notificationCenterFailureSubheadline =>
      '通知を取得できませんでした。もう一度お試しください。';

  @override
  String get notificationCenterEmptyHeadline => '通知なし';

  @override
  String get notificationCenterEmptySubheadline => '新しい通知はありません。';

  @override
  String get notificationCenterTabBreakingNews => 'ニュース速報';

  @override
  String get notificationCenterTabDigests => 'ダイジェスト';

  @override
  String get deleteReadNotificationsButtonTooltip => '既読の通知をすべて削除';

  @override
  String get deleteReadNotificationsDialogContent =>
      'このタブの既読通知をすべて削除してもよろしいですか？';

  @override
  String get deleteButtonLabel => '削除';

  @override
  String get breakingNewsPrefix => '速報';

  @override
  String get settingsFeedClickBehaviorLabel => 'リンクを開く方法';

  @override
  String get settingsFeedClickBehaviorDefault => 'アプリのデフォルト';

  @override
  String get settingsFeedClickBehaviorInApp => 'アプリ内ブラウザ';

  @override
  String get settingsFeedClickBehaviorSystem => 'システムブラウザ';

  @override
  String get continueToArticleButtonLabel => '記事へ進む';

  @override
  String get headlineActionsModalTitle => 'アクション';

  @override
  String get shareActionLabel => '共有';

  @override
  String get bookmarkActionLabel => 'ブックマーク';

  @override
  String get removeBookmarkActionLabel => 'ブックマークを削除';

  @override
  String get reportActionLabel => '報告';

  @override
  String get reportContentTitle => 'コンテンツを報告';

  @override
  String get reportReasonSelectionPrompt => '報告の理由を選択してください:';

  @override
  String get reportAdditionalCommentsLabel => '追加のコメント（任意）';

  @override
  String get reportSubmitButtonLabel => '報告を送信';

  @override
  String get reportSuccessSnackbar => '報告を送信しました。フィードバックありがとうございます。';

  @override
  String get reportFailureSnackbar => '報告の送信に失敗しました。';

  @override
  String get commentsTitle => 'コメント';

  @override
  String get commentPostButtonLabel => '投稿';

  @override
  String get commentInputHint => 'コメントを追加...';

  @override
  String get commentRequiresReactionError => 'コメントを投稿するにはリアクションを選択してください。';

  @override
  String get likeActionLabel => 'いいね';

  @override
  String get dislikeActionLabel => 'よくないね';

  @override
  String get commentActionLabel => 'コメント';

  @override
  String get moreActionLabel => 'もっと見る';

  @override
  String get rateAppPromptTitle => 'アプリを楽しんでいますか？';

  @override
  String get rateAppPromptBody => '評価をお願いできますか？';

  @override
  String get rateAppPromptYesButton => '素晴らしい！';

  @override
  String get rateAppPromptNoButton => '改善が必要';

  @override
  String get feedbackPromptTitle => 'どのように改善できますか？';

  @override
  String get feedbackPromptReasonUI => 'UI / デザイン';

  @override
  String get feedbackPromptReasonPerformance => 'パフォーマンス / 速度';

  @override
  String get feedbackPromptReasonContent => 'コンテンツの質';

  @override
  String get feedbackPromptReasonOther => 'その他';

  @override
  String get feedbackPromptSubmitButton => 'フィードバックを送信';

  @override
  String get rateAppNegativeFollowUpTitle_1 => '現在の状況はいかがですか？';

  @override
  String get rateAppNegativeFollowUpTitle_2 => '改善されましたか？';

  @override
  String get rateAppNegativeFollowUpBody_1 =>
      'フィードバックに基づき改善を行いました。評価を再検討していただけませんか？';

  @override
  String get rateAppNegativeFollowUpBody_2 =>
      '皆様のご意見を大切にしています。改善されたかどうか教えてください。';

  @override
  String get noCommentsYet => 'まだコメントはありません。';

  @override
  String get commentInputNoReactionHint => 'リアクションしてコメントを追加';

  @override
  String get headlineReportReasonMisinformation => '誤報またはフェイクニュース';

  @override
  String get headlineReportReasonClickbait => 'クリックベイトまたは紛らわしいタイトル';

  @override
  String get headlineReportReasonOffensive => '不快またはヘイトスピーチ';

  @override
  String get headlineReportReasonSpam => 'スパムまたは詐欺';

  @override
  String get headlineReportReasonBrokenLink => 'リンク切れ';

  @override
  String get headlineReportReasonPaywalled => 'ペイウォール（有料記事）';

  @override
  String get sourceReportReasonLowQuality => '質の低いジャーナリズム';

  @override
  String get sourceReportReasonHighAdDensity => '過度な広告またはポップアップ';

  @override
  String get sourceReportReasonFrequentPaywalls => '頻繁なペイウォール';

  @override
  String get sourceReportReasonImpersonation => 'なりすまし';

  @override
  String get sourceReportReasonMisinformation => '誤報';

  @override
  String get commentReportReasonSpam => 'スパムまたは広告';

  @override
  String get commentReportReasonHarassment => '嫌がらせまたはいじめ';

  @override
  String get commentReportReasonHateSpeech => 'ヘイトスピーチ';

  @override
  String get limitReachedTitle => '制限に達しました';

  @override
  String get manageMyContentButton => 'マイコンテンツを管理';

  @override
  String get upgradeButton => 'アップグレード';

  @override
  String get createAccountButton => 'アカウントを作成';

  @override
  String get gotItButton => '了解';

  @override
  String get commentsPageTitle => 'コメント';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のコメント',
    );
    return '$_temp0';
  }

  @override
  String get limitReachedGuestUserTitle => 'アカウントが必要です';

  @override
  String get limitReachedGuestUserBody =>
      'コミュニティに参加してこの機能を使用するには、無料アカウントを作成するかサインインしてください。';

  @override
  String get limitReachedBodyFollow =>
      'フォロー中のアイテムの制限に達しました。新しくフォローするには、既存のコンテンツを整理してください。';

  @override
  String get limitReachedBodySave =>
      '保存した記事の制限に達しました。新しく保存するには、既存の記事を整理してください。';

  @override
  String get limitReachedBodySaveFilters =>
      '保存されたフィルタの制限に達しました。新しく作成するには、既存のフィルタを整理してください。';

  @override
  String get limitReachedBodyPinFilters =>
      '固定されたフィルタの制限に達しました。新しく固定するには、既存のフィルタの固定を解除してください。';

  @override
  String get limitReachedBodySubscribeToNotifications =>
      '通知購読の制限に達しました。新しいアラートを購読するには、既存の購読を整理してください。';

  @override
  String get limitReachedBodyComments => '1日のコメント投稿制限に達しました。明日またお試しください。';

  @override
  String get limitReachedBodyReactions => '1日のリアクション制限に達しました。明日またお試しください。';

  @override
  String get limitReachedBodyReports => '1日の報告制限に達しました。明日またお試しください。';

  @override
  String get commentEditButtonLabel => '更新';

  @override
  String get commentPostFailureSnackbar => 'コメントの投稿に失敗しました。もう一度お試しください。';

  @override
  String get commentUpdateFailureSnackbar => 'コメントの更新に失敗しました。もう一度お試しください。';

  @override
  String get commentInputDisabledHint => 'サインインして会話に参加';

  @override
  String get commentInputExistingHint => 'この見出しには既にコメント済みです。';

  @override
  String commenterName(String id) {
    return 'ユーザー $id';
  }

  @override
  String get accountRewardsTile => '特典とオファー';

  @override
  String get rewardsPageTitle => '特典';

  @override
  String rewardsOfferTitle(String rewardName, String duration) {
    return '$duration間の$rewardNameを取得';
  }

  @override
  String rewardsOfferActiveTitle(String rewardName) {
    return '$rewardName 有効';
  }

  @override
  String rewardsOfferExpiresIn(String countdown) {
    return '有効期限: $countdown';
  }

  @override
  String get rewardsOfferWatchButton => '動画を視聴';

  @override
  String get rewardsOfferVerifyingButton => '確認中...';

  @override
  String get rewardsOfferLoadingButton => '広告を読み込み中...';

  @override
  String rewardsSnackbarSuccess(String rewardName) {
    return '特典解除: $rewardName が有効になりました。';
  }

  @override
  String get rewardsSnackbarFailure => '確認に失敗しました。しばらくしてからもう一度お試しください。';

  @override
  String get rewardsAdDismissedSnackbar => '広告が閉じられました。特典を獲得するには最後まで視聴してください。';

  @override
  String get decoratorUnlockRewardsTitle => '広告なしの体験を解除';

  @override
  String decoratorUnlockRewardsDescription(String duration) {
    return '短い動画を視聴して、$duration間アプリを広告なしで楽しみましょう。';
  }

  @override
  String get decoratorUnlockRewardsCta => '今すぐ視聴';

  @override
  String rewardsDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日間',
    );
    return '$_temp0';
  }

  @override
  String get rewardTypeAdFree => '広告なし';

  @override
  String get rewardTypeDailyDigest => 'デイリーダイジェスト';

  @override
  String get unlockMoreButton => 'さらに解除';

  @override
  String get requiresActiveReward => '有効な特典が必要です。アカウントページから特典を解除できます。';

  @override
  String get rewardsAdFreeTitle => '広告なしの体験を楽しむ';

  @override
  String rewardsAdFreeDescription(String duration) {
    return '短い動画を視聴して、$duration間アプリからすべての広告を削除します。';
  }

  @override
  String get rewardsDailyDigestTitle => 'デイリーニュースダイジェストを解除';

  @override
  String rewardsDailyDigestDescription(String duration) {
    return '「デイリーダイジェスト」オプションが有効な保存済みフィルタから、主要な見出しをまとめたプッシュ通知を毎日受け取ります。$duration間有効です。';
  }

  @override
  String get rewardsOfferActiveButton => '有効';

  @override
  String get rewardsAdFreePageTitle => '広告なし体験';

  @override
  String get rewardsAdFreeInactiveHeadline => '広告なしの体験を楽しむ';

  @override
  String rewardsAdFreeInactiveBody(String duration) {
    return '短い広告を視聴して、$duration間アプリを中断なしで楽しみましょう。';
  }

  @override
  String get rewardsAdFreeActiveHeadline => '広告なし体験が有効です';

  @override
  String get rewardsAdFreeActiveBody => '広告なしアクセスの有効期限:';

  @override
  String get appTourStep1Title => 'あなたにぴったりのニュース';

  @override
  String get appTourStep1Body =>
      'あなた専用のフィードを作成しましょう。関心のあるトピック、ソース、国をフォローすれば、あとはお任せください。';

  @override
  String get appTourStep2Title => 'キュレートして通知を受け取る';

  @override
  String get appTourStep2Body =>
      'あらゆるニッチな分野に合わせてカスタムニュースフィードを作成・保存。見逃せないニュースの速報アラートやデイリーダイジェストを購読しましょう。';

  @override
  String get appTourStep3Title => 'あなたの視点を共有';

  @override
  String get appTourStep3Body =>
      '記事にリアクションやコメントをして、グローバルコミュニティと交流しましょう。あなたの声が会話を形作ります。';

  @override
  String get appTourSkipButton => 'スキップ';

  @override
  String get appTourNextButton => '次へ';

  @override
  String get appTourGetStartedButton => 'はじめる';

  @override
  String get initialPersonalizationTitle => 'フィードをカスタマイズ';

  @override
  String get initialPersonalizationSubtitle =>
      'まずはトピック、ソース、または国をいくつかフォローしましょう。これらは後でいつでも変更できます。';

  @override
  String get initialPersonalizationStepTopicsTitle => 'トピックを選択';

  @override
  String get initialPersonalizationStepSourcesTitle => 'ソースを選択';

  @override
  String get initialPersonalizationStepCountriesTitle => '国を選択';

  @override
  String initialPersonalizationTotalSelectionCountLabel(int count) {
    return '$count件選択済み';
  }

  @override
  String get initialPersonalizationFinishButton => '完了';

  @override
  String get deleteAccountDialogTitle => 'アカウントの削除';

  @override
  String get deleteAccountDialogContent => '本当にアカウントを完全に削除しますか？この操作は取り消せません。';

  @override
  String get deleteAccountDialogConfirm => 'アカウントを削除';

  @override
  String get deleteAccountButton => 'アカウントを削除';

  @override
  String get followedContentEmpty => 'このカテゴリにはまだフォロー中のアイテムがありません。';

  @override
  String get followedContentEmptySubheadline =>
      'フォローしたアイテムがここに表示されます。「+」ボタンを使って追加してください。';

  @override
  String multiSelectSearchPageSelectionCount(int count, int total) {
    return '$count/$total';
  }

  @override
  String get guestUserDisplayName => 'ゲスト';

  @override
  String get accountPageSyncProgressButton => '進捗を同期';

  @override
  String get applyButtonLabel => '適用';

  @override
  String get commentStatusPending => '審査中';

  @override
  String get languageNameEn => '英語';

  @override
  String get languageNameEs => 'スペイン語';

  @override
  String get languageNameFr => 'フランス語';

  @override
  String get languageNameAr => 'アラビア語';

  @override
  String get languageNamePt => 'ポルトガル語';

  @override
  String get languageNameDe => 'ドイツ語';

  @override
  String get languageNameIt => 'イタリア語';

  @override
  String get languageNameZh => '中国語';

  @override
  String get languageNameHi => 'ヒンディー語';

  @override
  String get languageNameJa => '日本語';
}
