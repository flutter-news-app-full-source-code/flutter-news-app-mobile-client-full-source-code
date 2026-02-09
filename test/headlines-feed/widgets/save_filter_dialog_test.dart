import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/widgets/save_filter_dialog.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockContentLimitationService extends Mock
    implements ContentLimitationService {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockLogger extends Mock implements Logger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeAnalyticsEventPayload extends Fake implements AnalyticsEventPayload {}

void main() {
  group('SaveFilterDialog', () {
    late AppBloc appBloc;
    late ContentLimitationService contentLimitationService;
    late PushNotificationService pushNotificationService;
    late Logger logger;
    late AnalyticsService analyticsService;

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
          enabled: true,
          primaryProvider: PushNotificationProviders.firebase,
          deliveryConfigs: {
            PushNotificationSubscriptionDeliveryType.breakingOnly: true,
            PushNotificationSubscriptionDeliveryType.dailyDigest: true,
          },
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

    setUp(() {
      appBloc = MockAppBloc();
      contentLimitationService = MockContentLimitationService();
      pushNotificationService = MockPushNotificationService();
      logger = MockLogger();
      analyticsService = MockAnalyticsService();

      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          remoteConfig: remoteConfig,
        ),
      );

      when(
        () => contentLimitationService.checkAction(
          any(),
          deliveryType: any(named: 'deliveryType'),
        ),
      ).thenAnswer((_) async => LimitationStatus.allowed);

      // Stub checkAction for calls without named arguments (e.g., saveFilter)
      when(
        () => contentLimitationService.checkAction(any()),
      ).thenAnswer((_) async => LimitationStatus.allowed);

      when(
        () => pushNotificationService.hasPermission(),
      ).thenAnswer((_) async => true);

      when(() => logger.fine(any())).thenAnswer((_) {});
      when(() => logger.info(any())).thenAnswer((_) {});
      when(() => logger.warning(any())).thenAnswer((_) {});
      when(() => logger.severe(any(), any(), any())).thenAnswer((_) {});

      when(
        () => analyticsService.logEvent(any(), payload: any(named: 'payload')),
      ).thenAnswer((_) async {});
    });

    setUpAll(() {
      registerFallbackValue(ContentAction.saveFilter);
      registerFallbackValue(AnalyticsEvent.userRegistered);
      registerFallbackValue(FakeAnalyticsEventPayload());
    });

    Widget buildWidget({
      required ValueChanged<
        ({
          String name,
          bool isPinned,
          Set<PushNotificationSubscriptionDeliveryType> deliveryTypes,
        })
      >
      onSave,
      SavedHeadlineFilter? filterToEdit,
    }) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: contentLimitationService),
          RepositoryProvider.value(value: pushNotificationService),
          RepositoryProvider.value(value: logger),
          RepositoryProvider.value(value: analyticsService),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: appBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => MultiRepositoryProvider(
                        providers: [
                          RepositoryProvider.value(
                            value: contentLimitationService,
                          ),
                          RepositoryProvider.value(
                            value: pushNotificationService,
                          ),
                          RepositoryProvider.value(value: logger),
                          RepositoryProvider.value(value: analyticsService),
                        ],
                        child: BlocProvider.value(
                          value: appBloc,
                          child: SaveFilterDialog(
                            onSave: onSave,
                            filterToEdit: filterToEdit,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders correctly in create mode', (tester) async {
      await tester.pumpWidget(buildWidget(onSave: (_) {}));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Save Filter'), findsOneWidget);
      expect(find.text('Filter Name'), findsOneWidget);
      expect(find.text('Pin to Filter Bar'), findsOneWidget);
      expect(find.text('Breaking News'), findsOneWidget);
    });

    testWidgets('validates empty name and calls onSave on success', (
      tester,
    ) async {
      String? savedName;
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        buildWidget(onSave: (result) => savedName = result.name),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to save with empty name
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.saveFilterDialogValidationEmpty), findsOneWidget);
      expect(savedName, isNull);

      // Enter a valid name and save
      await tester.enterText(find.byType(TextFormField), 'My Test Filter');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedName, 'My Test Filter');
    });

    testWidgets('shows limit reached bottom sheet when saving is denied', (
      tester,
    ) async {
      when(
        () => contentLimitationService.checkAction(ContentAction.saveFilter),
      ).thenAnswer((_) async => LimitationStatus.standardUserLimitReached);

      await tester.pumpWidget(buildWidget(onSave: (_) {}));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'New Filter');
      await tester.tap(find.text('Save'));
      // Manually pump to allow the un-awaited showContentLimitationBottomSheet to start.
      await tester.pump();
      await tester.pumpAndSettle(); // Now settle the animation.

      expect(find.byType(ContentLimitationBottomSheet), findsOneWidget);
    });

    testWidgets('handles notification permission flow correctly', (
      tester,
    ) async {
      when(
        () => pushNotificationService.hasPermission(),
      ).thenAnswer((_) async => false);
      when(
        () => pushNotificationService.requestPermission(),
      ).thenAnswer((_) async => true);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(buildWidget(onSave: (_) {}));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Select a notification type
      await tester.tap(find.text('Breaking News'));
      await tester.pumpAndSettle();

      // Save, which should trigger the pre-permission dialog
      await tester.enterText(find.byType(TextFormField), 'Notify Me');
      await tester.tap(find.text('Save'));
      // Use manual pumps to avoid timeout from the CircularProgressIndicator
      await tester.pump();
      await tester.pump();

      // Verify pre-permission dialog is shown
      expect(find.text(l10n.prePermissionDialogTitle), findsOneWidget);

      // Tap 'Allow'
      await tester.tap(find.text(l10n.prePermissionDialogAllowButton));
      await tester.pumpAndSettle();

      // Verify OS permission was requested
      verify(() => pushNotificationService.requestPermission()).called(1);
    });
  });
}
