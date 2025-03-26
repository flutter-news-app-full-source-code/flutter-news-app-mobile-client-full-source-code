// Required for StreamSubscription

import 'package:flex_color_scheme/flex_color_scheme.dart';
// Required for Listenable
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:google_fonts/google_fonts.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
// Import the createRouter function and the helper stream
import 'package:ht_main/router/go_router_refresh_stream.dart';
import 'package:ht_main/router/router.dart';
// Routes class is still needed if createRouter uses it, which it does

class App extends StatelessWidget {
  const App({
    required HtHeadlinesRepository htHeadlinesRepository,
    required HtAuthenticationRepository htAuthenticationRepository,
    // AppBloc is no longer passed in constructor
    super.key,
  })  : _htHeadlinesRepository = htHeadlinesRepository,
        _htAuthenticationRepository = htAuthenticationRepository;

  final HtHeadlinesRepository _htHeadlinesRepository;
  final HtAuthenticationRepository _htAuthenticationRepository;
  // No longer storing AppBloc instance here

  @override
  Widget build(BuildContext context) {
    // Provide repositories globally
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _htHeadlinesRepository),
        RepositoryProvider.value(value: _htAuthenticationRepository),
      ],
      // Create AppBloc here using BlocProvider
      child: BlocProvider(
        create: (context) => AppBloc(
          authenticationRepository: context.read<HtAuthenticationRepository>(),
        ),
        // _AppView now reads AppBloc from context
        child: const _AppView(),
      ),
    );
  }
}

// Change _AppView to StatefulWidget to manage GoRouter lifecycle
class _AppView extends StatefulWidget {
  const _AppView(); // No longer needs appBloc passed

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // Store the router and the refresh stream listener
  late final GoRouter _router;
  late final GoRouterRefreshStream _refreshListener;

  @override
  void initState() {
    super.initState();
    // Get the AppBloc instance from the BlocProvider above
    final appBloc = context.read<AppBloc>();
    // Create the refresh listener using the AppBloc stream
    _refreshListener = GoRouterRefreshStream(appBloc.stream);
    // Create the router instance by calling the function from router.dart
    _router = createRouter(refreshListenable: _refreshListener);
  }

  @override
  void dispose() {
    // Dispose the refresh listener when the widget is disposed
    _refreshListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to react to theme changes from AppBloc
    return BlocBuilder<AppBloc, AppState>(
      // Use buildWhen for optimization if only theme affects MaterialApp
      buildWhen: (previous, current) => previous.themeMode != current.themeMode,
      builder: (context, state) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          // Apply theme based on AppBloc state
          themeMode: state.themeMode,
          theme: lightTheme(),
          darkTheme: darkTheme(),
          // Use the router created and stored in the state
          routerConfig: _router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}

// --- Themes (unchanged) ---
ThemeData lightTheme() {
  return FlexThemeData.light(
    scheme: FlexScheme.greyLaw,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );
}

ThemeData darkTheme() {
  return FlexThemeData.dark(
    scheme: FlexScheme.greyLaw,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );
}
