import 'package:flutter/material.dart';

import '../../../data/services/fastapi_gateway.dart';
import '../../../data/services/firebase_service.dart';
import '../signin_or_signup/loginpage.dart';
import 'profile_action_page.dart';
import '../recordbook/recordbookpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firebase = FirebaseService();
  final _gateway = FastApiGateway();

  Map<String, dynamic>? _profileSummary;
  String? _error;
  String? _lastSyncTime;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadProfileSummary();
    _loadSyncTime();
  }

  Future<void> _loadSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSyncTime = prefs.getString('last_sync_time');
    });
  }

  Future<void> _saveToCloud() async {
    final user = _firebase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    setState(() => _isSyncing = true);
    
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set({
        'balance': RecordBookData.balance,
        'startDate': RecordBookData.startDate.toIso8601String(),
        'endDate': RecordBookData.endDate.toIso8601String(),
        'categories': RecordBookData.categories.map((c) => c.toJson()).toList(),
      }, SetOptions(merge: true));

      final now = DateTime.now();
      final formattedTime = '${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', formattedTime);

      setState(() => _lastSyncTime = formattedTime);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully saved to cloud.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadProfileSummary() async {
    final user = _firebase.currentUser;
    if (user == null) return;
    try {
      debugPrint('Fetching latest stats...');
      final summary = await _gateway.fetchProfileSummary(user.uid);
      setState(() {
        _profileSummary = summary;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to reach FastAPI gateway: ${e.toString()}';
      });
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out without saving to sync?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
    if (confirm != true) return;

    await _firebase.signOut();
    if (!mounted) return;
    setState(() {
      _profileSummary = null;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );
  }

  void _openActionPage(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileActionPage(title: title),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0048B3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade900),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebase.currentUser;
    final displayName = user?.displayName ?? 'No Name';
    final role = 'Student';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, size: 50, color: Colors.blue),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      role,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWeb = MediaQuery.of(context).size.width > 600;
                        if (isWeb) {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildStatsCard('Average Daily Spending', '<empty>'),
                              _buildStatsCard('Average Weekly Spending', '<empty>'),
                              _buildStatsCard('Average Monthly Spending', '<empty>'),
                              _buildStatsCard('Login Streak', '<empty>'),
                            ],
                          );
                        }
                        return Center(
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.2,
                              children: [
                                _buildStatsCard('Average Daily Spending', '<empty>'),
                                _buildStatsCard('Average Weekly Spending', '<empty>'),
                                _buildStatsCard('Average Monthly Spending', '<empty>'),
                                _buildStatsCard('Login Streak', '<empty>'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              if (_profileSummary != null)
                Text(
                  'Summary from FastAPI: ${_profileSummary!['summary'] ?? 'No data yet'}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              _buildActionButton(
                'Export Reports',
                Icons.file_download,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting reports successfully...')),
                  );
                },
              ),
              _buildActionButton(
                _isSyncing 
                  ? 'Syncing...' 
                  : (_lastSyncTime != null ? 'Save to Cloud (Last: $_lastSyncTime)' : 'Save to Cloud'),
                _isSyncing ? Icons.sync : Icons.cloud_upload,
                _isSyncing ? () {} : _saveToCloud,
              ),
              _buildActionButton(
                'Manage Records',
                Icons.folder_open,
                () => _openActionPage('Manage Records'),
              ),
              _buildActionButton(
                'Settings',
                Icons.settings,
                () => _openActionPage('Settings'),
              ),
              _buildActionButton(
                user == null ? 'Log in' : 'Sign out',
                user == null ? Icons.login : Icons.logout,
                user == null
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        )
                    : _signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
