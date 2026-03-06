import 'package:flutter/material.dart';

import 'analysis/analysispage.dart';
import 'home/homepage.dart';
import 'profile/profilepage.dart';
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
    final titleIndex = _selectedIndex.clamp(0, _navTitles.length - 1);
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
      appBar: _selectedIndex == 3 ? null : _buildTopNavigation(),
      backgroundColor: Colors.white,
      body: _buildPageView(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}
