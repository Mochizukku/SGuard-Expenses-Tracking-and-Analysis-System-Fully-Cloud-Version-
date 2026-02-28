import 'package:flutter/material.dart';

import '../../../data/services/fastapi_gateway.dart';
import '../../../data/services/firebase_service.dart';
import 'profile_action_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfileSummary();
  }

  Future<void> _loadProfileSummary() async {
    final user = _firebase.currentUser;
    if (user == null) return;
    try {
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
    await _firebase.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    }
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
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
    final displayName = user?.displayName ?? 'Mo E. Lester';
    final role = 'Student';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: const Icon(Icons.person, size: 52, color: Colors.blue),
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatsCard('Average Daily Spending', '\$120.00'),
                    _buildStatsCard('Average Weekly Spending', '\$480.00'),
                    _buildStatsCard('Average Monthly Spending', '\$1670.00'),
                    _buildStatsCard('Login Streak', '34 days'),
                  ],
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
            )
          else
            const Text(
              'Fetching latest stats...',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          const SizedBox(height: 16),
          _buildActionButton(
            'Export Reports',
            Icons.file_download,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting reports is handled by FastAPI & Firestore records')),
              );
            },
          ),
          _buildActionButton(
            'Sync/Cloud Status',
            Icons.sync_alt,
            () => _openActionPage('Sync/Cloud Status'),
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
            'Sign out',
            Icons.logout,
            _signOut,
          ),
        ],
      ),
    );
  }
}
