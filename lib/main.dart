import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_firestore/ht_headlines_firestore.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/app/app.dart';
import 'package:ht_main/bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Bloc.observer = const AppBlocObserver();
  final firestore = FirebaseFirestore.instance;
  final headlinesClient = HtHeadlinesFirestore(firestore: firestore);
  final headlinesRepository = HtHeadlinesRepository(client: headlinesClient);

  runApp(App(htHeadlinesRepository: headlinesRepository));
}
