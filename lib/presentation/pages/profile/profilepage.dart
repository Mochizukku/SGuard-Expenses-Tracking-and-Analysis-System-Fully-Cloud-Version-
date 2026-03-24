import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/fastapi_gateway.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/services/record_book_store.dart';
import '../../../data/services/record_export_service.dart';
import '../signin_or_signup/loginpage.dart';
import '../recordbook/recordbookpage.dart';
import 'managerecordpage.dart';
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
  String? _lastSyncTime;
  int _loginStreak = 1;
  bool _isSyncing = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadProfileSummary();
    _loadSyncTime();
    _updateLoginStreak();
  }

  Future<void> _loadSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _lastSyncTime = prefs.getString('last_sync_time');
    });
  }

  Future<void> _updateLoginStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final storedDate = prefs.getString('last_open_date');
    final storedStreak = prefs.getInt('login_streak') ?? 0;

    var newStreak = 1;
    if (storedDate != null) {
      final previous = DateTime.tryParse(storedDate);
      if (previous != null) {
        final prevDate = DateTime(previous.year, previous.month, previous.day);
        final dayDiff = today.difference(prevDate).inDays;
        if (dayDiff == 0) {
          newStreak = storedStreak > 0 ? storedStreak : 1;
        } else if (dayDiff == 1) {
          newStreak = storedStreak + 1;
        }
      }
    }

    await prefs.setString('last_open_date', today.toIso8601String());
    await prefs.setInt('login_streak', newStreak);

    if (!mounted) {
      return;
    }
    setState(() => _loginStreak = newStreak);
  }

  double _totalSpent() {
    return RecordBookData.categories.fold(0.0, (sum, category) => sum + category.total);
  }

  int _recordedDays() {
    final keys = <String>{};
    for (final category in RecordBookData.categories) {
      for (final item in category.items) {
        keys.add(RecordBookStore.dateKeyFromDate(item.date));
      }
    }
    return keys.isEmpty ? 1 : keys.length;
  }

  Future<void> _saveToCloud() async {
    final user = _firebase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    setState(() => _isSyncing = true);

    try {
      await RecordBookStore.saveCurrentToCloud();

      final now = DateTime.now();
      final formattedTime =
          '${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', formattedTime);

      if (!mounted) {
        return;
      }
      setState(() => _lastSyncTime = formattedTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${RecordBookStore.dateKeyFromDate(RecordBookData.activeDate)} to cloud.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _exportReports() async {
    setState(() => _isExporting = true);
    try {
      await RecordExportService.exportCurrentSnapshotPdf();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _loadProfileSummary() async {
    final user = _firebase.currentUser;
    if (user == null) {
      return;
    }

    try {
      final summary = await _gateway.fetchProfileSummary(user.uid);
      if (!mounted) {
        return;
      }
      setState(() {
        _profileSummary = summary;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to reach FastAPI gateway: ${error.toString()}';
      });
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out without saving the current day to cloud?'),
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
      ),
    );
    if (confirm != true) {
      return;
    }

    await _firebase.signOut();
    if (!mounted) {
      return;
    }
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
      MaterialPageRoute(builder: (_) => ProfileActionPage(title: title)),
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
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: RecordBookData.revision,
      builder: (context, _, __) {
        final user = _firebase.currentUser;
        final displayName = user?.displayName ?? 'No Name';
        final role = 'Student';
        final totalSpent = _totalSpent();
        final dailyAverage = totalSpent / _recordedDays();
        final weeklyAverage = dailyAverage * 7;
        final monthlyAverage = dailyAverage * 30;

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
                        Text(role, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          'Active record: ${RecordBookStore.dateKeyFromDate(RecordBookData.activeDate)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = MediaQuery.of(context).size.width > 600;
                            final cards = [
                              _buildStatsCard('Average Daily Spending', '\$${dailyAverage.toStringAsFixed(2)}'),
                              _buildStatsCard('Average Weekly Spending', '\$${weeklyAverage.toStringAsFixed(2)}'),
                              _buildStatsCard('Average Monthly Spending', '\$${monthlyAverage.toStringAsFixed(2)}'),
                              _buildStatsCard('Login Streak', '$_loginStreak day${_loginStreak == 1 ? '' : 's'}'),
                            ];

                            if (isWide) {
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: cards,
                              );
                            }

                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.2,
                              children: cards,
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
                    _isExporting ? 'Exporting PDF...' : 'Export Reports',
                    Icons.picture_as_pdf,
                    _isExporting ? () {} : _exportReports,
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
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageRecordPage()),
                    ),
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
      },
    );
  }
}
