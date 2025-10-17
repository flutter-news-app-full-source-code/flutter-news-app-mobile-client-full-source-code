import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';

/// {@template discover_page}
/// A page that will be used to discover and browse news sources.
///
/// Currently a placeholder.
/// {@endtemplate}
class DiscoverPage extends StatelessWidget {
  /// {@macro discover_page}
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoverPageTitle)),
      body: const Center(child: Text('Discover Page Placeholder')),
    );
  }
}
