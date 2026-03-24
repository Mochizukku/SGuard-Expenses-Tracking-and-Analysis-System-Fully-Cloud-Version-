import 'package:flutter/material.dart';

import '../../../data/services/record_book_store.dart';

class ProfileActionPage extends StatefulWidget {
  const ProfileActionPage({super.key, required this.title});

  final String title;

  @override
  State<ProfileActionPage> createState() => _ProfileActionPageState();
}

class _ProfileActionPageState extends State<ProfileActionPage> {
  bool _isLoading = false;

  Future<void> _saveToCloud() async {
    setState(() => _isLoading = true);
    try {
      await RecordBookStore.saveCurrentToCloud();
      _showMessage('Successfully saved the active day to cloud.');
    } catch (error) {
      _showMessage('Failed to save data: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 2,
      ),
      body: widget.title == 'Sync/Cloud Status'
          ? Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Save Active Day to Cloud'),
                          onPressed: _saveToCloud,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
            )
          : Center(
              child: Text(
                'The ${widget.title} page is under construction.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
