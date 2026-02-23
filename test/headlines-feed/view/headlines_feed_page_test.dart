import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/view/headlines_feed_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

class MockHeadlinesFeedBloc
    extends MockBloc<HeadlinesFeedEvent, HeadlinesFeedState>
    implements HeadlinesFeedBloc {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

void main() {
  late HeadlinesFeedBloc headlinesFeedBloc;
  late AppBloc appBloc;

  final user = User(
    id: 'user-id',
    email: 'test@test.com',
    role: UserRole.user,
    tier: AccessTier.standard,
    createdAt: DateTime.now(),
  );

  final headline1 = Headline(
    id: 'h1',
    title: 'Title 1',
    url: 'url1',
    imageUrl: 'imageUrl1',
    source: Source(
      id: 's1',
      name: 'Source 1',
      description: '',
      url: '',
      logoUrl: '',
      sourceType: SourceType.newsAgency,
      language: Language(
        id: 'en',
        code: 'en',
        name: 'English',
        nativeName: 'English',
        createdAt: DateTime(2023),
        updatedAt: DateTime(2023),
        status: ContentStatus.active,
      ),
      headquarters: Country(
        isoCode: 'US',
        name: 'USA',
        flagUrl: 'f',
        id: 'c',
        createdAt: DateTime(2023),
        updatedAt: DateTime(2023),
        status: ContentStatus.active,
      ),
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
      status: ContentStatus.active,
    ),
    eventCountry: Country(
      isoCode: 'US',
      name: 'USA',
      flagUrl: 'f',
      id: 'c',
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
      status: ContentStatus.active,
    ),
    topic: Topic(
      id: 't1',
      name: 'Topic 1',
      description: '',
      iconUrl: '',
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
      status: ContentStatus.active,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: ContentStatus.active,
    isBreaking: false,
  );

  final remoteConfig = RemoteConfig(
    id: 'config',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    app: const AppConfig(
      maintenance: MaintenanceConfig(isUnderMaintenance: false),
      update: UpdateConfig(
        latestAppVersion: '1.0.0',
        isLatestVersionOnly: false,
        iosUpdateUrl: '',
        androidUpdateUrl: '',
      ),
      general: GeneralAppConfig(termsOfServiceUrl: '', privacyPolicyUrl: ''),
    ),
    features: const FeaturesConfig(
      onboarding: OnboardingConfig(
        isEnabled: true,
        appTour: AppTourConfig(isEnabled: true, isSkippable: true),
        initialPersonalization: InitialPersonalizationConfig(
          isEnabled: true,
          isSkippable: true,
          isCountrySelectionEnabled: true,
          isTopicSelectionEnabled: true,
          isSourceSelectionEnabled: true,
        ),
      ),
      analytics: AnalyticsConfig(
        enabled: true,
        activeProvider: AnalyticsProviders.firebase,
        disabledEvents: {},
        eventSamplingRates: {},
      ),
      ads: AdConfig(
        enabled: false,
        primaryAdPlatform: AdPlatformType.admob,
        platformAdIdentifiers: {},
        feedAdConfiguration: FeedAdConfiguration(
          enabled: false,
          adType: AdType.native,
          visibleTo: {},
        ),
        navigationAdConfiguration: NavigationAdConfiguration(
          enabled: false,
          visibleTo: {},
        ),
      ),
      pushNotifications: PushNotificationConfig(
        enabled: false,
        primaryProvider: PushNotificationProviders.firebase,
        deliveryConfigs: {},
      ),
      feed: FeedConfig(
        itemClickBehavior: FeedItemClickBehavior.defaultBehavior,
        decorators: {},
      ),
      community: CommunityConfig(
        enabled: true,
        engagement: EngagementConfig(
          enabled: true,
          engagementMode: EngagementMode.reactionsAndComments,
        ),
        reporting: ReportingConfig(
          headlineReportingEnabled: true,
          sourceReportingEnabled: true,
          commentReportingEnabled: true,
          enabled: true,
        ),
        appReview: AppReviewConfig(
          enabled: false,
          interactionCycleThreshold: 10,
          initialPromptCooldownDays: 30,
          eligiblePositiveInteractions: [],
          isNegativeFeedbackFollowUpEnabled: false,
          isPositiveFeedbackFollowUpEnabled: false,
        ),
      ),
      rewards: RewardsConfig(enabled: true, rewards: {}),
    ),
    user: const UserConfig(
      limits: UserLimitsConfig(
        followedItems: {},
        savedHeadlines: {},
        savedHeadlineFilters: {},
        commentsPerDay: {},
        reactionsPerDay: {},
        reportsPerDay: {},
      ),
    ),
  );

  setUpAll(() {
    registerFallbackValue(NavigationHandled());
  });

  setUp(() {
    headlinesFeedBloc = MockHeadlinesFeedBloc();
    appBloc = MockAppBloc();

    when(() => appBloc.state).thenReturn(
      AppState(
        status: AppLifeCycleStatus.authenticated,
        user: user,
        remoteConfig: remoteConfig,
        userContentPreferences: const UserContentPreferences(
          id: 'prefs',
          followedCountries: [],
          followedSources: [],
          followedTopics: [],
          savedHeadlines: [],
          savedHeadlineFilters: [],
        ),
        settings: AppSettings(
          id: 'settings-id',
          language: Language(
            id: 'l-id',
            code: 'en',
            name: 'English',
            nativeName: 'English',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            status: ContentStatus.active,
          ),
          displaySettings: const DisplaySettings(
            baseTheme: AppBaseTheme.light,
            accentTheme: AppAccentTheme.defaultBlue,
            fontFamily: 'Roboto',
            textScaleFactor: AppTextScaleFactor.medium,
            fontWeight: AppFontWeight.regular,
          ),
          feedSettings: const FeedSettings(
            feedItemDensity: FeedItemDensity.standard,
            feedItemImageStyle: FeedItemImageStyle.smallThumbnail,
            feedItemClickBehavior: FeedItemClickBehavior.internalNavigation,
          ),
        ),
      ),
    );

    when(() => headlinesFeedBloc.stream).thenAnswer(
      (_) => Stream.value(
        const HeadlinesFeedState(status: HeadlinesFeedStatus.initial),
      ),
    );
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: headlinesFeedBloc),
        BlocProvider.value(value: appBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...UiKitLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HeadlinesFeedPage(),
      ),
    );
  }

  group('HeadlinesFeedPage', () {
    testWidgets(
      'renders loading indicator when status is loading and feed is empty',
      (tester) async {
        when(() => headlinesFeedBloc.state).thenReturn(
          const HeadlinesFeedState(
            status: HeadlinesFeedStatus.loading,
            feedItems: [],
          ),
        );
        await tester.pumpWidget(buildTestWidget());
        expect(find.byType(LoadingStateWidget), findsOneWidget);
      },
    );

    testWidgets('renders error widget when status is failure', (tester) async {
      when(() => headlinesFeedBloc.state).thenReturn(
        const HeadlinesFeedState(
          status: HeadlinesFeedStatus.failure,
          feedItems: [],
        ),
      );
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(FailureStateWidget), findsOneWidget);
    });

    testWidgets('renders feed items when status is success', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      addTearDown(tester.view.resetPhysicalSize);

      final headlines = List.generate(5, (index) => headline1);
      when(() => headlinesFeedBloc.state).thenReturn(
        HeadlinesFeedState(
          status: HeadlinesFeedStatus.success,
          feedItems: headlines,
        ),
      );
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(CustomScrollView), findsOneWidget); // This is fine
      // Make this finder more specific to the main feed list
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SliverList &&
              widget.delegate is SliverChildBuilderDelegate,
        ),
        findsOneWidget,
      );
      expect(find.text(headline1.title, skipOffstage: false), findsNWidgets(5));
    });

    testWidgets('adds HeadlinesFeedFetchRequested when scrolled to bottom', (
      tester,
    ) async {
      when(() => headlinesFeedBloc.state).thenReturn(
        HeadlinesFeedState(
          status: HeadlinesFeedStatus.success,
          feedItems: List.generate(10, (index) => headline1),
          hasMore: true,
        ),
      );
      await tester.pumpWidget(buildTestWidget());
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pump();
      verify(() => headlinesFeedBloc.add(any())).called(1);
    });
  });
}
