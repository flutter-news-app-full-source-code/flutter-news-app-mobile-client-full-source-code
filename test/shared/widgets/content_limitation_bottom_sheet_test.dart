import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late AppBloc mockAppBloc;
  late AnalyticsService mockAnalyticsService;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockAppBloc = MockAppBloc();
    mockAnalyticsService = MockAnalyticsService();
    mockNavigatorObserver = MockNavigatorObserver();
    registerFallbackValue(
      MaterialPageRoute<dynamic>(builder: (_) => const SizedBox()),
    );
    registerFallbackValue(AnalyticsEvent.limitExceededCtaClicked);
    registerFallbackValue(
      const LimitExceededCtaClickedPayload(ctaType: 'test'),
    );
    when(
      () =>
          mockAnalyticsService.logEvent(any(), payload: any(named: 'payload')),
    ).thenAnswer((_) async {});
  });

  Widget buildTestWidget({
    required LimitationStatus status,
    required AccessTier userTier,
  }) {
    final user = User(
      id: 'test-user',
      email: 'test@example.com',
      role: UserRole.user,
      tier: userTier,
      createdAt: DateTime.now(),
      isAnonymous: userTier == AccessTier.guest,
    );

    when(() => mockAppBloc.state).thenReturn(
      AppState(status: AppLifeCycleStatus.authenticated, user: user),
    );

    final router = GoRouter(
      observers: [mockNavigatorObserver],
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => showContentLimitationBottomSheet(
                      context: context,
                      status: status,
                      action: ContentAction.postComment,
                    ),
                    child: const Text('Show Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
        GoRoute(
          path: '/account-linking',
          name: Routes.accountLinkingName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/paywall',
          name: Routes.paywallName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/manage-followed-items',
          name: Routes.manageFollowedItemsName,
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: mockAnalyticsService)],
      child: BlocProvider.value(
        value: mockAppBloc,
        child: MaterialApp.router(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...UiKitLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  group('ContentLimitationBottomSheet', () {
    testWidgets('shows correct content for anonymous users '
        'and navigates to account linking on tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          status: LimitationStatus.anonymousLimitReached,
          userTier: AccessTier.guest,
        ),
      );

      // Show the bottom sheet
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify content
      expect(find.text('Account Required'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify navigation
      verify(
        () => mockNavigatorObserver.didPush(
          any(
            that: isA<Route<dynamic>>().having(
              (r) => r.settings.name,
              'name',
              Routes.accountLinkingName,
            ),
          ),
          any(),
        ),
      ).called(1);

      // Verify analytics event
      verify(
        () => mockAnalyticsService.logEvent(
          AnalyticsEvent.limitExceededCtaClicked,
          payload: any(
            named: 'payload',
            that: isA<LimitExceededCtaClickedPayload>(),
          ),
        ),
      ).called(1);
    });

    testWidgets('shows correct content for standard users '
        'and navigates to paywall on tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          status: LimitationStatus.standardUserLimitReached,
          userTier: AccessTier.standard,
        ),
      );

      // Show the bottom sheet
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify content
      expect(find.text('Limit Reached'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();

      // Verify navigation
      verify(
        () => mockNavigatorObserver.didPush(
          any(
            that: isA<Route<dynamic>>().having(
              (r) => r.settings.name,
              'name',
              Routes.paywallName,
            ),
          ),
          any(),
        ),
      ).called(1);
    });
  });
}
