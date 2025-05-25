import 'package:flutter/material.dart';
import 'package:ht_main/l10n/l10n.dart';

/// {@template saved_headlines_page}
/// A placeholder page for displaying user's saved headlines.
/// {@endtemplate}
class SavedHeadlinesPage extends StatelessWidget {
  /// {@macro saved_headlines_page}
  const SavedHeadlinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSavedHeadlinesTile)),
      body: const Center(child: Text('SAVED HEADLINES PAGE (Placeholder)')),
    );
  }
}
