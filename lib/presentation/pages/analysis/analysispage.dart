import 'package:flutter/material.dart';

/// Minimal placeholder page for the analysis tab.
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Analysis insights will appear here once data arrives.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
