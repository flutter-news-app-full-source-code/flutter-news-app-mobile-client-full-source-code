import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_status_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

void main() {
  group('AppStatusService', () {
    late AppBloc appBloc;

    setUp(() {
      appBloc = MockAppBloc();
    });

    testWidgets('observes lifecycle state change and dispatches event', (
      tester,
    ) async {
      // Use a distinct key to look up the AppStatusService if needed,
      // or just capture the context from the builder.
      late AppStatusService service;

      await tester.pumpWidget(
        BlocProvider<AppBloc>.value(
          value: appBloc,
          child: Builder(
            builder: (context) {
              service = AppStatusService(
                context: context,
                checkInterval: const Duration(minutes: 5),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      // Trigger the lifecycle change
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Verify that the service triggered an event on the BLoC
      verify(
        () => appBloc.add(const AppPeriodicConfigFetchRequested()),
      ).called(1);

      // Dispose the widget to cancel the timer
      // Dispose the service to cancel the timer
      service.dispose();

      await tester.pumpWidget(const SizedBox());
    });
  });
}
