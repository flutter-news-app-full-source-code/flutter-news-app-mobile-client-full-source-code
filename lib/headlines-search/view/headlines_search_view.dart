import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';

class HeadlinesSearchView extends StatelessWidget {
  const HeadlinesSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          hintText: 'Search Headlines',
          onChanged: (value) {
            context
                .read<HeadlinesSearchBloc>()
                .add(HeadlinesSearchTermChanged(searchTerm: value));
          },
          onSubmitted: (value) {
            context.read<HeadlinesSearchBloc>().add(HeadlinesSearchRequested());
          },
        ),
      ),
      body: BlocBuilder<HeadlinesSearchBloc, HeadlinesSearchState>(
        builder: (context, state) {
          if (state is HeadlinesSearchInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64),
                  SizedBox(height: 16),
                  Text('Search Headlines', style: TextStyle(fontSize: 24)),
                  Text('Enter keywords to find articles'),
                ],
              ),
            );
          } else if (state is HeadlinesSearchLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HeadlinesSearchLoaded) {
            return ListView.builder(
              itemCount: state.headlines.length,
              itemBuilder: (context, index) {
                return HeadlineItemWidget(headline: state.headlines[index]);
              },
            );
          } else if (state is HeadlinesSearchError) {
            return Center(child: Text(state.message));
          }
          return Container(); // Should never reach here
        },
      ),
    );
  }
}
