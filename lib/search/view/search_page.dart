import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SearchView();
  }
}

class _SearchView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      child: Text('SEARCH VIEW'),
    );
  }
}
