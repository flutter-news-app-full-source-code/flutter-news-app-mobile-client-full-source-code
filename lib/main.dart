import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_inmemory/ht_headlines_inmemory.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/app/app.dart';
import 'package:ht_main/bloc_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  final headlinesClient = HtInMemoryHeadlinesClient();
  final headlinesRepository = HtHeadlinesRepository(client: headlinesClient);

  runApp(App(htHeadlinesRepository: headlinesRepository));
}
