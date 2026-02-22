import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/models/cached_feed.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockHeadlinesRepository extends Mock
    implements DataRepository<Headline> {}

class MockEngagementRepository extends Mock
    implements DataRepository<Engagement> {}

class MockFeedDecoratorService extends Mock implements FeedDecoratorService {}

class MockAdService extends Mock implements AdService {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockInlineAdCacheService extends Mock implements InlineAdCacheService {}

class MockFeedCacheService extends Mock implements FeedCacheService {}

class MockContentLimitationService extends Mock
    implements ContentLimitationService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeFeedItem extends Fake implements FeedItem {}

class FakeHeadlineFilterUsedPayload extends Fake
    implements HeadlineFilterUsedPayload {}

class FakeReactionCreatedPayload extends Fake
    implements ReactionCreatedPayload {}

class FakeCommentCreatedPayload extends Fake implements CommentCreatedPayload {}

class FakeRemoteConfig extends Fake implements RemoteConfig {}

class FakeUserRewards extends Fake implements UserRewards {}

class FakeAdThemeStyle extends Fake implements AdThemeStyle {}

class FakePaginationOptions extends Fake implements PaginationOptions {}

class FakeUser extends Fake implements User {}

class FakeCachedFeed extends Fake implements CachedFeed {}

class FakeEngagement extends Fake implements Engagement {}

const _adThemeStyle = AdThemeStyle(
  primaryTextColor: Colors.black,
  secondaryTextColor: Colors.grey,
  tertiaryTextColor: Colors.grey,
  primaryTextSize: 16,
  secondaryTextSize: 14,
  tertiaryTextSize: 12,
  callToActionTextSize: 14,
  callToActionTextColor: Colors.white,
  callToActionBackgroundColor: Colors.blue,
  primaryBackgroundColor: Colors.white,
  secondaryBackgroundColor: Colors.white,
  tertiaryBackgroundColor: Colors.white,
  mainBackgroundColor: Colors.white,
  cornerRadius: 8,
);

void main() {
  late HeadlinesFeedBloc headlinesFeedBloc;
  late MockHeadlinesRepository mockHeadlinesRepository;
  late MockEngagementRepository mockEngagementRepository;
  late MockFeedDecoratorService mockFeedDecoratorService;
  late MockAdService mockAdService;
  late MockAppBloc mockAppBloc;
  late MockInlineAdCacheService mockInlineAdCacheService;
  late MockFeedCacheService mockFeedCacheService;
  late MockContentLimitationService mockContentLimitationService;
  late MockAnalyticsService mockAnalyticsService;

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

  final headlines = [headline1];
  final paginatedResponse = PaginatedResponse(
    items: headlines,
    cursor: 'next',
    hasMore: true,
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
        savedSourceFilters: {},
        commentsPerDay: {},
        reactionsPerDay: {},
        reportsPerDay: {},
      ),
    ),
  );

  final appSettings = AppSettings(
    id: user.id,
    language: Language(
      id: 'en',
      code: 'en',
      name: 'English',
      nativeName: 'English',
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
      status: ContentStatus.active,
    ),
    displaySettings: const DisplaySettings(
      baseTheme: AppBaseTheme.light,
      accentTheme: AppAccentTheme.defaultBlue,
      fontFamily: 'system',
      textScaleFactor: AppTextScaleFactor.medium,
      fontWeight: AppFontWeight.regular,
    ),
    feedSettings: const FeedSettings(
      feedItemDensity: FeedItemDensity.standard,
      feedItemImageStyle: FeedItemImageStyle.largeThumbnail,
      feedItemClickBehavior: FeedItemClickBehavior.internalNavigation,
    ),
  );

  setUpAll(() {
    registerFallbackValue(FakeFeedItem());
    registerFallbackValue(FakeHeadlineFilterUsedPayload());
    registerFallbackValue(AnalyticsEvent.headlineFilterUsed);
    registerFallbackValue(FakeReactionCreatedPayload());
    registerFallbackValue(AnalyticsEvent.reactionCreated);
    registerFallbackValue(FakeCommentCreatedPayload());
    registerFallbackValue(AnalyticsEvent.commentCreated);
    registerFallbackValue(BuildContextFake());
    registerFallbackValue(FakeRemoteConfig());
    registerFallbackValue(FakeUserRewards());
    registerFallbackValue(FakeAdThemeStyle());
    registerFallbackValue(FakePaginationOptions());
    registerFallbackValue(FakeUser());
    registerFallbackValue(FeedItemImageStyle.smallThumbnail);
    registerFallbackValue(<FeedItem>[]);
    registerFallbackValue(FakeCachedFeed());
    registerFallbackValue(ContentAction.reactToContent);
    registerFallbackValue(FakeEngagement());
  });

  setUp(() {
    mockHeadlinesRepository = MockHeadlinesRepository();
    mockEngagementRepository = MockEngagementRepository();
    mockFeedDecoratorService = MockFeedDecoratorService();
    mockAdService = MockAdService();
    mockAppBloc = MockAppBloc();
    mockInlineAdCacheService = MockInlineAdCacheService();
    mockFeedCacheService = MockFeedCacheService();
    mockContentLimitationService = MockContentLimitationService();
    mockAnalyticsService = MockAnalyticsService();

    when(() => mockAppBloc.state).thenReturn(
      AppState(
        status: AppLifeCycleStatus.authenticated,
        user: user,
        remoteConfig: remoteConfig,
        settings: appSettings,
        userContentPreferences: const UserContentPreferences(
          id: 'prefs',
          followedCountries: [],
          followedSources: [],
          followedTopics: [],
          savedHeadlines: [],
          savedHeadlineFilters: [],
          savedSourceFilters: [],
        ),
      ),
    );
    when(() => mockAppBloc.stream).thenAnswer((_) => const Stream.empty());

    when(
      () => mockFeedDecoratorService.decorateFeed(
        feedItems: any(named: 'feedItems'),
        remoteConfig: any(named: 'remoteConfig'),
      ),
    ).thenAnswer(
      (invocation) => invocation.namedArguments[#feedItems] as List<FeedItem>,
    );

    when(
      () => mockAdService.injectFeedAdPlaceholders(
        feedItems: any(named: 'feedItems'),
        user: any(named: 'user'),
        userRewards: any(named: 'userRewards'),
        remoteConfig: any(named: 'remoteConfig'),
        imageStyle: any(named: 'imageStyle'),
        adThemeStyle: any(named: 'adThemeStyle'),
        processedContentItemCount: any(named: 'processedContentItemCount'),
      ),
    ).thenAnswer(
      (invocation) async =>
          invocation.namedArguments[#feedItems] as List<FeedItem>,
    );

    when(() => mockFeedCacheService.getFeed(any())).thenReturn(null);
    when(() => mockFeedCacheService.setFeed(any(), any())).thenAnswer((_) {});
    when(
      () => mockFeedCacheService.updateFeed(any(), any()),
    ).thenAnswer((_) {});
    when(
      () => mockInlineAdCacheService.clearAdsForContext(
        contextKey: any(named: 'contextKey'),
      ),
    ).thenAnswer((_) {});
    when(
      () => mockEngagementRepository.readAll(filter: any(named: 'filter')),
    ).thenAnswer(
      (_) async =>
          const PaginatedResponse(items: [], cursor: null, hasMore: false),
    );
    when(
      () => mockContentLimitationService.checkAction(any()),
    ).thenAnswer((_) async => LimitationStatus.allowed);
    when(
      () =>
          mockAnalyticsService.logEvent(any(), payload: any(named: 'payload')),
    ).thenAnswer((_) async {});

    headlinesFeedBloc = HeadlinesFeedBloc(
      headlinesRepository: mockHeadlinesRepository,
      feedDecoratorService: mockFeedDecoratorService,
      engagementRepository: mockEngagementRepository,
      adService: mockAdService,
      appBloc: mockAppBloc,
      inlineAdCacheService: mockInlineAdCacheService,
      feedCacheService: mockFeedCacheService,
      contentLimitationService: mockContentLimitationService,
      analyticsService: mockAnalyticsService,
    );
  });

  tearDown(() {
    headlinesFeedBloc.close();
  });

  group('HeadlinesFeedBloc', () {
    test('initial state is correct', () {
      expect(headlinesFeedBloc.state, const HeadlinesFeedState());
    });

    blocTest<HeadlinesFeedBloc, HeadlinesFeedState>(
      'emits [loading, success] on refresh when cache is empty',
      setUp: () {
        when(
          () => mockHeadlinesRepository.readAll(
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => paginatedResponse);
      },
      build: () => headlinesFeedBloc,
      act: (bloc) => bloc.add(
        const HeadlinesFeedRefreshRequested(adThemeStyle: _adThemeStyle),
      ),
      expect: () => <HeadlinesFeedState>[
        const HeadlinesFeedState(
          status: HeadlinesFeedStatus.loading,
          adThemeStyle: _adThemeStyle,
        ),
        HeadlinesFeedState(
          status: HeadlinesFeedStatus.success,
          feedItems: headlines,
          hasMore: true,
          cursor: 'next',
          adThemeStyle: _adThemeStyle,
        ),
      ],
      verify: (_) {
        verify(
          () => mockHeadlinesRepository.readAll(
            filter: any(named: 'filter'),
            pagination: const PaginationOptions(limit: 10),
            sort: any(named: 'sort'),
          ),
        ).called(1);
        verify(() => mockFeedCacheService.setFeed(any(), any())).called(1);
      },
    );

    blocTest<HeadlinesFeedBloc, HeadlinesFeedState>(
      'emits [success] with cached items on filter apply with cache hit',
      setUp: () {
        final cachedFeed = CachedFeed(
          feedItems: headlines,
          hasMore: true,
          cursor: 'next',
          lastRefreshedAt: DateTime.now(),
        );
        when(() => mockFeedCacheService.getFeed(any())).thenReturn(cachedFeed);
      },
      build: () => headlinesFeedBloc,
      act: (bloc) => bloc.add(
        const HeadlinesFeedFiltersApplied(
          filter: HeadlineFilterCriteria(
            topics: [],
            sources: [],
            countries: [],
          ),
          adThemeStyle: _adThemeStyle,
        ),
      ),
      expect: () => <HeadlinesFeedState>[
        HeadlinesFeedState(
          status: HeadlinesFeedStatus.success,
          feedItems: headlines,
          hasMore: true,
          cursor: 'next',
          activeFilterId: 'custom',
          adThemeStyle: _adThemeStyle,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockHeadlinesRepository.readAll());
      },
    );

    blocTest<HeadlinesFeedBloc, HeadlinesFeedState>(
      'emits [loadingMore, success] on fetch more',
      setUp: () {
        final initialFeed = CachedFeed(
          feedItems: headlines,
          hasMore: true,
          cursor: 'first-cursor',
          lastRefreshedAt: DateTime.now(),
        );
        when(() => mockFeedCacheService.getFeed(any())).thenReturn(initialFeed);
        when(
          () => mockHeadlinesRepository.readAll(
            filter: any(named: 'filter'),
            pagination: any(
              named: 'pagination',
              that: isA<PaginationOptions>(),
            ),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => PaginatedResponse(
            items: [headline1.copyWith(id: 'h2')],
            cursor: 'last-cursor',
            hasMore: false,
          ),
        );
      },
      build: () => headlinesFeedBloc,
      seed: () => HeadlinesFeedState(
        status: HeadlinesFeedStatus.success,
        feedItems: headlines,
        hasMore: true,
        cursor: 'first-cursor',
        activeFilterId: 'all',
      ),
      act: (bloc) => bloc.add(
        const HeadlinesFeedFetchRequested(adThemeStyle: _adThemeStyle),
      ),
      expect: () => <HeadlinesFeedState>[
        HeadlinesFeedState(
          status: HeadlinesFeedStatus.loadingMore,
          feedItems: headlines,
          hasMore: true,
          cursor: 'first-cursor',
          activeFilterId: 'all',
        ),
        HeadlinesFeedState(
          status: HeadlinesFeedStatus.success,
          feedItems: [
            headline1,
            headline1.copyWith(id: 'h2'),
          ],
          hasMore: false,
          cursor: 'last-cursor',
          activeFilterId: 'all',
          engagementsMap: const {},
        ),
      ],
      verify: (_) {
        verify(
          () => mockHeadlinesRepository.readAll(
            pagination: const PaginationOptions(
              limit: 10,
              cursor: 'first-cursor',
            ),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).called(1);
        verify(() => mockFeedCacheService.updateFeed(any(), any())).called(1);
      },
    );

    blocTest<HeadlinesFeedBloc, HeadlinesFeedState>(
      'emits limitationStatus when reaction is denied',
      setUp: () {
        when(
          () => mockContentLimitationService.checkAction(any()),
        ).thenAnswer((_) async => LimitationStatus.anonymousLimitReached);
      },
      build: () => headlinesFeedBloc,
      act: (bloc) => bloc.add(
        HeadlinesFeedReactionUpdated(
          'h1',
          ReactionType.like,
          context: BuildContextFake(),
        ),
      ),
      expect: () => const <HeadlinesFeedState>[
        HeadlinesFeedState(
          limitationStatus: LimitationStatus.anonymousLimitReached,
          limitedAction: ContentAction.reactToContent,
        ),
        HeadlinesFeedState(
          limitationStatus: LimitationStatus.allowed,
          limitedAction: null,
        ),
      ],
    );

    blocTest<HeadlinesFeedBloc, HeadlinesFeedState>(
      'optimistically updates UI on successful reaction',
      setUp: () {
        when(
          () => mockContentLimitationService.checkAction(any()),
        ).thenAnswer((_) async => LimitationStatus.allowed);
        when(
          () => mockEngagementRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer(
          (_) async => Engagement(
            id: 'e1',
            userId: 'user-id',
            entityId: 'h1',
            entityType: EngageableType.headline,
            reaction: const Reaction(reactionType: ReactionType.like),
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        );
      },
      build: () => headlinesFeedBloc,
      act: (bloc) => bloc.add(
        HeadlinesFeedReactionUpdated(
          'h1',
          ReactionType.like,
          context: BuildContextFake(),
        ),
      ),
      expect: () => [
        isA<HeadlinesFeedState>().having(
          (s) => s.engagementsMap['h1']?.first.reaction?.reactionType,
          'reactionType',
          ReactionType.like,
        ),
      ],
      verify: (_) {
        verify(
          () => mockEngagementRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        ).called(1);
      },
    );

    blocTest<HeadlinesFeedBloc, HeadlinesFeedState>(
      'rolls back UI and shows limitation sheet on ForbiddenException',
      setUp: () {
        // Allow the client-side check to pass
        when(
          () => mockContentLimitationService.checkAction(any()),
        ).thenAnswer((_) async => LimitationStatus.allowed);

        // Make the repository throw a server-side limit exception
        when(
          () => mockEngagementRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        ).thenThrow(const ForbiddenException('Limit reached'));

        when(
          () => mockContentLimitationService.invalidateAndForceRefresh(),
        ).thenAnswer((_) {});
      },
      build: () => headlinesFeedBloc,
      act: (bloc) => bloc.add(
        HeadlinesFeedReactionUpdated(
          'h1',
          ReactionType.like,
          context: BuildContextFake(),
        ),
      ),
      expect: () => <dynamic>[
        // 1. Optimistic UI update (this happens internally before the await)
        isA<HeadlinesFeedState>().having(
          (s) => s.engagementsMap['h1']?.first.reaction?.reactionType,
          'reactionType',
          ReactionType.like,
        ),
        // 2. Rollback to original state (empty list for h1)
        isA<HeadlinesFeedState>().having(
          (s) => s.engagementsMap['h1'],
          'engagements for h1',
          isEmpty,
        ),
        // 3. Show limitation sheet
        isA<HeadlinesFeedState>().having(
          (s) => s.limitationStatus,
          'limitationStatus',
          LimitationStatus.standardUserLimitReached,
        ),
        // 4. Clear limitation state (back to allowed)
        isA<HeadlinesFeedState>().having(
          (s) => s.limitationStatus,
          'limitationStatus',
          LimitationStatus.allowed,
        ),
      ],
      verify: (_) {
        verify(
          () => mockContentLimitationService.invalidateAndForceRefresh(),
        ).called(1);
      },
    );
  });
}

class BuildContextFake extends Fake implements BuildContext {}
