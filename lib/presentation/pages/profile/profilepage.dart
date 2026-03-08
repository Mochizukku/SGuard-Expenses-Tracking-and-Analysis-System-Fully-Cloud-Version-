import 'package:flutter/material.dart';

import '../../../data/services/fastapi_gateway.dart';
import '../../../data/services/firebase_service.dart';
import '../signin_or_signup/loginpage.dart';
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
                    const SnackBar(content: Text('Exporting reports successfully...')),
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
