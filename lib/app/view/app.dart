import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/router.dart';

class App extends StatelessWidget {
  const App({
    required HtHeadlinesRepository htHeadlinesRepository,
    required HtAuthenticationRepository htAuthenticationRepository,
    super.key,
  })  : _htHeadlinesRepository = htHeadlinesRepository,
        _htAuthenticationRepository = htAuthenticationRepository;

  final HtHeadlinesRepository _htHeadlinesRepository;
  final HtAuthenticationRepository _htAuthenticationRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _htHeadlinesRepository),
        RepositoryProvider.value(value: _htAuthenticationRepository),
      ],
      child: BlocProvider(
        create: (context) => AppBloc(
          authenticationRepository: context.read<HtAuthenticationRepository>(),
        ),
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // Store the router and the status notifier
  late final GoRouter _router;
  late final ValueNotifier<AppStatus> _statusNotifier;

  @override
  void initState() {
    super.initState();
    // Get the AppBloc instance from the BlocProvider above
    final appBloc = context.read<AppBloc>();

    // Create the ValueNotifier, initialized with the current status
    _statusNotifier = ValueNotifier<AppStatus>(appBloc.state.status);

    // Create the router instance, passing the ValueNotifier as the listenable
    _router = createRouter(authStatusNotifier: _statusNotifier);
  }

  @override
  void dispose() {
    // Remove subscription cancellation
    // _blocSubscription.cancel();
    // Dispose the ValueNotifier
    _statusNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the part of the tree that needs to react to AppBloc state changes
    // (specifically for updating the ValueNotifier) with a BlocListener.
    // The BlocBuilder remains for theme changes.
    return BlocListener<AppBloc, AppState>(
      // Only listen when the status actually changes
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        // Update the ValueNotifier when the AppBloc status changes.
        // This triggers the GoRouter's refreshListenable.
        _statusNotifier.value = state.status;
      },
      child: BlocBuilder<AppBloc, AppState>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode,
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: lightTheme(),
            darkTheme: darkTheme(),
            routerConfig: _router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}

ThemeData lightTheme() {
  return FlexThemeData.light(
    scheme: FlexScheme.material,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );
}

ThemeData darkTheme() {
  return FlexThemeData.dark(
    scheme: FlexScheme.material,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );
}
