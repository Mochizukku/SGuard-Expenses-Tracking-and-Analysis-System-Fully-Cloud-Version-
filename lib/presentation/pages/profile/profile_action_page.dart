import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../recordbook/recordbookpage.dart';

class ProfileActionPage extends StatefulWidget {
  const ProfileActionPage({super.key, required this.title});

  final String title;

  @override
  State<ProfileActionPage> createState() => _ProfileActionPageState();
}

class _ProfileActionPageState extends State<ProfileActionPage> {
  bool _isLoading = false;

  Future<void> _saveToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login first.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set({
        'balance': RecordBookData.balance,
        'startDate': RecordBookData.startDate.toIso8601String(),
        'endDate': RecordBookData.endDate.toIso8601String(),
        'categories': RecordBookData.categories.map((c) => c.toJson()).toList(),
      }, SetOptions(merge: true));
      _showMessage('Successfully saved to cloud.');
    } catch (e) {
      _showMessage('Failed to save data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  void _showMessage(String text) {
    if (!mounted) return;
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
            child: _isLoading ? const CircularProgressIndicator() : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Save to Cloud'),
                  onPressed: _saveToCloud,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
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
