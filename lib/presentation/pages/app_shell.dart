import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/app_settings_controller.dart';
import 'analysis/analysispage.dart';
import 'home/homepage.dart';
import 'profile/profilepage.dart';
import 'recordbook/recordbookpage.dart';
import 'signin_or_signup/loginpage.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _navTitles = ['Home', 'Record Book', 'Analysis', 'Profile'];
  static const _bottomIcons = [
    Icons.home,
    Icons.add,
    Icons.bar_chart,
    Icons.person,
  ];

  late final PageController _pageController;
  late int _selectedIndex;

  final List<Widget> _pageBodies = [
    HomePageContent(),
    RecordBookPage(),
    AnalysisPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    final defaultIndex =
        AppSettingsController.instance.settings.value.personalization.startPageIndex;
    _selectedIndex =
        (widget.initialIndex ?? defaultIndex).clamp(0, _pageBodies.length - 1) as int;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  Future<void> _refreshPage() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  void _setPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildTopNavigation() {
    final titleIndex = _selectedIndex.clamp(0, _navTitles.length - 1) as int;
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              _navTitles[titleIndex],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF002D72),
              ),
            )
          )
        )
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pageBodies.length,
      onPageChanged: (index) => setState(() => _selectedIndex = index),
      itemBuilder: (context, index) {
        return RefreshIndicator(
          onRefresh: _refreshPage,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _pageBodies[index],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(28, 12, 28, 12 + bottomInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_bottomIcons.length, (index) {
          final isActive = index == _selectedIndex;
          return GestureDetector(
            onTap: () => _setPage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF002D72) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _bottomIcons[index],
                color: isActive ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF004AAD),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Logo.png',
                  width: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'SGUARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: _selectedIndex == 0,
            onTap: () {
              _setPage(0);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Record Book'),
            selected: _selectedIndex == 1,
            onTap: () {
              _setPage(1);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Analysis'),
            selected: _selectedIndex == 2,
            onTap: () {
              _setPage(2);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            selected: _selectedIndex == 3,
            onTap: () {
              _setPage(3);
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final requireConfirm = AppSettingsController
        .instance.settings.value.tracking.confirmResetSensitiveActions;
    if (!requireConfirm) {
      return true;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Application'),
        content: const Text('Are you sure you want to exit without saving to sync?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: _buildDrawer(),
        appBar: _selectedIndex == 3 ? null : _buildTopNavigation(),
        backgroundColor: Colors.white,
        body: _buildPageView(),
        bottomNavigationBar: _buildBottomNavigation(context),
      ),
    );
  }
}
