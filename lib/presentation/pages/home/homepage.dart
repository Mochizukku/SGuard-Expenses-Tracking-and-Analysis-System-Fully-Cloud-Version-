import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../recordbook/recordbookpage.dart';

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  static final List<Color> _pieColors = [
    const Color(0xFF66CDD0),
    const Color(0xFF46ACC6),
    const Color(0xFF368DBB),
    const Color(0xFF2A78A9),
    const Color(0xFF1F6398),
    const Color(0xFF165285),
  ];

  double _sumForDay(DateTime targetDate) {
    double total = 0.0;
    for (final category in RecordBookData.categories) {
      for (final item in category.items) {
        if (_isSameDay(item.date, targetDate)) {
          total += item.amount;
        }
      }
    }
    return total;
  }

  Map<String, double> _categoryTotalsForDay(DateTime targetDate) {
    final totals = <String, double>{};
    for (final category in RecordBookData.categories) {
      double subtotal = 0.0;
      for (final item in category.items) {
        if (_isSameDay(item.date, targetDate)) {
          subtotal += item.amount;
        }
      }
      if (subtotal > 0) {
        totals[category.name] = subtotal;
      }
    }
    return totals;
  }

  double _totalWithinBalanceDuration() {
    final start = DateTime(
      RecordBookData.startDate.year,
      RecordBookData.startDate.month,
      RecordBookData.startDate.day,
    );
    final end = DateTime(
      RecordBookData.endDate.year,
      RecordBookData.endDate.month,
      RecordBookData.endDate.day,
      23,
      59,
      59,
    );

    double total = 0.0;
    for (final category in RecordBookData.categories) {
      for (final item in category.items) {
        if (!item.date.isBefore(start) && !item.date.isAfter(end)) {
          total += item.amount;
        }
      }
    }
    return total;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _trendLabel(double today, double yesterday) {
    if (today > yesterday) return 'increased';
    if (today < yesterday) return 'decreased';
    return 'remained';
  }

  IconData _trendIcon(double today, double yesterday) {
    if (today > yesterday) return Icons.arrow_upward;
    if (today < yesterday) return Icons.arrow_downward;
    return Icons.remove;
  }

  Color _trendColor(double today, double yesterday) {
    if (today > yesterday) return Colors.red;
    if (today < yesterday) return Colors.green;
    return Colors.grey.shade600;
  }

  String _topCategory(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) {
      return 'N/A';
    }
    final top = categoryTotals.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return top.key;
  }

  String _insightPlaceholder({
    required double today,
    required double yesterday,
    required String topCategory,
  }) {
    final trend = _trendLabel(today, yesterday);
    final ratio = yesterday > 0 ? ((today - yesterday).abs() / yesterday) : 0.0;

    if (today == 0 && yesterday == 0) {
      return 'No spending yet from yesterday. Sign up for notifications to get insights from your yesterday\'s spending';
    }
    if (trend == 'increased' && ratio >= 0.30) {
      return '$topCategory spending increased drastically compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%. Consider reviewing your expenses in this category.';
    }
    if (trend == 'increased') {
      return '$topCategory spending increased significantly compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%.';
    }
    if (trend == 'decreased' && ratio >= 0.30) {
      return '$topCategory spending decreased drastically compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%.';
    }
    if (trend == 'decreased') {
      return '$topCategory spending decreased significantly compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%.';
    }
    return '$topCategory stayed the same and nothing changed compared to yesterday.';
  }

  String _currency(double value) {
    return value.toStringAsFixed(2);
  }

  Widget _buildYesterdayChart(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No spending data for yesterday.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    final total = categoryTotals.values.fold<double>(0.0, (a, b) => a + b);
    int colorIndex = 0;
    final sections = categoryTotals.entries.map((entry) {
      final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
      final section = PieChartSectionData(
        color: _pieColors[colorIndex % _pieColors.length],
        value: entry.value,
        radius: 92,
        title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        titlePositionPercentageOffset: 1.15,
      );
      colorIndex++;
      return section;
    }).toList();

    return SizedBox(
      height: 260,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 0,
          sectionsSpace: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterdayDate = now.subtract(const Duration(days: 1));

    final todayTotal = _sumForDay(now);
    final yesterdayTotal = _sumForDay(yesterdayDate);
    final trend = _trendLabel(todayTotal, yesterdayTotal);
    final trendText = trend == 'remained'
        ? 'remained the same as yesterday'
        : '$trend than yesterday';

    final spentInDuration = _totalWithinBalanceDuration();
    final remainingBalance = math.max(
      RecordBookData.balance - spentInDuration,
      0.0,
    );
    final yesterdayCategoryTotals = _categoryTotalsForDay(yesterdayDate);
    final topCategory = _topCategory(yesterdayCategoryTotals);
    final insight = _insightPlaceholder(
      today: todayTotal,
      yesterday: yesterdayTotal,
      topCategory: topCategory,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Home',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Icon(
                Icons.search,
                size: 30,
                color: Colors.black.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.more_vert,
                size: 30,
                color: Colors.black.withValues(alpha: 0.85),
              ),
            ],
          ),
          const Divider(height: 28),
          const SizedBox(height: 6),
          const Text(
            'Total Spending',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Text(
            'Today:  ${_currency(todayTotal)}',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Yesterday:  ${_currency(yesterdayTotal)}',
            style: const TextStyle(fontSize: 16),
          ),
          Row(
            children: [
              const Text('Trends: ', style: TextStyle(fontSize: 16)),
              Icon(
                _trendIcon(todayTotal, yesterdayTotal),
                color: _trendColor(todayTotal, yesterdayTotal),
                size: 18,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(trendText, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          Text(
            'Remaining balance:  ${_currency(remainingBalance)}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 26),
          const Text(
            'Yesterday\'s Analysis:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildYesterdayChart(yesterdayCategoryTotals),
          const SizedBox(height: 20),
          Text(
            insight,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
