import 'package:flutter/material.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';

class HeadlineFilterBottomSheet extends StatefulWidget {
  const HeadlineFilterBottomSheet({
    required this.onApplyFilters,
    required this.bloc,
    super.key,
  });

  final void Function(
    String? category,
    String? source,
    String? eventCountry,
  ) onApplyFilters;

  final HeadlinesFeedBloc bloc;

  @override
  State<HeadlineFilterBottomSheet> createState() =>
      _HeadlineFilterBottomSheetState();
}

class _HeadlineFilterBottomSheetState extends State<HeadlineFilterBottomSheet> {
  String? _selectedCategory;
  String? _selectedSource;
  String? _selectedEventCountry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter Headlines',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Category Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Category'),
            value: _selectedCategory,
            items: const [
              // Placeholder items
              DropdownMenuItem(value: 'technology', child: Text('Technology')),
              DropdownMenuItem(value: 'business', child: Text('Business')),
              DropdownMenuItem(value: 'Politics', child: Text('Sports')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Source Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Source'),
            value: _selectedSource,
            items: const [
              // Placeholder items
              DropdownMenuItem(value: 'cnn', child: Text('CNN')),
              DropdownMenuItem(value: 'reuters', child: Text('Reuters')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSource = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Event Country Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Event Country'),
            value: _selectedEventCountry,
            items: const [
              // Placeholder items
              DropdownMenuItem(value: 'US', child: Text('United States')),
              DropdownMenuItem(value: 'UK', child: Text('United Kingdom')),
              DropdownMenuItem(value: 'CA', child: Text('Canada')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedEventCountry = value;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onApplyFilters(
                _selectedCategory,
                _selectedSource,
                _selectedEventCountry,
              );
              widget.bloc.add(
                HeadlinesFeedFilterChanged(
                  category: _selectedCategory,
                  source: _selectedSource,
                  eventCountry: _selectedEventCountry,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
