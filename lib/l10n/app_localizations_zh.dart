// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get accountLinkingPageTitle => '同步进度';

  @override
  String get accountLinkingGenericError => '发生错误';

  @override
  String get accountLinkingEmailSentSuccess => '请检查您的电子邮件以获取登录链接！';

  @override
  String get accountLinkingHeadline => '保存您的进度';

  @override
  String get accountLinkingBody => '创建一个账户，以便在您的所有设备上同步关注的项目和偏好设置。';

  @override
  String get accountLinkingContinueWithGoogleButton => '使用 Google 继续';

  @override
  String get accountLinkingEmailInputLabel => '输入您的电子邮件';

  @override
  String get accountLinkingEmailInputHint => 'you@example.com';

  @override
  String get accountLinkingEmailValidationError => '请输入有效的电子邮件地址';

  @override
  String get accountLinkingSendLinkButton => '使用电子邮件同步';

  @override
  String get accountPageTitle => '账户';

  @override
  String get accountAnonymousUser => '（匿名）';

  @override
  String get accountNoNameUser => '无姓名';

  @override
  String get accountStatusAuthenticated => '已认证';

  @override
  String get accountStatusAnonymous => '匿名会话';

  @override
  String get accountStatusUnauthenticated => '未登录';

  @override
  String get accountSettingsTile => '设置';

  @override
  String get accountSignOutTile => '退出登录';

  @override
  String get accountBackupTile => '创建账户以保存数据';

  @override
  String get accountContentPreferencesTile => '关注的内容';

  @override
  String get accountSavedHeadlinesTile => '已保存的头条';

  @override
  String accountRoleLabel(String role) {
    return '角色：$role';
  }

  @override
  String get accountMyContentSectionTitle => '我的内容';

  @override
  String get accountActivityAndRewardsSectionTitle => '活动与奖励';

  @override
  String get accountGeneralSectionTitle => '常规';

  @override
  String get accountEditProfileButton => '编辑个人资料';

  @override
  String get editProfilePageTitle => '编辑个人资料';

  @override
  String get editProfileNameInputLabel => '姓名';

  @override
  String get editProfileEmailInputLabel => '电子邮件';

  @override
  String get editProfileUpdateSuccessSnackbar => '个人资料更新成功。';

  @override
  String get editProfileUpdateFailureSnackbar => '更新个人资料失败。请重试。';

  @override
  String get followedContentPageTitle => '关注的项目';

  @override
  String get followedContentTopicsTab => '话题';

  @override
  String get followedContentSourcesTab => '来源';

  @override
  String get authenticationEmailSentSuccess => '请检查您的电子邮件以获取登录链接。';

  @override
  String get authenticationPageTitle => '登录 / 注册';

  @override
  String get authenticationEmailLabel => '电子邮件';

  @override
  String get authenticationSendLinkButton => '发送登录链接';

  @override
  String get authenticationOrDivider => '或';

  @override
  String get authenticationGoogleSignInButton => '使用 Google 登录';

  @override
  String get authenticationAnonymousSignInButton => '匿名继续';

  @override
  String get headlineDetailsInitialHeadline => '正在等待详情';

  @override
  String get headlineDetailsInitialSubheadline => '请稍候...';

  @override
  String get headlineDetailsLoadingHeadline => '正在加载头条';

  @override
  String get headlineDetailsLoadingSubheadline => '正在获取数据...';

  @override
  String get headlineDetailsContinueReadingButton => '继续阅读';

  @override
  String get headlinesFeedLoadingHeadline => '正在加载...';

  @override
  String get headlinesFeedLoadingSubheadline => '正在获取头条';

  @override
  String get headlinesFeedFilterTitle => '筛选头条';

  @override
  String get headlinesFeedFilterCategoryLabel => '类别';

  @override
  String get headlinesFeedFilterAllOption => '全部';

  @override
  String get headlinesFeedFilterCategoryTechnology => '科技';

  @override
  String get headlinesFeedFilterCategoryBusiness => '商业';

  @override
  String get headlinesFeedFilterCategorySports => '体育';

  @override
  String get headlinesFeedFilterSourceLabel => '来源';

  @override
  String get headlinesFeedFilterSourceCNN => 'CNN';

  @override
  String get headlinesFeedFilterSourceReuters => '路透社';

  @override
  String get headlinesFeedFilterEventCountryLabel => '国家';

  @override
  String get headlinesFeedFilterSourceCountryLabel => '总部所在地';

  @override
  String get headlinesFeedFilterCountryUS => '美国';

  @override
  String get headlinesFeedFilterCountryUK => '英国';

  @override
  String get headlinesFeedFilterCountryCA => '加拿大';

  @override
  String get headlinesFeedFilterApplyButton => '应用筛选';

  @override
  String get headlinesFeedFilterResetButton => '重置筛选';

  @override
  String get headlinesSearchHintText => '搜索头条...';

  @override
  String get headlinesSearchInitialHeadline => '即刻查找头条';

  @override
  String get headlinesSearchInitialSubheadline => '在上方输入关键词以发现新闻文章。';

  @override
  String get headlinesSearchNoResultsHeadline => '无结果';

  @override
  String get headlinesSearchNoResultsSubheadline => '请尝试不同的搜索词';

  @override
  String get authenticationEmailSignInButton => '使用电子邮件继续';

  @override
  String get authenticationLinkingHeadline => '同步您的进度';

  @override
  String get authenticationLinkingSubheadline => '创建一个账户，以便在设备间保存您的设置、内容偏好等。';

  @override
  String get authenticationSignInHeadline => 'Veritas';

  @override
  String get authenticationSignInSubheadline => '来自全球可信来源的未经过滤的新闻。';

  @override
  String get emailSignInPageTitle => '使用电子邮件登录';

  @override
  String get emailSignInExplanation => '在下方输入您的电子邮件。我们将向您发送一个安全的登录链接。无需密码！';

  @override
  String get emailLinkSentPageTitle => '检查您的电子邮件';

  @override
  String get emailLinkSentConfirmation =>
      '链接已发送！请检查您的电子邮件收件箱（及垃圾邮件箱）。点击邮件中的链接以完成登录。';

  @override
  String get accountConnectPrompt => '关联账户';

  @override
  String get accountConnectBenefit => '在设备间保存您的偏好设置和阅读历史。';

  @override
  String get bottomNavFeedLabel => '信息流';

  @override
  String get bottomNavSearchLabel => '搜索';

  @override
  String get bottomNavAccountLabel => '账户';

  @override
  String get accountNotificationsTile => '通知';

  @override
  String get headlinesSearchActionTooltip => '搜索';

  @override
  String get notificationsTooltip => '查看通知';

  @override
  String get accountSignInPromptButton => '注册 / 登录';

  @override
  String get categoryFilterLoadingHeadline => '正在加载类别...';

  @override
  String get categoryFilterLoadingSubheadline => '请稍候，正在获取可用类别。';

  @override
  String get categoryFilterEmptyHeadline => '未找到类别';

  @override
  String get categoryFilterEmptySubheadline => '目前没有可用的类别。';

  @override
  String get countryFilterLoadingHeadline => '正在加载国家...';

  @override
  String get countryFilterLoadingSubheadline => '请稍候，正在获取可用国家。';

  @override
  String get countryFilterEmptyHeadline => '未找到国家';

  @override
  String get countryFilterEmptySubheadline => '目前没有可用的国家。';

  @override
  String get headlinesFeedAppBarTitle => 'HT';

  @override
  String get headlinesFeedFilterTooltip => '筛选头条';

  @override
  String get headlinesFeedFilterAllLabel => '全部';

  @override
  String headlinesFeedFilterSelectedCountLabel(int count) {
    return '已选择 $count 个';
  }

  @override
  String get sourceFilterLoadingHeadline => '正在加载来源...';

  @override
  String get sourceFilterLoadingSubheadline => '请稍候，正在获取可用来源。';

  @override
  String get sourceFilterEmptyHeadline => '未找到来源';

  @override
  String get sourceFilterEmptySubheadline => '目前没有可用的来源。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLoadingHeadline => '正在加载设置...';

  @override
  String get settingsLoadingSubheadline => '请稍候，正在获取您的偏好设置。';

  @override
  String get settingsErrorDefault => '无法加载设置。';

  @override
  String get settingsAppearanceTitle => '外观';

  @override
  String get settingsFeedDisplayTitle => '信息流';

  @override
  String get settingsArticleDisplayTitle => '文章显示';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsAppearanceThemeModeLight => '浅色';

  @override
  String get settingsAppearanceThemeModeDark => '深色';

  @override
  String get settingsAppearanceThemeModeSystem => '系统';

  @override
  String get settingsAppearanceThemeNameRed => '红色';

  @override
  String get settingsAppearanceThemeNameBlue => '蓝色';

  @override
  String get settingsAppearanceThemeNameGrey => '灰色';

  @override
  String get settingsAppearanceFontSizeSmall => '小';

  @override
  String get settingsAppearanceFontSizeLarge => '大';

  @override
  String get settingsAppearanceFontSizeMedium => '中';

  @override
  String get settingsAppearanceThemeModeLabel => '主题模式';

  @override
  String get settingsAppearanceThemeNameLabel => '配色方案';

  @override
  String get settingsAppearanceAppFontSizeLabel => '应用字体大小';

  @override
  String get settingsAppearanceAppFontTypeLabel => '应用字体';

  @override
  String get settingsAppearanceFontWeightLabel => '字体粗细';

  @override
  String get settingsFeedTileTypeImageTop => '图片置顶';

  @override
  String get settingsFeedTileTypeImageStart => '图片居前';

  @override
  String get settingsFeedTileTypeTextOnly => '仅文字';

  @override
  String get settingsFeedTileTypeLabel => '信息流卡片布局';

  @override
  String get settingsArticleFontSizeLabel => '文章字体大小';

  @override
  String get settingsNotificationsEnableLabel => '启用通知';

  @override
  String get settingsNotificationsCategoriesLabel => '关注的类别';

  @override
  String get settingsNotificationsSourcesLabel => '关注的来源';

  @override
  String get settingsNotificationsCountriesLabel => '关注的国家';

  @override
  String get settingsAppearanceSectionTitle => '外观';

  @override
  String get settingsFeedSectionTitle => '信息流';

  @override
  String get settingsGeneralSectionTitle => '常规';

  @override
  String get settingsAccentColorAndFontsTitle => '强调色与字体';

  @override
  String get settingsAccentColorLabel => '强调色';

  @override
  String get settingsFontFamilyLabel => '字体系列';

  @override
  String get settingsLayoutAndReadingTitle => '布局与阅读';

  @override
  String get appName => '头条工具箱';

  @override
  String get unknownError => '发生未知错误。';

  @override
  String get loadMoreError => '无法加载更多项目。';

  @override
  String get settingsAppearanceFontSizeExtraLarge => '特大';

  @override
  String get settingsAppearanceFontFamilySystemDefault => '系统默认';

  @override
  String get settingsAppearanceFontFamilyRoboto => 'Roboto';

  @override
  String get settingsAppearanceFontFamilyOpenSans => 'Open Sans';

  @override
  String get settingsAppearanceThemeSubPageTitle => '主题设置';

  @override
  String get settingsAppearanceFontSubPageTitle => '字体设置';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get emailCodeSentPageTitle => '输入代码';

  @override
  String emailCodeSentConfirmation(String email) {
    return '验证码已发送至 $email。请在下方输入。';
  }

  @override
  String get emailCodeSentInstructions => '请输入您收到的 6 位代码。';

  @override
  String get emailCodeVerificationHint => '6 位代码';

  @override
  String get emailCodeVerificationButtonLabel => '验证代码';

  @override
  String get emailCodeValidationEmptyError => '请输入 6 位代码。';

  @override
  String get emailCodeValidationLengthError => '代码必须为 6 位。';

  @override
  String get headlinesFeedEmptyFilteredHeadline => '没有符合筛选条件的头条';

  @override
  String get headlinesFeedEmptyFilteredSubheadline => '请尝试调整筛选标准或清除筛选以查看所有头条。';

  @override
  String get headlinesFeedClearFiltersButton => '清除筛选';

  @override
  String get headlinesFeedFilterLoadingCriteria => '正在加载筛选选项...';

  @override
  String get pleaseWait => '请稍候...';

  @override
  String get headlinesFeedFilterErrorCriteria => '无法加载筛选选项。';

  @override
  String get headlinesFeedFilterCountryLabel => '国家';

  @override
  String get headlinesFeedFilterSourceTypeLabel => '类型';

  @override
  String get headlinesFeedFilterErrorSources => '无法加载来源。';

  @override
  String get headlinesFeedFilterNoSourcesMatch => '没有符合所选筛选条件的来源。';

  @override
  String get searchModelTypeHeadline => '头条';

  @override
  String get searchModelTypeCategory => '类别';

  @override
  String get searchModelTypeSource => '来源';

  @override
  String get searchModelTypeCountry => '国家';

  @override
  String get searchHintTextHeadline => '例如：AI 进展、火星探测器...';

  @override
  String get searchHintTextGeneric => '搜索...';

  @override
  String get searchHintTextCategory => '例如：科技、体育、金融...';

  @override
  String get searchHintTextSource => '例如：BBC 新闻、TechCrunch、路透社...';

  @override
  String get searchHintTextCountry => '例如：美国、日本、巴西...';

  @override
  String get searchPageInitialHeadline => '开始搜索';

  @override
  String get searchPageInitialSubheadline => '选择类型并输入关键词以开始。';

  @override
  String get followedCategoriesPageTitle => '关注的类别';

  @override
  String get addCategoriesTooltip => '添加类别';

  @override
  String get noFollowedCategoriesMessage => '您尚未关注任何类别。';

  @override
  String get addCategoriesButtonLabel => '查找要关注的类别';

  @override
  String unfollowCategoryTooltip(String categoryName) {
    return '取消关注 $categoryName';
  }

  @override
  String get addTopicsPageTitle => '关注话题';

  @override
  String get topicFilterLoadingHeadline => '正在加载话题...';

  @override
  String get topicFilterError => '无法加载话题。请重试。';

  @override
  String get topicFilterEmptyHeadline => '未找到话题';

  @override
  String get topicFilterEmptySubheadline => '目前没有可用的话题。';

  @override
  String unfollowTopicTooltip(String topicName) {
    return '取消关注 $topicName';
  }

  @override
  String followTopicTooltip(String topicName) {
    return '关注 $topicName';
  }

  @override
  String get followedSourcesLoadingHeadline => '正在加载关注的来源...';

  @override
  String get followedSourcesErrorHeadline => '无法加载关注的来源';

  @override
  String get followedSourcesEmptyHeadline => '无关注的来源';

  @override
  String get followedSourcesEmptySubheadline => '开始关注来源以在此处查看它们。';

  @override
  String get headlinesFeedFilterTopicLabel => '话题';

  @override
  String get followedTopicsPageTitle => '关注的话题';

  @override
  String get addTopicsTooltip => '添加话题';

  @override
  String get followedTopicsLoadingHeadline => '正在加载关注的话题...';

  @override
  String get followedTopicsErrorHeadline => '无法加载关注的话题';

  @override
  String get followedTopicsEmptyHeadline => '无关注的话题';

  @override
  String get followedTopicsEmptySubheadline => '开始关注话题以在此处查看它们。';

  @override
  String get followedSourcesPageTitle => '关注的来源';

  @override
  String get addSourcesTooltip => '添加来源';

  @override
  String get noFollowedSourcesMessage => '您尚未关注任何来源。';

  @override
  String get addSourcesButtonLabel => '查找要关注的来源';

  @override
  String unfollowSourceTooltip(String sourceName) {
    return '取消关注 $sourceName';
  }

  @override
  String get followedCountriesPageTitle => '关注的国家';

  @override
  String get addCountriesTooltip => '添加国家';

  @override
  String get noFollowedCountriesMessage => '您尚未关注任何国家。';

  @override
  String get addCountriesButtonLabel => '查找要关注的国家';

  @override
  String unfollowCountryTooltip(String countryName) {
    return '取消关注 $countryName';
  }

  @override
  String get addCategoriesPageTitle => '添加要关注的类别';

  @override
  String get categoryFilterError => '无法加载类别。请重试。';

  @override
  String followCategoryTooltip(String categoryName) {
    return '关注 $categoryName';
  }

  @override
  String get addSourcesPageTitle => '添加要关注的来源';

  @override
  String get sourceFilterError => '无法加载来源。请重试。';

  @override
  String followSourceTooltip(String sourceName) {
    return '关注 $sourceName';
  }

  @override
  String get addCountriesPageTitle => '添加要关注的国家';

  @override
  String followCountryTooltip(String countryName) {
    return '关注 $countryName';
  }

  @override
  String get headlineDetailsSaveTooltip => '保存头条';

  @override
  String get headlineDetailsRemoveFromSavedTooltip => '从已保存中移除';

  @override
  String get headlineSavedSuccessSnackbar => '头条已保存！';

  @override
  String get headlineUnsavedSuccessSnackbar => '头条已从保存中移除。';

  @override
  String get headlineSaveErrorSnackbar => '无法更新保存状态。请重试。';

  @override
  String get shareActionTooltip => '分享头条';

  @override
  String get sharingUnavailableSnackbar => '此设备或平台不支持分享。';

  @override
  String get similarHeadlinesSectionTitle => '您可能也喜欢';

  @override
  String get similarHeadlinesEmpty => '未找到相似头条。';

  @override
  String get detailsPageTitle => '详情';

  @override
  String get followButtonLabel => '关注';

  @override
  String get unfollowButtonLabel => '取消关注';

  @override
  String get noHeadlinesFoundMessage => '未找到此项目的头条。';

  @override
  String get failedToLoadMoreHeadlines => '无法加载更多头条。';

  @override
  String get headlinesSectionTitle => '头条';

  @override
  String get headlinesFeedFilterApplyFollowedLabel => '应用我关注的项目作为筛选条件';

  @override
  String get mustBeLoggedInToUseFeatureError => '您必须登录才能使用此功能。';

  @override
  String get noFollowedItemsForFilterSnackbar => '您尚未关注任何可用作筛选条件的项目。';

  @override
  String get requestCodePageHeadline => '输入您的电子邮件';

  @override
  String get requestCodePageSubheadline => '我们将向您的电子邮件发送一个安全代码以验证您的身份。';

  @override
  String get requestCodeEmailLabel => '电子邮件地址';

  @override
  String get requestCodeEmailHint => 'you@example.com';

  @override
  String get requestCodeSendCodeButton => '发送代码';

  @override
  String requestCodeResendButtonCooldown(int seconds) {
    return '$seconds 秒后重发';
  }

  @override
  String get entityDetailsCategoryTitle => '类别';

  @override
  String get entityDetailsSourceTitle => '来源';

  @override
  String get entityDetailsTopicTitle => '话题';

  @override
  String get entityDetailsCountryTitle => '国家';

  @override
  String get savedHeadlinesLoadingHeadline => '正在加载已保存的头条...';

  @override
  String get savedHeadlinesLoadingSubheadline => '请稍候，正在获取您保存的文章。';

  @override
  String get savedHeadlinesErrorHeadline => '无法加载已保存的头条';

  @override
  String get savedHeadlinesEmptyHeadline => '无已保存的头条';

  @override
  String get savedHeadlinesEmptySubheadline => '您尚未保存任何文章。开始探索吧！';

  @override
  String get accountFollowedCountriesTile => '关注的国家';

  @override
  String get followedCountriesLoadingHeadline => '正在加载关注的国家...';

  @override
  String get followedCountriesErrorHeadline => '无法加载关注的国家';

  @override
  String get followedCountriesEmptyHeadline => '无关注的国家';

  @override
  String get followedCountriesEmptySubheadline => '开始关注国家以在此处查看它们。';

  @override
  String get countryFilterError => '无法加载国家。请重试。';

  @override
  String get followedCategoriesLoadingHeadline => '正在加载关注的类别...';

  @override
  String get followedCategoriesErrorHeadline => '无法加载关注的类别';

  @override
  String get followedCategoriesEmptyHeadline => '无关注的类别';

  @override
  String get followedCategoriesEmptySubheadline => '开始关注类别以在此处查看它们。';

  @override
  String get contentTypeHeadline => '头条';

  @override
  String get contentTypeTopic => '话题';

  @override
  String get contentTypeSource => '来源';

  @override
  String get contentTypeCountry => '国家';

  @override
  String searchingFor(String contentType) {
    return '正在搜索 $contentType...';
  }

  @override
  String get settingsAppearanceFontWeightLight => '细体';

  @override
  String get settingsAppearanceFontWeightRegular => '常规';

  @override
  String get settingsAppearanceFontWeightBold => '粗体';

  @override
  String get maintenanceHeadline => '维护中';

  @override
  String get maintenanceSubheadline => '我们目前正在进行维护。请稍后再试。';

  @override
  String get updateRequiredHeadline => '需要更新';

  @override
  String get updateRequiredSubheadline => '应用有新版本可用。请更新以继续使用。';

  @override
  String get updateRequiredButton => '立即更新';

  @override
  String get neverShowAgain => '不再显示';

  @override
  String get followButtonText => '关注';

  @override
  String get unfollowButtonText => '取消关注';

  @override
  String get adInfoPlaceholderText => '广告有助于保持此应用免费！';

  @override
  String get retryButtonText => '重试';

  @override
  String get headlinesFeedFilterLoadingHeadline => '正在加载筛选条件';

  @override
  String get suggestedTopicsTitle => '推荐话题';

  @override
  String get suggestedSourcesTitle => '推荐来源';

  @override
  String couldNotOpenUpdateUrl(String url) {
    return '无法打开更新链接：$url';
  }

  @override
  String currentAppVersionLabel(String version) {
    return '当前版本：$version';
  }

  @override
  String latestRequiredVersionLabel(String version) {
    return '所需版本：$version';
  }

  @override
  String get anonymousLimitTitle => '登录以执行更多操作';

  @override
  String get anonymousLimitBody => '创建一个免费账户以保存更多书签并关注更多内容。';

  @override
  String get anonymousLimitButton => '登录';

  @override
  String get standardLimitBody => '您已达到免费计划的上限。升级以保存和关注更多内容。';

  @override
  String get standardLimitButton => '升级到高级版';

  @override
  String get premiumLimitTitle => '您已达到上限';

  @override
  String get premiumLimitBody => '要添加新项目，请查看并管理您现有的已保存和已关注内容。';

  @override
  String get premiumLimitButton => '管理我的内容';

  @override
  String get saveButtonLabel => '保存';

  @override
  String get cancelButtonLabel => '取消';

  @override
  String get manageFiltersPageTitle => '管理筛选';

  @override
  String get manageFiltersEmptyHeadline => '无已保存的筛选';

  @override
  String get manageFiltersEmptySubheadline => '您可以从筛选页面保存筛选条件。';

  @override
  String get manageFiltersRenameTooltip => '重命名筛选';

  @override
  String get manageFiltersDeleteTooltip => '删除筛选';

  @override
  String get saveFilterDialogTitleSave => '保存筛选';

  @override
  String get saveFilterDialogTitleRename => '重命名筛选';

  @override
  String get saveFilterDialogInputLabel => '筛选名称';

  @override
  String get saveFilterDialogValidationEmpty => '名称不能为空';

  @override
  String get saveFilterDialogValidationTooLong => '名称太长';

  @override
  String get saveFilterDialogGenericError => '保存筛选时发生意外错误。';

  @override
  String get headlinesFilterSaveTooltip => '保存筛选';

  @override
  String get headlinesFilterManageTooltip => '管理筛选';

  @override
  String get savedFiltersBarOpenTooltip => '打开筛选';

  @override
  String get savedFiltersBarAllLabel => '全部';

  @override
  String get savedFiltersBarCustomLabel => '自定义';

  @override
  String get applyFilterDialogTitle => '应用筛选';

  @override
  String get applyFilterDialogContent => '您是想仅在本次会话中应用这些筛选设置，还是保存以供将来使用？';

  @override
  String get applyFilterDialogApplyOnlyButton => '仅应用';

  @override
  String get applyFilterDialogApplyAndSaveButton => '应用并保存';

  @override
  String get savedFiltersBarFollowedLabel => '已关注';

  @override
  String get sourceListFilterPageTitle => '筛选来源';

  @override
  String get sourceListFilterPageFilterButtonTooltip => '筛选来源列表';

  @override
  String get sourceListFilterByHeadquartersPageTitle => '总部位置';

  @override
  String get savedFiltersPageTitle => '已保存的筛选';

  @override
  String get savedFiltersEmptyHeadline => '无已保存的筛选';

  @override
  String get savedFiltersEmptySubheadline => '您从信息流中保存的筛选将显示在此处。';

  @override
  String get savedFiltersMenuRename => '重命名';

  @override
  String get savedFiltersMenuDelete => '删除';

  @override
  String get discoverPageTitle => '发现';

  @override
  String get bottomNavDiscoverLabel => '发现';

  @override
  String get feedSearchHint => '搜索头条...';

  @override
  String get headlineSearchEnterQuery => '从数千个来源中查找头条。';

  @override
  String get headlineSearchEnterQuerySubheadline => '通过关键词搜索以查找来自数千个来源的文章。';

  @override
  String get headlineSearchNoResults => '未找到头条。';

  @override
  String get headlineSearchNoResultsSubheadline => '我们找不到符合您搜索条件的头条。请尝试不同的关键词。';

  @override
  String get accountGuestAccount => '游客账户';

  @override
  String get accountRoleStandard => '标准用户';

  @override
  String get accountRolePremium => '高级用户';

  @override
  String get deleteConfirmationDialogTitle => '确认删除';

  @override
  String get deleteConfirmationDialogContent => '您确定要删除此项目吗？此操作无法撤销。';

  @override
  String get deleteConfirmationDialogConfirmButton => '删除';

  @override
  String get headlineSearchInitialHeadline => '搜索头条';

  @override
  String get headlineSearchInitialSubheadline => '输入关键词以查找文章。';

  @override
  String get accountGuestUserHeadline => '游客账户';

  @override
  String get accountGuestUserSubheadline => '登录以同步您的数据';

  @override
  String get discoverSearchHint => '搜索来源...';

  @override
  String get seeAllButtonLabel => '查看全部';

  @override
  String get failedToLoadMoreSources => '无法加载更多来源。';

  @override
  String get sourceTypeNewsAgency => '通讯社';

  @override
  String get sourceTypeLocalNewsOutlet => '地方新闻媒体';

  @override
  String get sourceTypeNationalNewsOutlet => '国家新闻媒体';

  @override
  String get sourceTypeInternationalNewsOutlet => '国际新闻媒体';

  @override
  String get sourceTypeSpecializedPublisher => '专业出版商';

  @override
  String get sourceTypeBlog => '博客';

  @override
  String get sourceTypeGovernmentSource => '政府来源';

  @override
  String get sourceTypeAggregator => '聚合器';

  @override
  String get sourceTypeOther => '其他';

  @override
  String get sourceTypeNewsAgencies => '通讯社';

  @override
  String get sourceTypeLocalNewsOutlets => '地方新闻媒体';

  @override
  String get sourceTypeNationalNewsOutlets => '国家新闻媒体';

  @override
  String get sourceTypeInternationalNewsOutlets => '国际新闻媒体';

  @override
  String get sourceTypeSpecializedPublishers => '专业出版商';

  @override
  String get sourceTypeBlogs => '博客';

  @override
  String get sourceTypeGovernmentSources => '政府来源';

  @override
  String get sourceTypeAggregators => '聚合器';

  @override
  String get sourceTypeOthers => '其他';

  @override
  String get sourceTypeFilterEmptyHeadline => '未找到来源类型';

  @override
  String get sourceTypeFilterEmptySubheadline => '目前没有可用的来源类型供筛选。';

  @override
  String get decoratorDismissedConfirmation => '建议已隐藏。';

  @override
  String get decoratorDismissAction => '隐藏建议';

  @override
  String get decoratorLinkAccountTitle_1 => '保存您的文章与偏好';

  @override
  String get decoratorLinkAccountTitle_2 => '永不丢失您保存的偏好';

  @override
  String get decoratorLinkAccountDescription_1 =>
      '创建一个免费账户以保存更多文章、关注更多话题，并在设备间同步您的偏好。';

  @override
  String get decoratorLinkAccountDescription_2 =>
      '注册以解锁更多保存、扩展关注内容，并让您的新闻流在各处保持一致。';

  @override
  String get decoratorLinkAccountCta_1 => '立即注册';

  @override
  String get decoratorLinkAccountCta_2 => '创建免费账户';

  @override
  String get decoratorUpgradeTitle_1 => '享受不间断的新闻体验';

  @override
  String get decoratorUpgradeTitle_2 => '解锁您的高级访问权限';

  @override
  String get decoratorUpgradeDescription_1 => '去广告并大幅扩展您保存文章和关注内容的上限。';

  @override
  String get decoratorUpgradeDescription_2 =>
      '升级到高级版以获得无广告体验，并能够保存和关注更多您喜爱的内容。';

  @override
  String get decoratorUpgradeCta_1 => '升级到高级版';

  @override
  String get decoratorUpgradeCta_2 => '了解更多';

  @override
  String get decoratorRateAppTitle_1 => '喜欢这个应用吗？';

  @override
  String get decoratorRateAppTitle_2 => '分享您的反馈';

  @override
  String get decoratorRateAppDescription_1 => '您的评分有助于我们为每个人改进新闻体验。您的意见很重要！';

  @override
  String get decoratorRateAppDescription_2 => '您的反馈有助于我们提供更好的新闻。请花一点时间为我们评分！';

  @override
  String get decoratorRateAppCta_1 => '立即评分';

  @override
  String get decoratorRateAppCta_2 => '提供反馈';

  @override
  String get decoratorEnableNotificationsTitle_1 => '绝不错过突发新闻';

  @override
  String get decoratorEnableNotificationsTitle_2 => '即时掌握资讯';

  @override
  String get decoratorEnableNotificationsDescription_1 =>
      '获取您关注的话题和来源的突发新闻即时提醒和更新。';

  @override
  String get decoratorEnableNotificationsDescription_2 =>
      '启用通知以直接在您的设备上接收个性化的新闻更新。';

  @override
  String get decoratorEnableNotificationsCta_1 => '开启提醒';

  @override
  String get decoratorEnableNotificationsCta_2 => '开启通知';

  @override
  String get decoratorSuggestedTopicsTitle_1 => '发现新兴趣';

  @override
  String get decoratorSuggestedTopicsTitle_2 => '拓宽您的知识面';

  @override
  String get decoratorSuggestedSourcesTitle_1 => '寻找新视角';

  @override
  String get decoratorSuggestedSourcesTitle_2 => '发现可信来源';

  @override
  String get savedHeadlineFiltersPageTitle => '已保存的筛选';

  @override
  String get savedHeadlineFiltersCreateNewButton => '创建筛选';

  @override
  String get savedHeadlineFiltersLoadingHeadline => '正在加载您的筛选...';

  @override
  String get savedHeadlineFiltersEmptyHeadline => '尚无已保存的筛选';

  @override
  String get savedHeadlineFiltersEmptySubheadline =>
      '您创建并保存的筛选将显示在此处。点击下方按钮开始。';

  @override
  String get savedFiltersMenuEdit => '编辑';

  @override
  String get saveFilterDialogPinToFeedLabel => '固定到筛选栏';

  @override
  String get saveFilterDialogNotificationsLabel => '通知偏好';

  @override
  String get notificationDeliveryTypeBreakingOnly => '突发新闻';

  @override
  String get notificationDeliveryTypeDailyDigest => '每日摘要';

  @override
  String get notificationDeliveryTypeWeeklyRoundup => '每周回顾';

  @override
  String get prePermissionDialogTitle => '启用通知？';

  @override
  String get prePermissionDialogBody => '为了向您发送此筛选条件的突发新闻提醒和摘要，请允许通知。';

  @override
  String get prePermissionDialogDenyButton => '以后再说';

  @override
  String get prePermissionDialogAllowButton => '允许';

  @override
  String get notificationPermissionDeniedError => '通知权限被拒绝。您可以在设备设置中启用它。';

  @override
  String get notificationCenterPageTitle => '通知';

  @override
  String get notificationCenterMarkAllAsReadButton => '全部标记为已读';

  @override
  String get notificationCenterLoadingHeadline => '正在加载通知...';

  @override
  String get notificationCenterLoadingSubheadline => '请稍候...';

  @override
  String get notificationCenterFailureHeadline => '加载通知失败';

  @override
  String get notificationCenterFailureSubheadline => '无法检索您的通知。请重试。';

  @override
  String get notificationCenterEmptyHeadline => '无通知';

  @override
  String get notificationCenterEmptySubheadline => '您没有新通知。';

  @override
  String get notificationCenterTabBreakingNews => '突发新闻';

  @override
  String get notificationCenterTabDigests => '摘要';

  @override
  String get deleteReadNotificationsButtonTooltip => '删除所有已读通知';

  @override
  String get deleteReadNotificationsDialogContent =>
      '您确定要删除此标签页中的所有已读通知吗？此操作无法撤销。';

  @override
  String get deleteButtonLabel => '删除';

  @override
  String get breakingNewsPrefix => '突发新闻';

  @override
  String get settingsFeedClickBehaviorLabel => '打开链接方式';

  @override
  String get settingsFeedClickBehaviorDefault => '应用默认';

  @override
  String get settingsFeedClickBehaviorInApp => '应用内浏览器';

  @override
  String get settingsFeedClickBehaviorSystem => '系统浏览器';

  @override
  String get continueToArticleButtonLabel => '继续阅读文章';

  @override
  String get headlineActionsModalTitle => '操作';

  @override
  String get shareActionLabel => '分享';

  @override
  String get bookmarkActionLabel => '书签';

  @override
  String get removeBookmarkActionLabel => '移除书签';

  @override
  String get reportActionLabel => '举报';

  @override
  String get reportContentTitle => '举报内容';

  @override
  String get reportReasonSelectionPrompt => '请选择举报原因：';

  @override
  String get reportAdditionalCommentsLabel => '附加评论（可选）';

  @override
  String get reportSubmitButtonLabel => '提交举报';

  @override
  String get reportSuccessSnackbar => '举报已提交。感谢您的反馈。';

  @override
  String get reportFailureSnackbar => '提交举报失败。请重试。';

  @override
  String get commentsTitle => '评论';

  @override
  String get commentPostButtonLabel => '发布';

  @override
  String get commentInputHint => '添加评论...';

  @override
  String get commentRequiresReactionError => '请选择一个反应以发布评论。';

  @override
  String get likeActionLabel => '点赞';

  @override
  String get dislikeActionLabel => '踩';

  @override
  String get commentActionLabel => '评论';

  @override
  String get moreActionLabel => '更多';

  @override
  String get rateAppPromptTitle => '喜欢这个应用吗？';

  @override
  String get rateAppPromptBody => '您的反馈有助于我们改进。您介意为我们评分吗？';

  @override
  String get rateAppPromptYesButton => '太棒了！';

  @override
  String get rateAppPromptNoButton => '还有待改进';

  @override
  String get feedbackPromptTitle => '我们该如何改进？';

  @override
  String get feedbackPromptReasonUI => 'UI / 设计';

  @override
  String get feedbackPromptReasonPerformance => '性能 / 速度';

  @override
  String get feedbackPromptReasonContent => '内容质量';

  @override
  String get feedbackPromptReasonOther => '其他';

  @override
  String get feedbackPromptSubmitButton => '提交反馈';

  @override
  String get rateAppNegativeFollowUpTitle_1 => '我们现在做得怎么样？';

  @override
  String get rateAppNegativeFollowUpTitle_2 => '我们有改进吗？';

  @override
  String get rateAppNegativeFollowUpBody_1 => '我们一直在根据您的反馈进行改进。您会重新考虑您的评分吗？';

  @override
  String get rateAppNegativeFollowUpBody_2 => '我们重视您的意见。如果情况变好了，请告诉我们。';

  @override
  String get noCommentsYet => '暂无评论。';

  @override
  String get commentInputNoReactionHint => '做出反应以添加评论';

  @override
  String get headlineReportReasonMisinformation => '虚假信息或假新闻';

  @override
  String get headlineReportReasonClickbait => '标题党或误导性标题';

  @override
  String get headlineReportReasonOffensive => '冒犯性或仇恨言论';

  @override
  String get headlineReportReasonSpam => '垃圾信息或诈骗';

  @override
  String get headlineReportReasonBrokenLink => '链接失效';

  @override
  String get headlineReportReasonPaywalled => '付费墙内容';

  @override
  String get sourceReportReasonLowQuality => '低质量新闻';

  @override
  String get sourceReportReasonHighAdDensity => '广告或弹窗过多';

  @override
  String get sourceReportReasonFrequentPaywalls => '频繁出现付费墙';

  @override
  String get sourceReportReasonImpersonation => '冒充他人';

  @override
  String get sourceReportReasonMisinformation => '虚假信息';

  @override
  String get commentReportReasonSpam => '垃圾信息或广告';

  @override
  String get commentReportReasonHarassment => '骚扰或欺凌';

  @override
  String get commentReportReasonHateSpeech => '仇恨言论';

  @override
  String get limitReachedTitle => '已达上限';

  @override
  String get manageMyContentButton => '管理我的内容';

  @override
  String get upgradeButton => '升级';

  @override
  String get createAccountButton => '创建账户';

  @override
  String get gotItButton => '知道了';

  @override
  String get commentsPageTitle => '评论';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条评论',
      one: '1 条评论',
    );
    return '$_temp0';
  }

  @override
  String get limitReachedGuestUserTitle => '需要账户';

  @override
  String get limitReachedGuestUserBody => '请创建一个免费账户或登录，以便参与社区互动并使用此功能。';

  @override
  String get limitReachedBodyFollow => '您已达到关注项目的上限。要关注更多，请查看您现有的关注内容。';

  @override
  String get limitReachedBodySave => '您已达到保存文章的上限。要保存更多，请查看您现有的已保存文章。';

  @override
  String get limitReachedBodySaveFilters => '您已达到保存筛选条件的上限。要创建新筛选，请查看您现有的筛选条件。';

  @override
  String get limitReachedBodyPinFilters => '您已达到固定筛选条件的上限。要固定新筛选，请取消固定现有筛选。';

  @override
  String get limitReachedBodySubscribeToNotifications =>
      '您已达到通知订阅的上限。要订阅新提醒，请查看您现有的订阅。';

  @override
  String get limitReachedBodyComments => '您已达到每日发布评论的上限。请明天再试。';

  @override
  String get limitReachedBodyReactions => '您已达到每日反应的上限。请明天再试。';

  @override
  String get limitReachedBodyReports => '您已达到每日提交举报的上限。请明天再试。';

  @override
  String get commentEditButtonLabel => '更新';

  @override
  String get commentPostFailureSnackbar => '发布评论失败。请重试。';

  @override
  String get commentUpdateFailureSnackbar => '更新评论失败。请重试。';

  @override
  String get commentInputDisabledHint => '登录以加入对话';

  @override
  String get commentInputExistingHint => '您已经对此头条发表过评论。';

  @override
  String commenterName(String id) {
    return '用户 $id';
  }

  @override
  String get accountRewardsTile => '奖励与优惠';

  @override
  String get rewardsPageTitle => '奖励';

  @override
  String rewardsOfferTitle(String rewardName, String duration) {
    return '获取 $rewardName，时长 $duration';
  }

  @override
  String rewardsOfferActiveTitle(String rewardName) {
    return '$rewardName 已激活';
  }

  @override
  String rewardsOfferExpiresIn(String countdown) {
    return '过期时间：$countdown';
  }

  @override
  String get rewardsOfferWatchButton => '观看视频';

  @override
  String get rewardsOfferVerifyingButton => '正在验证...';

  @override
  String get rewardsOfferLoadingButton => '正在加载广告...';

  @override
  String rewardsSnackbarSuccess(String rewardName) {
    return '奖励已解锁：$rewardName 现已激活。';
  }

  @override
  String get rewardsSnackbarFailure => '验证失败。请稍后重试。';

  @override
  String get rewardsAdDismissedSnackbar => '广告已关闭。请观看完整广告以赚取奖励。';

  @override
  String get decoratorUnlockRewardsTitle => '解锁无广告体验';

  @override
  String decoratorUnlockRewardsDescription(String duration) {
    return '观看一段短视频，即可在 $duration 内享受无广告的应用体验。';
  }

  @override
  String get decoratorUnlockRewardsCta => '立即观看';

  @override
  String rewardsDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
      one: '1 天',
    );
    return '$_temp0';
  }

  @override
  String get rewardTypeAdFree => '无广告';

  @override
  String get rewardTypeDailyDigest => '每日摘要';

  @override
  String get unlockMoreButton => '解锁更多';

  @override
  String get requiresActiveReward => '需要激活奖励。您可以从“账户”页面解锁奖励。';

  @override
  String get rewardsAdFreeTitle => '享受无广告体验';

  @override
  String rewardsAdFreeDescription(String duration) {
    return '观看一段短视频，即可在 $duration 内移除应用中的所有广告。';
  }

  @override
  String get rewardsDailyDigestTitle => '解锁每日新闻摘要';

  @override
  String rewardsDailyDigestDescription(String duration) {
    return '接收每日推送通知，总结您已启用“每日摘要”选项的已保存筛选条件中的顶级头条。有效期为 $duration。';
  }

  @override
  String get rewardsOfferActiveButton => '已激活';

  @override
  String get rewardsAdFreePageTitle => '无广告体验';

  @override
  String get rewardsAdFreeInactiveHeadline => '享受无广告体验';

  @override
  String rewardsAdFreeInactiveBody(String duration) {
    return '观看一段短广告，即可在 $duration 内享受无干扰的应用体验。';
  }

  @override
  String get rewardsAdFreeActiveHeadline => '无广告体验已激活';

  @override
  String get rewardsAdFreeActiveBody => '您的无广告权限过期时间：';

  @override
  String get appTourStep1Title => '您的新闻，完美定制';

  @override
  String get appTourStep1Body => '获取为您量身定制的信息流。关注您最感兴趣的话题、来源和国家，剩下的交给我们。';

  @override
  String get appTourStep2Title => '策划并获取通知';

  @override
  String get appTourStep2Body => '为任何细分领域创建并保存自定义新闻流。订阅突发新闻提醒或每日摘要，掌握不容错过的故事。';

  @override
  String get appTourStep3Title => '分享您的观点';

  @override
  String get appTourStep3Body => '对文章做出反应并发表评论，与全球社区互动。您的声音有助于塑造对话。';

  @override
  String get appTourSkipButton => '跳过';

  @override
  String get appTourNextButton => '下一步';

  @override
  String get appTourGetStartedButton => '开始使用';

  @override
  String get initialPersonalizationTitle => '自定义您的信息流';

  @override
  String get initialPersonalizationSubtitle => '关注一些话题、来源或国家以开始。您可以随时更改这些设置。';

  @override
  String get initialPersonalizationStepTopicsTitle => '选择话题';

  @override
  String get initialPersonalizationStepSourcesTitle => '选择来源';

  @override
  String get initialPersonalizationStepCountriesTitle => '选择国家';

  @override
  String initialPersonalizationTotalSelectionCountLabel(int count) {
    return '已选择 $count 个';
  }

  @override
  String get initialPersonalizationFinishButton => '完成';

  @override
  String get deleteAccountDialogTitle => '注销账户';

  @override
  String get deleteAccountDialogContent => '您确定要永久注销您的账户吗？此操作无法撤销。';

  @override
  String get deleteAccountDialogConfirm => '注销账户';

  @override
  String get deleteAccountButton => '注销账户';

  @override
  String get followedContentEmpty => '您尚未在此类别中关注任何项目。';

  @override
  String get followedContentEmptySubheadline => '您关注的项目将显示在此处。使用“+”按钮添加更多。';

  @override
  String multiSelectSearchPageSelectionCount(int count, int total) {
    return '$count/$total';
  }

  @override
  String get guestUserDisplayName => '游客';

  @override
  String get accountPageSyncProgressButton => '同步进度';

  @override
  String get applyButtonLabel => '应用';

  @override
  String get commentStatusPending => '审核中';
}
