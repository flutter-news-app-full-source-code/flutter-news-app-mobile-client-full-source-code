import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/headlines-search/view/headlines_search_view.dart';

class HeadlinesSearchPage extends StatelessWidget {
  const HeadlinesSearchPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HeadlinesSearchPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => HeadlinesSearchBloc(
            headlinesRepository: context.read<HtHeadlinesRepository>(),
          ),
      child: const HeadlinesSearchView(),
    );
  }
}
