// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get accountLinkingPageTitle => 'ربط حسابك';

  @override
  String get accountLinkingGenericError => 'حدث خطأ';

  @override
  String get accountLinkingEmailSentSuccess =>
      'تحقق من بريدك الإلكتروني للحصول على رابط تسجيل الدخول!';

  @override
  String get accountLinkingHeadline => 'أحفظ تقدمك';

  @override
  String get accountLinkingBody =>
      'يتيح لك التسجيل الوصول إلى معلوماتك عبر أجهزة متعددة ويضمن عدم فقدان تقدمك.';

  @override
  String get accountLinkingContinueWithGoogleButton => 'المتابعة باستخدام جوجل';

  @override
  String get accountLinkingEmailInputLabel => 'أدخل بريدك الإلكتروني';

  @override
  String get accountLinkingEmailInputHint => 'you@example.com';

  @override
  String get accountLinkingEmailValidationError =>
      'الرجاء إدخال عنوان بريد إلكتروني صالح';

  @override
  String get accountLinkingSendLinkButton => 'إرسال رابط تسجيل الدخول';

  @override
  String get accountPageTitle => 'الحساب';

  @override
  String get accountAnonymousUser => '(مجهول)';

  @override
  String get accountNoNameUser => 'لا يوجد اسم';

  @override
  String get accountStatusAuthenticated => 'مصادق عليه';

  @override
  String get accountStatusAnonymous => 'جلسة مجهولة';

  @override
  String get accountStatusUnauthenticated => 'لم يتم تسجيل الدخول';

  @override
  String get accountSettingsTile => 'الإعدادات';

  @override
  String get accountSignOutTile => 'تسجيل الخروج';

  @override
  String get accountBackupTile => 'أنشئ حسابًا لحفظ البيانات';

  @override
  String get accountContentPreferencesTile => 'تفضيلات المحتوى';

  @override
  String get accountSavedHeadlinesTile => 'العناوين المحفوظة';

  @override
  String accountRoleLabel(String role) {
    return 'الدور: $role';
  }

  @override
  String get authenticationEmailSentSuccess =>
      'تحقق من بريدك الإلكتروني للحصول على رابط تسجيل الدخول.';

  @override
  String get authenticationPageTitle => 'تسجيل الدخول / التسجيل';

  @override
  String get authenticationEmailLabel => 'البريد الإلكتروني';

  @override
  String get authenticationSendLinkButton => 'إرسال رابط تسجيل الدخول';

  @override
  String get authenticationOrDivider => 'أو';

  @override
  String get authenticationGoogleSignInButton => 'تسجيل الدخول باستخدام جوجل';

  @override
  String get authenticationAnonymousSignInButton => 'المتابعة كمجهول';

  @override
  String get headlineDetailsInitialHeadline => 'في انتظار العنوان';

  @override
  String get headlineDetailsInitialSubheadline => 'يرجى الانتظار...';

  @override
  String get headlineDetailsLoadingHeadline => 'جارٍ تحميل العنوان';

  @override
  String get headlineDetailsLoadingSubheadline => 'جارٍ جلب البيانات...';

  @override
  String get headlineDetailsContinueReadingButton => 'متابعة القراءة';

  @override
  String get headlinesFeedLoadingHeadline => 'جارٍ التحميل...';

  @override
  String get headlinesFeedLoadingSubheadline => 'جارٍ جلب العناوين';

  @override
  String get headlinesFeedFilterTitle => 'تصفية العناوين';

  @override
  String get headlinesFeedFilterCategoryLabel => 'الفئة';

  @override
  String get headlinesFeedFilterAllOption => 'الكل';

  @override
  String get headlinesFeedFilterCategoryTechnology => 'تكنولوجيا';

  @override
  String get headlinesFeedFilterCategoryBusiness => 'أعمال';

  @override
  String get headlinesFeedFilterCategorySports => 'رياضة';

  @override
  String get headlinesFeedFilterSourceLabel => 'المصدر';

  @override
  String get headlinesFeedFilterSourceCNN => 'CNN';

  @override
  String get headlinesFeedFilterSourceReuters => 'Reuters';

  @override
  String get headlinesFeedFilterEventCountryLabel => 'بلد الحدث';

  @override
  String get headlinesFeedFilterSourceCountryLabel => 'مقر المصدر';

  @override
  String get headlinesFeedFilterCountryUS => 'الولايات المتحدة';

  @override
  String get headlinesFeedFilterCountryUK => 'المملكة المتحدة';

  @override
  String get headlinesFeedFilterCountryCA => 'كندا';

  @override
  String get headlinesFeedFilterApplyButton => 'تطبيق الفلاتر';

  @override
  String get headlinesFeedFilterResetButton => 'إعادة تعيين الفلاتر';

  @override
  String get headlinesSearchHintText => 'ابحث في العناوين...';

  @override
  String get headlinesSearchInitialHeadline => 'اعثر على العناوين فوراً';

  @override
  String get headlinesSearchInitialSubheadline =>
      'اكتب كلمات رئيسية أعلاه لاكتشاف المقالات الإخبارية.';

  @override
  String get headlinesSearchNoResultsHeadline => 'لا توجد نتائج';

  @override
  String get headlinesSearchNoResultsSubheadline => 'جرب مصطلح بحث مختلف';

  @override
  String get authenticationEmailSignInButton => 'متابعة بالبريد الإلكتروني';

  @override
  String get authenticationLinkingHeadline => 'زامن بياناتك';

  @override
  String get authenticationLinkingSubheadline =>
      'إحفظ إعداداتك، تفضيلات المحتوى والمزيد عبر مختلف الأجهزة.';

  @override
  String get authenticationSignInHeadline => 'فيريتاس';

  @override
  String get authenticationSignInSubheadline =>
      'أخبار غير مصفاة من مصادر موثوقة حول العالم.';

  @override
  String get emailSignInPageTitle => 'تسجيل الدخول بالبريد الإلكتروني';

  @override
  String get emailSignInExplanation =>
      'أدخل بريدك الإلكتروني أدناه. سنرسل لك رابطًا آمنًا لتسجيل الدخول فورًا. لا حاجة لكلمة مرور!';

  @override
  String get emailLinkSentPageTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get emailLinkSentConfirmation =>
      'تم إرسال الرابط! تحقق من صندوق الوارد في بريدك الإلكتروني (ومجلد الرسائل غير المرغوب فيها) بحثًا عن رسالة منا. انقر على الرابط الموجود بالداخل لإكمال تسجيل الدخول.';

  @override
  String get accountConnectPrompt => 'ربط الحساب';

  @override
  String get accountConnectBenefit => 'لحفظ تفضيلاتك وسجل القراءة عبر الأجهزة.';

  @override
  String get bottomNavFeedLabel => 'الموجز';

  @override
  String get bottomNavSearchLabel => 'بحث';

  @override
  String get bottomNavAccountLabel => 'الحساب';

  @override
  String get accountNotificationsTile => 'الإشعارات';

  @override
  String get headlinesSearchActionTooltip => 'بحث';

  @override
  String get notificationsTooltip => 'عرض الإشعارات';

  @override
  String get accountSignInPromptButton => 'تسجيل / تسجيل الدخول';

  @override
  String get categoryFilterLoadingHeadline => 'جارٍ تحميل الفئات...';

  @override
  String get categoryFilterLoadingSubheadline =>
      'يرجى الانتظار بينما نقوم بجلب الفئات المتاحة.';

  @override
  String get categoryFilterEmptyHeadline => 'لم يتم العثور على فئات';

  @override
  String get categoryFilterEmptySubheadline =>
      'لا توجد فئات متاحة في الوقت الحالي.';

  @override
  String get countryFilterLoadingHeadline => 'جارٍ تحميل البلدان...';

  @override
  String get countryFilterLoadingSubheadline =>
      'يرجى الانتظار بينما نقوم بجلب البلدان المتاحة.';

  @override
  String get countryFilterEmptyHeadline => 'لم يتم العثور على بلدان';

  @override
  String get countryFilterEmptySubheadline =>
      'لا توجد بلدان متاحة في الوقت الحالي.';

  @override
  String get headlinesFeedAppBarTitle => 'HT';

  @override
  String get headlinesFeedFilterTooltip => 'تصفية العناوين';

  @override
  String get headlinesFeedFilterAllLabel => 'الكل';

  @override
  String headlinesFeedFilterSelectedCountLabel(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get sourceFilterLoadingHeadline => 'جارٍ تحميل المصادر...';

  @override
  String get sourceFilterLoadingSubheadline =>
      'يرجى الانتظار بينما نقوم بجلب المصادر المتاحة.';

  @override
  String get sourceFilterEmptyHeadline => 'لم يتم العثور على مصادر';

  @override
  String get sourceFilterEmptySubheadline =>
      'لا توجد مصادر متاحة في الوقت الحالي.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLoadingHeadline => 'جارٍ تحميل الإعدادات...';

  @override
  String get settingsLoadingSubheadline =>
      'يرجى الانتظار بينما نقوم بجلب تفضيلاتك.';

  @override
  String get settingsErrorDefault => 'تعذر تحميل الإعدادات.';

  @override
  String get settingsAppearanceTitle => 'المظهر';

  @override
  String get settingsFeedDisplayTitle => 'عرض الموجز';

  @override
  String get settingsArticleDisplayTitle => 'عرض المقال';

  @override
  String get settingsNotificationsTitle => 'الإشعارات';

  @override
  String get settingsAppearanceThemeModeLight => 'فاتح';

  @override
  String get settingsAppearanceThemeModeDark => 'داكن';

  @override
  String get settingsAppearanceThemeModeSystem => 'النظام';

  @override
  String get settingsAppearanceThemeNameRed => 'أحمر';

  @override
  String get settingsAppearanceThemeNameBlue => 'أزرق';

  @override
  String get settingsAppearanceThemeNameGrey => 'رمادي';

  @override
  String get settingsAppearanceFontSizeSmall => 'صغير';

  @override
  String get settingsAppearanceFontSizeLarge => 'كبير';

  @override
  String get settingsAppearanceFontSizeMedium => 'متوسط';

  @override
  String get settingsAppearanceThemeModeLabel => 'وضع المظهر';

  @override
  String get settingsAppearanceThemeNameLabel => 'نظام الألوان';

  @override
  String get settingsAppearanceAppFontSizeLabel => 'حجم خط التطبيق';

  @override
  String get settingsAppearanceAppFontTypeLabel => 'خط التطبيق';

  @override
  String get settingsAppearanceFontWeightLabel => 'وزن الخط';

  @override
  String get settingsFeedTileTypeImageTop => 'صورة في الأعلى';

  @override
  String get settingsFeedTileTypeImageStart => 'صورة في البداية';

  @override
  String get settingsFeedTileTypeTextOnly => 'نص فقط';

  @override
  String get settingsFeedTileTypeLabel => 'تخطيط عنصر الموجز';

  @override
  String get settingsArticleFontSizeLabel => 'حجم خط المقال';

  @override
  String get settingsNotificationsEnableLabel => 'تفعيل الإشعارات';

  @override
  String get settingsNotificationsCategoriesLabel => 'الفئات المتابعة';

  @override
  String get settingsNotificationsSourcesLabel => 'المصادر المتابعة';

  @override
  String get settingsNotificationsCountriesLabel => 'البلدان المتابعة';

  @override
  String get unknownError => 'حدث خطأ غير معروف.';

  @override
  String get loadMoreError => 'فشل تحميل المزيد من العناصر.';

  @override
  String get settingsAppearanceFontSizeExtraLarge => 'كبير جداً';

  @override
  String get settingsAppearanceFontFamilySystemDefault => 'افتراضي النظام';

  @override
  String get settingsAppearanceThemeSubPageTitle => 'إعدادات المظهر';

  @override
  String get settingsAppearanceFontSubPageTitle => 'إعدادات الخط';

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get emailCodeSentPageTitle => 'أدخل الرمز';

  @override
  String emailCodeSentConfirmation(String email) {
    return 'تم إرسال رمز التحقق إلى $email. يرجى إدخاله أدناه.';
  }

  @override
  String get emailCodeSentInstructions =>
      'أدخل الرمز المكون من 6 أرقام الذي تلقيته.';

  @override
  String get emailCodeVerificationHint => 'رمز مكون من 6 أرقام';

  @override
  String get emailCodeVerificationButtonLabel => 'تحقق من الرمز';

  @override
  String get emailCodeValidationEmptyError =>
      'الرجاء إدخال الرمز المكون من 6 أرقام.';

  @override
  String get emailCodeValidationLengthError => 'يجب أن يتكون الرمز من 6 أرقام.';

  @override
  String get headlinesFeedEmptyFilteredHeadline =>
      'لا توجد عناوين تطابق فلاترك';

  @override
  String get headlinesFeedEmptyFilteredSubheadline =>
      'حاول تعديل معايير الفلترة أو مسحها لرؤية جميع العناوين.';

  @override
  String get headlinesFeedClearFiltersButton => 'مسح الفلاتر';

  @override
  String get headlinesFeedFilterLoadingCriteria =>
      'جارٍ تحميل خيارات التصفية...';

  @override
  String get pleaseWait => 'يرجى الانتظار...';

  @override
  String get headlinesFeedFilterErrorCriteria => 'تعذر تحميل خيارات التصفية.';

  @override
  String get headlinesFeedFilterCountryLabel => 'الدول';

  @override
  String get headlinesFeedFilterSourceTypeLabel => 'الأنواع';

  @override
  String get headlinesFeedFilterErrorSources => 'تعذر تحميل المصادر.';

  @override
  String get headlinesFeedFilterNoSourcesMatch =>
      'لا توجد مصادر تطابق الفلاتر المحددة.';

  @override
  String get searchModelTypeHeadline => 'العناوين الرئيسية';

  @override
  String get searchModelTypeCategory => 'الفئات';

  @override
  String get searchModelTypeSource => 'المصادر';

  @override
  String get searchModelTypeCountry => 'الدول';

  @override
  String get searchHintTextHeadline =>
      'مثال: تطورات الذكاء الاصطناعي, مركبة المريخ...';

  @override
  String get searchHintTextGeneric => 'بحث...';

  @override
  String get searchHintTextCategory => 'مثال: تكنولوجيا, رياضة, مالية...';

  @override
  String get searchHintTextSource => 'مثال: بي بي سي نيوز, تك كرانش, رويترز...';

  @override
  String get searchHintTextCountry =>
      'مثال: الولايات المتحدة, اليابان, البرازيل...';

  @override
  String get searchPageInitialHeadline => 'ابدأ بحثك';

  @override
  String get searchPageInitialSubheadline =>
      'اختر نوعًا وأدخل كلمات رئيسية للبدء.';

  @override
  String get followedCategoriesPageTitle => 'الفئات المتابَعة';

  @override
  String get addCategoriesTooltip => 'إضافة فئات';

  @override
  String get noFollowedCategoriesMessage => 'أنت لا تتابع أي فئات حتى الآن.';

  @override
  String get addCategoriesButtonLabel => 'البحث عن فئات لمتابعتها';

  @override
  String unfollowCategoryTooltip(String categoryName) {
    return 'إلغاء متابعة $categoryName';
  }

  @override
  String get addTopicsPageTitle => 'متابعة المواضيع';

  @override
  String get topicFilterLoadingHeadline => 'جارٍ تحميل المواضيع...';

  @override
  String get topicFilterError => 'تعذر تحميل المواضيع. يرجى المحاولة مرة أخرى.';

  @override
  String get topicFilterEmptyHeadline => 'لم يتم العثور على مواضيع';

  @override
  String get topicFilterEmptySubheadline =>
      'لا توجد مواضيع متاحة في الوقت الحالي.';

  @override
  String unfollowTopicTooltip(String topicName) {
    return 'إلغاء متابعة $topicName';
  }

  @override
  String followTopicTooltip(String topicName) {
    return 'متابعة $topicName';
  }

  @override
  String get followedSourcesLoadingHeadline =>
      'جارٍ تحميل المصادر المتابَعة...';

  @override
  String get followedSourcesErrorHeadline => 'تعذر تحميل المصادر المتابَعة';

  @override
  String get followedSourcesEmptyHeadline => 'لا توجد مصادر متابَعة';

  @override
  String get followedSourcesEmptySubheadline =>
      'ابدأ بمتابعة المصادر لكي تظهر هنا.';

  @override
  String get headlinesFeedFilterTopicLabel => 'الموضوع';

  @override
  String get followedTopicsPageTitle => 'المواضيع المتابَعة';

  @override
  String get addTopicsTooltip => 'إضافة مواضيع';

  @override
  String get followedTopicsLoadingHeadline =>
      'جارٍ تحميل المواضيع المتابَعة...';

  @override
  String get followedTopicsErrorHeadline => 'تعذر تحميل المواضيع المتابَعة';

  @override
  String get followedTopicsEmptyHeadline => 'لا توجد مواضيع متابَعة';

  @override
  String get followedTopicsEmptySubheadline =>
      'ابدأ بمتابعة المواضيع لكي تظهر هنا.';

  @override
  String get followedSourcesPageTitle => 'المصادر المتابَعة';

  @override
  String get addSourcesTooltip => 'إضافة مصادر';

  @override
  String get noFollowedSourcesMessage => 'أنت لا تتابع أي مصادر حتى الآن.';

  @override
  String get addSourcesButtonLabel => 'البحث عن مصادر لمتابعتها';

  @override
  String unfollowSourceTooltip(String sourceName) {
    return 'إلغاء متابعة $sourceName';
  }

  @override
  String get followedCountriesPageTitle => 'الدول المتابَعة';

  @override
  String get addCountriesTooltip => 'إضافة دول';

  @override
  String get noFollowedCountriesMessage => 'أنت لا تتابع أي دول حتى الآن.';

  @override
  String get addCountriesButtonLabel => 'البحث عن دول لمتابعتها';

  @override
  String unfollowCountryTooltip(String countryName) {
    return 'إلغاء متابعة $countryName';
  }

  @override
  String get addCategoriesPageTitle => 'إضافة فئات للمتابعة';

  @override
  String get categoryFilterError =>
      'تعذر تحميل الفئات. يرجى المحاولة مرة أخرى.';

  @override
  String followCategoryTooltip(String categoryName) {
    return 'متابعة $categoryName';
  }

  @override
  String get addSourcesPageTitle => 'إضافة مصادر للمتابعة';

  @override
  String get sourceFilterError => 'تعذر تحميل المصادر. يرجى المحاولة مرة أخرى.';

  @override
  String followSourceTooltip(String sourceName) {
    return 'متابعة $sourceName';
  }

  @override
  String get addCountriesPageTitle => 'إضافة دول للمتابعة';

  @override
  String followCountryTooltip(String countryName) {
    return 'متابعة $countryName';
  }

  @override
  String get headlineDetailsSaveTooltip => 'حفظ العنوان';

  @override
  String get headlineDetailsRemoveFromSavedTooltip => 'إزالة من المحفوظات';

  @override
  String get headlineSavedSuccessSnackbar => 'تم حفظ العنوان!';

  @override
  String get headlineUnsavedSuccessSnackbar =>
      'تمت إزالة العنوان من المحفوظات.';

  @override
  String get headlineSaveErrorSnackbar =>
      'تعذر تحديث حالة الحفظ. يرجى المحاولة مرة أخرى.';

  @override
  String get shareActionTooltip => 'مشاركة العنوان';

  @override
  String get sharingUnavailableSnackbar =>
      'المشاركة غير متاحة على هذا الجهاز أو المنصة.';

  @override
  String get similarHeadlinesSectionTitle => 'قد يعجبك ايضا';

  @override
  String get similarHeadlinesEmpty => 'لم يتم العثور على عناوين مشابهة.';

  @override
  String get detailsPageTitle => 'التفاصيل';

  @override
  String get followButtonLabel => 'متابعة';

  @override
  String get unfollowButtonLabel => 'إلغاء المتابعة';

  @override
  String get noHeadlinesFoundMessage => 'لم يتم العثور على عناوين لهذا العنصر.';

  @override
  String get failedToLoadMoreHeadlines => 'فشل تحميل المزيد من العناوين.';

  @override
  String get headlinesSectionTitle => 'العناوين الرئيسية';

  @override
  String get headlinesFeedFilterApplyFollowedLabel =>
      'تطبيق العناصر التي أتابعها كمرشحات.';

  @override
  String get mustBeLoggedInToUseFeatureError =>
      'يجب عليك تسجيل الدخول لاستخدام هذه الميزة.';

  @override
  String get noFollowedItemsForFilterSnackbar =>
      'أنت لا تتبع أي عناصر لتطبيقها كفلتر.';

  @override
  String get requestCodePageHeadline => 'أدخل بريدك الإلكتروني';

  @override
  String get requestCodePageSubheadline =>
      'سنرسل رمزًا آمنًا إلى بريدك الإلكتروني للتحقق من هويتك.';

  @override
  String get requestCodeEmailLabel => 'عنوان البريد الإلكتروني';

  @override
  String get requestCodeEmailHint => 'you@example.com';

  @override
  String get requestCodeSendCodeButton => 'إرسال الرمز';

  @override
  String requestCodeResendButtonCooldown(int seconds) {
    return 'إعادة الإرسال في $seconds ثانية';
  }

  @override
  String get entityDetailsCategoryTitle => 'الفئة';

  @override
  String get entityDetailsSourceTitle => 'المصدر';

  @override
  String get entityDetailsTopicTitle => 'الموضوع';

  @override
  String get entityDetailsCountryTitle => 'الدولة';

  @override
  String get savedHeadlinesLoadingHeadline => 'جارٍ تحميل العناوين المحفوظة...';

  @override
  String get savedHeadlinesLoadingSubheadline =>
      'يرجى الانتظار بينما نقوم بجلب مقالاتك المحفوظة.';

  @override
  String get savedHeadlinesErrorHeadline => 'تعذر تحميل العناوين المحفوظة';

  @override
  String get savedHeadlinesEmptyHeadline => 'لا توجد عناوين محفوظة';

  @override
  String get savedHeadlinesEmptySubheadline =>
      'لم تقم بحفظ أي مقالات بعد. ابدأ الاستكشاف!';

  @override
  String get accountFollowedCountriesTile => 'الدول المتابَعة';

  @override
  String get followedCountriesLoadingHeadline =>
      'جارٍ تحميل الدول المتابَعة...';

  @override
  String get followedCountriesErrorHeadline => 'تعذر تحميل الدول المتابَعة';

  @override
  String get followedCountriesEmptyHeadline => 'لا توجد دول متابَعة';

  @override
  String get followedCountriesEmptySubheadline =>
      'ابدأ بمتابعة الدول لكي تظهر هنا.';

  @override
  String get countryFilterError => 'تعذر تحميل الدول. يرجى المحاولة مرة أخرى.';

  @override
  String get followedCategoriesLoadingHeadline =>
      'جارٍ تحميل الفئات المتابَعة...';

  @override
  String get followedCategoriesErrorHeadline => 'تعذر تحميل الفئات المتابَعة';

  @override
  String get followedCategoriesEmptyHeadline => 'لا توجد فئات متابَعة';

  @override
  String get followedCategoriesEmptySubheadline =>
      'ابدأ بمتابعة الفئات لكي تظهر هنا.';

  @override
  String demoVerificationCodeMessage(String code) {
    return 'وضع العرض التوضيحي: استخدم الرمز $code';
  }

  @override
  String demoEmailSuggestionMessage(String email) {
    return 'وضع العرض التوضيحي: استخدم البريد الإلكتروني $email';
  }

  @override
  String get contentTypeHeadline => 'العناوين الرئيسية';

  @override
  String get contentTypeTopic => 'المواضيع';

  @override
  String get contentTypeSource => 'المصادر';

  @override
  String get contentTypeCountry => 'الدول';

  @override
  String searchingFor(String contentType) {
    return 'جار البحث عن $contentType...';
  }

  @override
  String get settingsAppearanceFontWeightLight => 'صغير';

  @override
  String get settingsAppearanceFontWeightRegular => 'عادي';

  @override
  String get settingsAppearanceFontWeightBold => 'عريض';

  @override
  String get maintenanceHeadline => 'تحت الصيانة';

  @override
  String get maintenanceSubheadline =>
      'نقوم حاليًا بإجراء صيانة. يرجى التحقق مرة أخرى لاحقًا.';

  @override
  String get updateRequiredHeadline => 'التحديث مطلوب';

  @override
  String get updateRequiredSubheadline =>
      'يتوفر إصدار جديد من التطبيق. يرجى التحديث لمتابعة استخدام التطبيق.';

  @override
  String get updateRequiredButton => 'التحديث الآن';

  @override
  String get neverShowAgain => 'لا تظهر هذا مرة أخرى';

  @override
  String get followButtonText => 'متابعة';

  @override
  String get unfollowButtonText => 'إلغاء المتابعة';

  @override
  String get demoNativeAdText => 'إعلان أصلي (الوضع التجريبي)';

  @override
  String get demoBannerAdText => 'إعلان بانر (الوضع التجريبي)';

  @override
  String get demoInterstitialAdText => 'إعلان بيني (الوضع التجريبي)';

  @override
  String get demoInterstitialAdDescription =>
      'هذا عنصر نائب لإعلان بملء الشاشة.';

  @override
  String get adInfoPlaceholderText =>
      'الإعلانات تساعد في إبقاء هذا التطبيق مجانيًا.';

  @override
  String get retryButtonText => 'إعادة المحاولة';

  @override
  String get headlinesFeedFilterLoadingHeadline => 'جاري تحميل الفلاتر';

  @override
  String get suggestedTopicsTitle => 'مواضيع مقترحة';

  @override
  String get suggestedSourcesTitle => 'مصادر مقترحة';

  @override
  String couldNotOpenUpdateUrl(String url) {
    return 'تعذر فتح رابط التحديث: $url';
  }

  @override
  String currentAppVersionLabel(String version) {
    return 'إصدارك الحالي: $version';
  }

  @override
  String latestRequiredVersionLabel(String version) {
    return 'الإصدار المطلوب: $version';
  }

  @override
  String get anonymousLimitTitle => 'تسجيل الدخول للقيام بالمزيد';

  @override
  String get anonymousLimitBody =>
      'قم بإنشاء حساب مجاني لإضافة المزيد ومتابعة المزيد.';

  @override
  String get anonymousLimitButton => 'تسجيل الدخول';

  @override
  String get standardLimitTitle => 'افتح الوصول غير المحدود';

  @override
  String get standardLimitBody =>
      'لقد وصلت إلى الحد الأقصى للباقة المجانية. قم بالترقية لحفظ ومتابعة المزيد.';

  @override
  String get standardLimitButton => 'الترقية إلى بريميوم';

  @override
  String get premiumLimitTitle => 'لقد وصلت إلى الحد الأقصى';

  @override
  String get premiumLimitBody =>
      'لإضافة عناصر جديدة، يرجى مراجعة وإدارة المحتوى المحفوظ والمتابع الحالي.';

  @override
  String get premiumLimitButton => 'إدارة المحتوى الخاص بي';

  @override
  String get saveButtonLabel => 'حفظ';

  @override
  String get cancelButtonLabel => 'إلغاء';

  @override
  String get manageFiltersPageTitle => 'إدارة الفلاتر';

  @override
  String get manageFiltersEmptyHeadline => 'لا توجد فلاتر محفوظة';

  @override
  String get manageFiltersEmptySubheadline =>
      'يمكنك حفظ الفلاتر من صفحة التصفية.';

  @override
  String get manageFiltersRenameTooltip => 'إعادة تسمية الفلتر';

  @override
  String get manageFiltersDeleteTooltip => 'حذف الفلتر';

  @override
  String get saveFilterDialogTitleSave => 'حفظ الفلتر';

  @override
  String get saveFilterDialogTitleRename => 'إعادة تسمية الفلتر';

  @override
  String get saveFilterDialogInputLabel => 'اسم الفلتر';

  @override
  String get saveFilterDialogValidationEmpty => 'لا يمكن أن يكون الاسم فارغًا';

  @override
  String get saveFilterDialogValidationTooLong => 'الاسم طويل جدًا';

  @override
  String get headlinesFilterSaveTooltip => 'حفظ الفلتر';

  @override
  String get headlinesFilterManageTooltip => 'إدارة الفلاتر';

  @override
  String get savedFiltersBarOpenTooltip => 'فتح الفلاتر';

  @override
  String get savedFiltersBarAllLabel => 'الكل';

  @override
  String get savedFiltersBarCustomLabel => 'مخصص';

  @override
  String get applyFilterDialogTitle => 'تطبيق الفلتر';

  @override
  String get applyFilterDialogContent =>
      'هل تريد تطبيق إعدادات الفلترة هذه لهذه الجلسة فقط، أم حفظها للاستخدام المستقبلي؟';

  @override
  String get applyFilterDialogApplyOnlyButton => 'تطبيق فقط';

  @override
  String get applyFilterDialogApplyAndSaveButton => 'تطبيق وحفظ';

  @override
  String get savedFiltersBarFollowedLabel => 'المتابَعات';

  @override
  String get sourceListFilterPageTitle => 'تصفية المصادر';

  @override
  String get sourceListFilterPageFilterButtonTooltip => 'تصفية قائمة المصادر';

  @override
  String get accountSavedFiltersTile => 'الفلاتر المحفوظة';

  @override
  String get savedFiltersPageTitle => 'الفلاتر المحفوظة';

  @override
  String get savedFiltersEmptyHeadline => 'لا توجد فلاتر محفوظة';

  @override
  String get savedFiltersEmptySubheadline =>
      'الفلاتر التي تحفظها من الموجز ستظهر هنا.';

  @override
  String get savedFiltersMenuRename => 'إعادة تسمية';

  @override
  String get savedFiltersMenuDelete => 'حذف';

  @override
  String get discoverPageTitle => 'اكتشف';

  @override
  String get bottomNavDiscoverLabel => 'اكتشف';

  @override
  String get feedSearchHint => 'ابحث في العناوين...';

  @override
  String get headlineSearchEnterQuery => 'ابحث عن عناوين من آلاف المصادر.';

  @override
  String get headlineSearchEnterQuerySubheadline =>
      'ابحث بالكلمة المفتاحية للعثور على مقالات من آلاف المصادر.';

  @override
  String get headlineSearchNoResults => 'لم يتم العثور على عناوين.';

  @override
  String get headlineSearchNoResultsSubheadline =>
      'لم نتمكن من العثور على أي عناوين تطابق بحثك. يرجى تجربة كلمات مفتاحية مختلفة.';

  @override
  String get accountGuestAccount => 'حساب زائر';

  @override
  String get accountRoleStandard => 'مستخدم عادي';

  @override
  String get accountRolePremium => 'مستخدم مميز';

  @override
  String get deleteConfirmationDialogTitle => 'تأكيد الحذف';

  @override
  String get deleteConfirmationDialogContent =>
      'هل أنت متأكد أنك تريد حذف هذا العنصر؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteConfirmationDialogConfirmButton => 'حذف';

  @override
  String get headlineSearchInitialHeadline => 'ابحث عن العناوين';

  @override
  String get headlineSearchInitialSubheadline =>
      'أدخل كلمات رئيسية للعثور على المقالات.';
}
