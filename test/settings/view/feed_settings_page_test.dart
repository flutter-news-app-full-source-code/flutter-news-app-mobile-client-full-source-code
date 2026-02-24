import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/feed_settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class FakeAppSettings extends Fake implements AppSettings {}

class FakeAppEvent extends Fake implements AppEvent {}

// Test helper
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget, {required AppBloc appBloc}) {
    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: appBloc, child: widget),
      ),
    );
  }
}

void main() {
  late AppBloc appBloc;

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
      fontFamily: 'Roboto',
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
  });

  setUp(() {
    appBloc = MockAppBloc();
    when(() => appBloc.state).thenReturn(
      AppState(
        status: AppLifeCycleStatus.authenticated,
        settings: initialSettings,
      ),
    );
  });

  group('FeedSettingsPage', () {
    testWidgets('renders CircularProgressIndicator when settings are null', (
      tester,
    ) async {
      when(
        () => appBloc.state,
      ).thenReturn(const AppState(status: AppLifeCycleStatus.authenticated));
      await tester.pumpApp(const FeedSettingsPage(), appBloc: appBloc);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders settings list when settings are available', (
      tester,
    ) async {
      await tester.pumpApp(const FeedSettingsPage(), appBloc: appBloc);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Feed Tile Layout'), findsOneWidget);
      expect(find.text('Open links using'), findsOneWidget);
    });

    group('_LayoutStyleSelector', () {
      testWidgets('dispatches AppSettingsChanged when a style is tapped', (
        tester,
      ) async {
        await tester.pumpApp(const FeedSettingsPage(), appBloc: appBloc);

        await tester.tap(find.text('Text Only'));
        await tester.pump();

        final captured =
            verify(() => appBloc.add(captureAny())).captured.last as AppEvent;
        expect(captured, isA<AppSettingsChanged>());
        final event = captured as AppSettingsChanged;
        expect(
          event.settings.feedSettings.feedItemImageStyle,
          FeedItemImageStyle.hidden,
        );
      });
    });

    group('_OpenLinksInSelector', () {
      testWidgets('dispatches AppSettingsChanged when a behavior is tapped', (
        tester,
      ) async {
        await tester.pumpApp(const FeedSettingsPage(), appBloc: appBloc);

        await tester.tap(find.text('System browser'));
        await tester.pump();

        final captured =
            verify(() => appBloc.add(captureAny())).captured.last as AppEvent;
        expect(captured, isA<AppSettingsChanged>());
        final event = captured as AppSettingsChanged;
        expect(
          event.settings.feedSettings.feedItemClickBehavior,
          FeedItemClickBehavior.externalNavigation,
        );
      });
    });
  });
}
