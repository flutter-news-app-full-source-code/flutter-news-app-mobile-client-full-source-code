import 'package:flutter/material.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({
    required this.icon,
    required this.headline,
    required this.subheadline,
    super.key,
  });

  final IconData icon;
  final String headline;
  final String subheadline;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64),
          const SizedBox(height: 16),
          Text(headline, style: const TextStyle(fontSize: 24)),
          Text(subheadline),
          const SizedBox(height: 16),
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
