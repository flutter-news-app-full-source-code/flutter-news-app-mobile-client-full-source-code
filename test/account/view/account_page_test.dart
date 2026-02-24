import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/account_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late AppBloc mockAppBloc;
  late MockNavigatorObserver mockNavigatorObserver;

  final standardUser = User(
    id: 'user1',
    email: 'test@test.com',
    role: UserRole.user,
    tier: AccessTier.standard,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockAppBloc = MockAppBloc();
    mockNavigatorObserver = MockNavigatorObserver();
    registerFallbackValue(
      MaterialPageRoute<dynamic>(builder: (_) => const SizedBox()),
    );
  });

  Widget buildTestWidget(AppState appState) {
    when(() => mockAppBloc.state).thenReturn(appState);

    final router = GoRouter(
      initialLocation: '/account',
      observers: [mockNavigatorObserver],
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountPage(),
        ),
        GoRoute(
          path: '/settings',
          name: Routes.settingsName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/manage-followed-items',
          name: Routes.manageFollowedItemsName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/saved-headlines',
          name: Routes.accountSavedHeadlinesName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/notifications-center',
          name: Routes.notificationsCenterName,
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/account-linking',
          name: Routes.accountLinkingName,
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    return BlocProvider.value(
      value: mockAppBloc,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('AccountPage', () {
    testWidgets('renders user header for standard user', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
          ),
        ),
      );

      expect(find.text(standardUser.email), findsOneWidget);
    });

    testWidgets('dispatches AppLogoutRequested on sign out tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      verify(() => mockAppBloc.add(const AppLogoutRequested())).called(1);
    });

    testWidgets('navigates to settings on settings icon tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      verify(
        () => mockNavigatorObserver.didPush(
          any(
            that: isA<Route<dynamic>>().having(
              (r) => r.settings.name,
              'name',
              Routes.settingsName,
            ),
          ),
          any(),
        ),
      ).called(1);
    });
  });
}
