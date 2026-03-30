import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/record_book_store.dart';
import '../recordbook/recordbookpage.dart';
import '../signin_or_signup/loginpage.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildRow(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                color: const Color(0xFF004AAD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    height: 82,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF2C69C8)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 42),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildRow(context, 'Profile', () => _open(context, const SettingsProfilePage())),
                        _buildRow(context, 'Account', () => _open(context, const SettingsAccountPage())),
                        _buildRow(context, 'Tracking System', () => _open(context, const SettingsTrackingPage())),
                        _buildRow(context, 'Personalization', () => _open(context, const SettingsPersonalizationPage())),
                      ],
                    ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF004AAD),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [child],
      ),
    );
  }
}

class SettingsProfilePage extends StatelessWidget {
  const SettingsProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return _SettingsScaffold(
      title: 'Profile',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${user?.displayName ?? 'No name available'}'),
              const SizedBox(height: 8),
              Text('Email: ${user?.email ?? 'Not signed in'}'),
              const SizedBox(height: 8),
              Text('UID: ${user?.uid ?? 'Unavailable'}'),
              const SizedBox(height: 8),
              Text('Active record date: ${RecordBookStore.dateKeyFromDate(RecordBookData.activeDate)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsAccountPage extends StatelessWidget {
  const SettingsAccountPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return _SettingsScaffold(
      title: 'Account',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Login state: ${user == null ? 'Signed out' : 'Signed in'}'),
              const SizedBox(height: 8),
              Text('Email: ${user?.email ?? 'No email available'}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: user == null ? null : () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsTrackingPage extends StatefulWidget {
  const SettingsTrackingPage({super.key});

  @override
  State<SettingsTrackingPage> createState() => _SettingsTrackingPageState();
}

class _SettingsTrackingPageState extends State<SettingsTrackingPage> {
  String? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadSync();
  }

  Future<void> _loadSync() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() => _lastSync = prefs.getString('last_sync_time'));
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Tracking System',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current active date: ${RecordBookStore.dateKeyFromDate(RecordBookData.activeDate)}'),
              const SizedBox(height: 8),
              Text('Last cloud save: ${_lastSync ?? 'No cloud save recorded yet'}'),
              const SizedBox(height: 8),
              const Text(
                'Daily records reset by server date when cloud sync is available, then the matching saved day is loaded.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPersonalizationPage extends StatefulWidget {
  const SettingsPersonalizationPage({super.key});

  @override
  State<SettingsPersonalizationPage> createState() => _SettingsPersonalizationPageState();
}

class _SettingsPersonalizationPageState extends State<SettingsPersonalizationPage> {
  bool _compactCards = false;
  bool _showQuickHints = true;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Personalization',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Compact dashboard cards'),
                subtitle: const Text('Reserved local preference for future UI tuning.'),
                value: _compactCards,
                onChanged: (value) => setState(() => _compactCards = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show quick hints'),
                subtitle: const Text('Keeps instructional hints visible in future screens.'),
                value: _showQuickHints,
                onChanged: (value) => setState(() => _showQuickHints = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
