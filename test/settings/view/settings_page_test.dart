import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Mocks
class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockGoRouter extends Mock implements GoRouter {}

class FakeAppSettings extends Fake implements AppSettings {}

class FakeAppEvent extends Fake implements AppEvent {}

// Test helper to pump widgets
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    required AppBloc appBloc,
    required GoRouter router,
  }) {
    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InheritedGoRouter(
          goRouter: router,
          child: BlocProvider.value(value: appBloc, child: widget),
        ),
      ),
    );
  }
}

void main() {
  late AppBloc appBloc;
  late GoRouter goRouter;

  // Fixture data
  final language = Language(
    id: 'en-id',
    code: 'en',
    name: 'English',
    nativeName: 'English',
    createdAt: DateTime(2023),
    updatedAt: DateTime(2023),
    status: ContentStatus.active,
  );

  final initialSettings = AppSettings(
    id: 'user-id',
    language: language,
    displaySettings: const DisplaySettings(
      baseTheme: AppBaseTheme.system,
      accentTheme: AppAccentTheme.defaultBlue,
      fontFamily: 'SystemDefault',
      textScaleFactor: AppTextScaleFactor.medium,
      fontWeight: AppFontWeight.regular,
    ),
    feedSettings: const FeedSettings(
      feedItemDensity: FeedItemDensity.standard,
      feedItemImageStyle: FeedItemImageStyle.smallThumbnail,
      feedItemClickBehavior: FeedItemClickBehavior.internalNavigation,
    ),
  );

  setUpAll(() {
    registerFallbackValue(FakeAppSettings());
    registerFallbackValue(FakeAppEvent());
    PackageInfo.setMockInitialValues(
      appName: 'News App',
      packageName: 'com.example.news',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'buildSignature',
    );
  });

  setUp(() {
    appBloc = MockAppBloc();
    goRouter = MockGoRouter();
    when(() => appBloc.state).thenReturn(
      AppState(
        status: AppLifeCycleStatus.authenticated,
        settings: initialSettings,
      ),
    );
  });

  group('SettingsPage', () {
    testWidgets('renders CircularProgressIndicator when settings are null', (
      tester,
    ) async {
      when(
        () => appBloc.state,
      ).thenReturn(const AppState(status: AppLifeCycleStatus.authenticated));
      await tester.pumpApp(
        const SettingsPage(),
        appBloc: appBloc,
        router: goRouter,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders settings list when settings are available', (
      tester,
    ) async {
      await tester.pumpApp(
        const SettingsPage(),
        appBloc: appBloc,
        router: goRouter,
      );
      await tester.pumpAndSettle(); // For PackageInfo
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('FEED'), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);
    });

    testWidgets(
      'navigates to accent color and fonts page when ListTile is tapped',
      (tester) async {
        when(
          () => goRouter.pushNamed(Routes.settingsAccentColorAndFontsName),
        ).thenAnswer((_) async => null);

        await tester.pumpApp(
          const SettingsPage(),
          appBloc: appBloc,
          router: goRouter,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Accent Color & Fonts'));
        await tester.pumpAndSettle();

        verify(
          () => goRouter.pushNamed(Routes.settingsAccentColorAndFontsName),
        ).called(1);
      },
    );

    testWidgets('navigates to feed settings page when ListTile is tapped', (
      tester,
    ) async {
      when(
        () => goRouter.pushNamed(Routes.settingsFeedName),
      ).thenAnswer((_) async => null);

      await tester.pumpApp(
        const SettingsPage(),
        appBloc: appBloc,
        router: goRouter,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Layout & Reading'));
      await tester.pumpAndSettle();

      verify(() => goRouter.pushNamed(Routes.settingsFeedName)).called(1);
    });

    group('_ThemeModeSetting', () {
      testWidgets('updates theme mode when a segment is tapped', (
        tester,
      ) async {
        await tester.pumpApp(
          const SettingsPage(),
          appBloc: appBloc,
          router: goRouter,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.light_mode_outlined));
        await tester.pumpAndSettle();

        final captured =
            verify(() => appBloc.add(captureAny())).captured.last as AppEvent;
        expect(captured, isA<AppSettingsChanged>());
        final event = captured as AppSettingsChanged;
        expect(event.settings.displaySettings.baseTheme, AppBaseTheme.light);
      });
    });
  });
}
