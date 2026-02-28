import 'package:flutter/material.dart';

/// Simple placeholder that matches the requested empty state.
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today:',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '<empty>',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'No spending records yet. Pull down to refresh once data is ready.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
