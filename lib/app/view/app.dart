import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AppBloc(
              authenticationRepository:
                  context.read<HtAuthenticationRepository>(),
            ),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme:
              state.themeMode == ThemeMode.light ? lightTheme() : darkTheme(),
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
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
