import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_firebase/ht_authentication_firebase.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
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
  final authenticationClient = HtAuthenticationFirebase();
  final authenticationRepository = HtAuthenticationRepository(
    authenticationClient: authenticationClient,
  );
  runApp(
    App(
      htAuthenticationRepository: authenticationRepository,
      htHeadlinesRepository: headlinesRepository,
    ),
  );
}
