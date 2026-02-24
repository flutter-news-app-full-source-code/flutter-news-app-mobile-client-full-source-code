import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/theme_and_font_settings_page.dart';
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

  group('ThemeAndFontSettingsPage', () {
    testWidgets('renders CircularProgressIndicator when settings are null', (
      tester,
    ) async {
      when(
        () => appBloc.state,
      ).thenReturn(const AppState(status: AppLifeCycleStatus.authenticated));
      await tester.pumpApp(const ThemeAndFontSettingsPage(), appBloc: appBloc);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders settings list when settings are available', (
      tester,
    ) async {
      await tester.pumpApp(const ThemeAndFontSettingsPage(), appBloc: appBloc);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Accent Color'), findsOneWidget);
      expect(find.text('Font Weight'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    group('_AccentThemeSelector', () {
      testWidgets('shows checkmark on selected color', (tester) async {
        await tester.pumpApp(
          const ThemeAndFontSettingsPage(),
          appBloc: appBloc,
        );

        final blueCircle = find.byWidgetPredicate(
          (widget) =>
              widget is CircleAvatar &&
              widget.backgroundColor != null &&
              widget.child is Icon,
        );
        expect(blueCircle, findsOneWidget);
      });

      testWidgets('dispatches AppSettingsChanged when a color is tapped', (
        tester,
      ) async {
        await tester.pumpApp(
          const ThemeAndFontSettingsPage(),
          appBloc: appBloc,
        );

        // Find the red circle avatar (which is not selected)
        final redCircle = find.byWidgetPredicate(
          (widget) =>
              widget is GestureDetector &&
              widget.child is CircleAvatar &&
              (widget.child! as CircleAvatar).child == null,
        );

        await tester.tap(redCircle.first);
        await tester.pump();

        final captured =
            verify(() => appBloc.add(captureAny())).captured.last as AppEvent;
        expect(captured, isA<AppSettingsChanged>());
        final event = captured as AppSettingsChanged;
        expect(
          event.settings.displaySettings.accentTheme,
          AppAccentTheme.newsRed,
        );
      });
    });

    group('_FontWeightSelector', () {
      testWidgets('dispatches AppSettingsChanged when a weight is tapped', (
        tester,
      ) async {
        await tester.pumpApp(
          const ThemeAndFontSettingsPage(),
          appBloc: appBloc,
        );

        await tester.tap(find.text('Bold'));
        await tester.pump();

        final captured =
            verify(() => appBloc.add(captureAny())).captured.last as AppEvent;
        expect(captured, isA<AppSettingsChanged>());
        final event = captured as AppSettingsChanged;
        expect(event.settings.displaySettings.fontWeight, AppFontWeight.bold);
      });
    });
  });
}
