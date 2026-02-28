import 'package:flutter/material.dart';

/// Placeholder page with only the navigator chrome visible.
class RecordBookPage extends StatelessWidget {
  const RecordBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Record book content will show here.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
