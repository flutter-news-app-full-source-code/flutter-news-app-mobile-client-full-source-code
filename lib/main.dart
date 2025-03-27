import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_firebase/ht_authentication_firebase.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_headlines_firestore/ht_headlines_firestore.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_kv_storage_shared_preferences/ht_kv_storage_shared_preferences.dart';
import 'package:ht_main/app/app.dart';
import 'package:ht_main/bloc_observer.dart';
import 'package:ht_main/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Bloc.observer = const AppBlocObserver();

  final kvStorage = await HtKvStorageSharedPreferences.getInstance();

  // --- Instantiate Repositories ---
  // 1. Authentication Repository
  // Define ActionCodeSettings for email link sign-in
  final actionCodeSettings = ActionCodeSettings(
    // IMPORTANT: Replace with your actual Firebase Dynamic Link domain/setup
    url: 'https://htmain.page.link/finishLogin',
    handleCodeInApp: true,
    // IMPORTANT: Replace with your actual bundle/package IDs
    iOSBundleId: 'com.example.htMain', // Example ID
    androidPackageName: 'com.example.ht_main', // Example ID
    androidInstallApp: true,
    androidMinimumVersion: '12', // Optional: Specify minimum Android version
  );

  final authenticationClient = HtAuthenticationFirebase(
    actionCodeSettings: actionCodeSettings,
  );
  final authenticationRepository = HtAuthenticationRepository(
    authenticationClient: authenticationClient,
    storageService: kvStorage, // Pass the storage service
  );

  // 2. Headlines Repository
  final firestore = FirebaseFirestore.instance;
  final headlinesClient = HtHeadlinesFirestore(firestore: firestore);
  final headlinesRepository = HtHeadlinesRepository(client: headlinesClient);
  // --- End Instantiation ---

  runApp(
    App(
      htAuthenticationRepository: authenticationRepository,
      htHeadlinesRepository: headlinesRepository,
      kvStorageService: kvStorage, // Pass storage service to App
    ),
  );
}
