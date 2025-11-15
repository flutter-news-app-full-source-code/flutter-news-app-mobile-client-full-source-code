import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/saved_headlines_filters_bloc.dart';

/// {@template saved_headlines_filters_page}
/// A page for managing a user's saved headline filters.
///
/// This page displays a list of all saved filters, allowing users to apply,
/// reorder, edit, or delete them. It also provides an entry point for creating
/// new filters.
/// {@endtemplate}
class SavedHeadlinesFiltersPage extends StatelessWidget {
  /// {@macro saved_headlines_filters_page}
  const SavedHeadlinesFiltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavedHeadlinesFiltersBloc(
        // The AppBloc is read from the context to get the initial list of
        // saved filters and to dispatch update events.
        appBloc: context.read<AppBloc>(),
      ),
      // The main view will be implemented in a subsequent step.
      child: const Scaffold(
        body: Center(child: Text('Saved Headlines Filters Page Placeholder')),
      ),
    );
  }
}
