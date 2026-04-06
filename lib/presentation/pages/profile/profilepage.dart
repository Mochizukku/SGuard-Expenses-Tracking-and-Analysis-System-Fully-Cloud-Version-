import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/app_settings_controller.dart';
import '../../../data/services/fastapi_gateway.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/services/record_book_store.dart';
import '../../../data/services/record_export_service.dart';
import '../signin_or_signup/loginpage.dart';
import '../recordbook/recordbookpage.dart';
import 'managerecordpage.dart';
import 'settingpage.dart';

class _HistoryMetrics {
  const _HistoryMetrics({
    required this.totalSpent,
    required this.dayCount,
    required this.weekCount,
    required this.monthCount,
  });

  final double totalSpent;
  final int dayCount;
  final int weekCount;
  final int monthCount;
}

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

  Set<String> _recordedDayKeys() {
    final keys = <String>{};
    for (final category in RecordBookData.categories) {
      for (final item in category.items) {
        keys.add(RecordBookStore.dateKeyFromDate(item.date));
      }
    }
    return keys;
  }

  int _recordedWeeks() {
    final keys = <String>{};
    for (final category in RecordBookData.categories) {
      for (final item in category.items) {
        final date = item.date;
        final weekStart = date.subtract(Duration(days: date.weekday % 7));
        keys.add(RecordBookStore.dateKeyFromDate(weekStart));
      }
    }
    return keys.length;
  }

  int _recordedMonths() {
    final keys = <String>{};
    for (final category in RecordBookData.categories) {
      for (final item in category.items) {
        keys.add('${item.date.year}-${item.date.month.toString().padLeft(2, '0')}');
      }
    }
    return keys.length;
  }

  Future<_HistoryMetrics> _loadHistoryMetrics() async {
    final keys = await RecordBookStore.listHistoryDateKeys();
    final dayKeys = <String>{};
    final weekKeys = <String>{};
    final monthKeys = <String>{};
    var totalSpent = 0.0;

    for (final key in keys) {
      final snapshot = await RecordBookStore.fetchHistorySnapshotByDateKey(key);
      if (snapshot == null) {
        continue;
      }

      var snapshotTotal = 0.0;
      for (final category in snapshot.categories) {
        snapshotTotal += category.total;
      }

      if (snapshotTotal <= 0) {
        continue;
      }

      totalSpent += snapshotTotal;
      dayKeys.add(snapshot.dateKey);
      final date = RecordBookStore.dateFromKey(snapshot.dateKey);
      final weekStart = date.subtract(Duration(days: date.weekday % 7));
      weekKeys.add(RecordBookStore.dateKeyFromDate(weekStart));
      monthKeys.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }

    return _HistoryMetrics(
      totalSpent: totalSpent,
      dayCount: dayKeys.length,
      weekCount: weekKeys.length,
      monthCount: monthKeys.length,
    );
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
    final requireConfirm = AppSettingsController
        .instance.settings.value.tracking.confirmResetSensitiveActions;
    final confirm = requireConfirm
        ? await showDialog<bool>(
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
          )
        : true;
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
            style: const TextStyle(fontSize: 12, color: Color(0xFFE7F0FF), fontWeight: FontWeight.w700),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16304B)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(AppProfileSettings settings) {
    if (settings.avatarImagePath.trim().isNotEmpty) {
      final imageFile = File(settings.avatarImagePath);
      if (imageFile.existsSync()) {
        return CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFFE8F0FF),
          backgroundImage: FileImage(imageFile),
        );
      }
    }
    final avatarMap = <String, ({IconData icon, Color color})>{
      'classic_blue': (icon: Icons.person, color: const Color(0xFF004AAD)),
      'green_guard': (icon: Icons.shield_outlined, color: const Color(0xFF147D64)),
      'sunrise_star': (icon: Icons.star_border, color: const Color(0xFFC05621)),
      'violet_face': (icon: Icons.sentiment_satisfied_alt, color: const Color(0xFF6B46C1)),
    };
    final avatar = avatarMap[settings.avatarKey] ?? avatarMap['classic_blue']!;
    return CircleAvatar(
      radius: 44,
      backgroundColor: avatar.color.withValues(alpha: 0.12),
      child: Icon(avatar.icon, size: 44, color: avatar.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettingsData>(
      valueListenable: AppSettingsController.instance.settings,
      builder: (context, __, ___) {
        return ValueListenableBuilder<int>(
          valueListenable: RecordBookData.revision,
          builder: (context, _, ____) {
        final user = _firebase.currentUser;
        final appSettings = AppSettingsController.instance.settings.value;
        final displayName = appSettings.profile.displayName.isNotEmpty
            ? appSettings.profile.displayName
            : (user?.displayName ?? 'No Name');
        final role = appSettings.profile.resolvedStatus;
        final compactCards = appSettings.personalization.compactCards;
        final showQuickHints = appSettings.personalization.showQuickHints;
        final showActiveDateBadge = appSettings.tracking.showActiveDateBadge;

        return FutureBuilder<_HistoryMetrics>(
          future: _loadHistoryMetrics(),
          builder: (context, historySnapshot) {
            final metrics = historySnapshot.data ??
                _HistoryMetrics(
                  totalSpent: _totalSpent(),
                  dayCount: _recordedDayKeys().length,
                  weekCount: _recordedWeeks(),
                  monthCount: _recordedMonths(),
                );
            final dailyAverage =
                metrics.dayCount == 0 ? 0.0 : metrics.totalSpent / metrics.dayCount;
            final weeklyAverage =
                metrics.weekCount == 0 ? 0.0 : metrics.totalSpent / metrics.weekCount;
            final monthlyAverage =
                metrics.monthCount == 0 ? 0.0 : metrics.totalSpent / metrics.monthCount;

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
                        _buildProfileAvatar(appSettings.profile),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF16304B)),
                        ),
                        Text(
                          role,
                          style: const TextStyle(color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
                        ),
                        if (showActiveDateBadge) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Active record: ${RecordBookStore.dateKeyFromDate(RecordBookData.activeDate)}',
                            style: const TextStyle(color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
                          ),
                        ],
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
                              childAspectRatio: compactCards ? 1.45 : 1.2,
                              children: cards,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                      const SizedBox(height: 26),
                      if (_profileSummary != null && showQuickHints)
                        Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD3E1F6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cloud Summary',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF16304B)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Total spent: \$${((_profileSummary!['totalSpent'] as num?) ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF324A64)),
                          ),
                          Text(
                            'Remaining balance: \$${((_profileSummary!['remainingBalance'] as num?) ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF324A64)),
                          ),
                          Text(
                            'Average daily spending: \$${((_profileSummary!['averageDailySpending'] as num?) ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF324A64)),
                          ),
                          Text(
                            'Average per expense: \$${((_profileSummary!['averagePerExpense'] as num?) ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF324A64)),
                          ),
                        ],
                      ),
                        )
                      else if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingPage()),
                    ),
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
      },
    );
      },
    );
  }
}
