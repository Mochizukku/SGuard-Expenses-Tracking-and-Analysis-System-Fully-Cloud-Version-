import 'package:flutter/material.dart';

import 'analysis/analysispage.dart';
import 'home/homepage.dart';
import 'profile/profile_page.dart';
import 'recordbook/recordbookpage.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _navTitles = ['Home', 'Record Book', 'Analysis'];
  static const _bottomIcons = [
    Icons.home,
    Icons.add,
    Icons.bar_chart,
    Icons.person,
  ];

  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<Widget> _pageBodies = [
    HomePageContent(),
    RecordBookPage(),
    AnalysisPage(),
    ProfilePage(),
  ];

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
    if (_selectedIndex >= _pageBodies.length - 1) {
      return AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 4,
      );
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(78),
      child: Material(
        elevation: 4,
        child: SafeArea(
          bottom: false,
          child: Container(
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
            child: Row(
              children: List.generate(_navTitles.length, (index) {
                final isActive = index == _selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _setPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF002D72) : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? Colors.blueAccent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _navTitles[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
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

  Widget _buildBottomNavigation() {
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
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopNavigation(),
      backgroundColor: Colors.white,
      body: _buildPageView(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}
