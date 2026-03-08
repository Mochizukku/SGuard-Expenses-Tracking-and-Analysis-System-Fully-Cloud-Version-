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

  Future<void> _loadFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login first.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        RecordBookData.balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        if (data['startDate'] != null) {
          RecordBookData.startDate = DateTime.parse(data['startDate']);
        }
        if (data['endDate'] != null) {
          RecordBookData.endDate = DateTime.parse(data['endDate']);
        }
        if (data['categories'] != null) {
          final cats = data['categories'] as List<dynamic>;
          RecordBookData.categories = cats.map((c) => SpendingCategory.fromJson(c as Map<String, dynamic>)).toList();
        }
        _showMessage('Successfully loaded from cloud. Changes will appear when you back out.');
      } else {
        _showMessage('No cloud data found.');
      }
    } catch (e) {
      _showMessage('Failed to load data: $e');
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Load from Cloud'),
                  onPressed: _loadFromCloud,
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
