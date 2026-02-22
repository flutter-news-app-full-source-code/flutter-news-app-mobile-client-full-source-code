import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/widgets/feed_sliver_app_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/widgets/saved_filters_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/notification_indicator.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/user_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockHeadlinesRepository extends Mock
    implements DataRepository<Headline> {}

class MockHeadlinesFeedBloc
    extends MockBloc<HeadlinesFeedEvent, HeadlinesFeedState>
    implements HeadlinesFeedBloc {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('FeedSliverAppBar', () {
    late AppBloc appBloc;
    late DataRepository<Headline> headlinesRepository;
    late AnalyticsService analyticsService;
    late HeadlinesFeedBloc headlinesFeedBloc;

    final user = User(
      id: '1',
      email: 'test@test.com',
      role: UserRole.user,
      tier: AccessTier.standard,
      createdAt: DateTime(2024),
    );

    setUp(() {
      appBloc = MockAppBloc();
      headlinesRepository = MockHeadlinesRepository();
      analyticsService = MockAnalyticsService();
      headlinesFeedBloc = MockHeadlinesFeedBloc();

      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          user: user,
          hasUnreadInAppNotifications: false,
        ),
      );
      when(
        () => headlinesFeedBloc.state,
      ).thenReturn(const HeadlinesFeedState());
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: headlinesRepository),
            RepositoryProvider.value(value: analyticsService),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: appBloc),
              BlocProvider.value(value: headlinesFeedBloc),
            ],
            child: const CustomScrollView(
              slivers: [
                FeedSliverAppBar(
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(52),
                    child: SavedFiltersBar(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('renders search bar and user avatar', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search headlines...'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('tapping search bar shows HeadlineSearchDelegate', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tapping user avatar navigates to account page', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      when(() => mockGoRouter.pushNamed(any())).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );

      await tester.tap(find.byType(UserAvatar));
      await tester.pumpAndSettle();

      verify(() => mockGoRouter.pushNamed(Routes.accountName)).called(1);
    });

    testWidgets('shows notification indicator when state is true', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          user: user,
          hasUnreadInAppNotifications: true,
        ),
      );

      await tester.pumpWidget(buildWidget());

      expect(find.byType(NotificationIndicator), findsOneWidget);
      final indicator = tester.widget<NotificationIndicator>(
        find.byType(NotificationIndicator),
      );
      expect(indicator.showIndicator, isTrue);
    });
  });
}
