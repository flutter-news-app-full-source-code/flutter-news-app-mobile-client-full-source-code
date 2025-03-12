import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/router.dart';

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

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppBloc(),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return MaterialApp.router(
            theme:
                state.themeMode == ThemeMode.light ? lightTheme() : darkTheme(),
            routerConfig: appRouter,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
