import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_firebase/ht_authentication_firebase.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_categories_firestore/ht_categories_firestore.dart';
import 'package:ht_categories_repository/ht_categories_repository.dart';
import 'package:ht_countries_firestore/ht_countries_firestore.dart';
import 'package:ht_countries_repository/ht_countries_repository.dart';
import 'package:ht_headlines_firestore/ht_headlines_firestore.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_kv_storage_shared_preferences/ht_kv_storage_shared_preferences.dart';
import 'package:ht_main/app/app.dart';
import 'package:ht_main/bloc_observer.dart';
import 'package:ht_main/firebase_options.dart';
import 'package:ht_preferences_firestore/ht_preferences_firestore.dart'; // Added
import 'package:ht_preferences_repository/ht_preferences_repository.dart'; // Added
import 'package:ht_sources_firestore/ht_sources_firestore.dart';
import 'package:ht_sources_repository/ht_sources_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Bloc.observer = const AppBlocObserver();

  final kvStorage = await HtKvStorageSharedPreferences.getInstance();

  // --- Instantiate Repositories ---
  // 1. Authentication Repository
  // Define ActionCodeSettings for email link sign-in
  final actionCodeSettings = ActionCodeSettings(
    url: 'https://htmain.page.link/finishLogin',
    handleCodeInApp: true,
    iOSBundleId: 'com.example.htMain',
    androidPackageName: 'com.example.ht_main',
    androidInstallApp: true,
    androidMinimumVersion: '12', // Optional: Specify minimum Android version
  );

  final authenticationClient = HtAuthenticationFirebase(
    actionCodeSettings: actionCodeSettings,
  );
  final authenticationRepository = HtAuthenticationRepository(
    authenticationClient: authenticationClient,
    storageService: kvStorage,
  );

  // 2. Headlines Repository
  final firestore = FirebaseFirestore.instance;
  final headlinesClient = HtHeadlinesFirestore(firestore: firestore);
  final headlinesRepository = HtHeadlinesRepository(client: headlinesClient);

  // 3. Categories Repository
  final categoriesClient = HtCategoriesFirestore(firestore: firestore);
  final categoriesRepository = HtCategoriesRepository(
    categoriesClient: categoriesClient,
  );

  // 4. Countries Repository
  final countriesClient = HtCountriesFirestore(firestore: firestore);
  final countriesRepository = HtCountriesRepository(
    countriesClient: countriesClient,
  );

  // 5. Sources Repository
  final sourcesClient = HtSourcesFirestore(firestore: firestore);
  final sourcesRepository = HtSourcesRepository(sourcesClient: sourcesClient);

  // 6. Preferences Repository (Added)
  // IMPORTANT: This assumes currentUser is immediately available after auth repo init.
  // If not, initialization might need to be deferred or handled differently.
  final currentUserId = authenticationRepository.currentUser.uid; // Assuming 'uid' property
  // Firestore typically requires non-empty document IDs.
  // Handle cases where the user might be anonymous or ID is empty.
  if (currentUserId.isEmpty) {
    // Option 1: Throw an error if user ID is required but missing
    // throw StateError('User ID is empty, cannot initialize preferences.');
    // Option 2: Use a default ID for anonymous/uninitialized users (use cautiously)
    // currentUserId = 'anonymous_user_settings';
    // Option 3: Let the client handle it (assuming it can)
    print(
      'Warning: Initializing HtPreferencesFirestore with an empty user ID.',
    );
  }
  final preferencesClient = HtPreferencesFirestore(
    firestore: firestore,
    userId: currentUserId, // Pass userId directly
  );
  final preferencesRepository = HtPreferencesRepository(
    preferencesClient: preferencesClient,
    // maxHistorySize: 25, // Default is 25 in the provided repo code
  );
  // --- End Instantiation ---

  runApp(
    App(
      htAuthenticationRepository: authenticationRepository,
      htHeadlinesRepository: headlinesRepository,
      htCategoriesRepository: categoriesRepository,
      htCountriesRepository: countriesRepository,
      htSourcesRepository: sourcesRepository,
      htPreferencesRepository: preferencesRepository, // Added
      kvStorageService: kvStorage,
    ),
  );
}
