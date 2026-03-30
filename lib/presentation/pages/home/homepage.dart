import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/services/spending_analysis_service.dart';
import '../analysis/graph_detail_page.dart';
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

  double _sumForDay(DateTime targetDate) => SpendingAnalysisService.totalInRange(
        RecordBookData.categories,
        SpendingAnalysisService.startOfDay(targetDate),
        SpendingAnalysisService.endOfDay(targetDate),
      );

  Map<String, double> _categoryTotalsForDay(DateTime targetDate) => SpendingAnalysisService.categoryTotalsInRange(
        RecordBookData.categories,
        SpendingAnalysisService.startOfDay(targetDate),
        SpendingAnalysisService.endOfDay(targetDate),
      );

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

  String _formatLongDate(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildYesterdayChart(BuildContext context, DateTime targetDate, Map<String, double> categoryTotals) {
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

    return InkWell(
      onTap: () {
        final filteredCategories = SpendingAnalysisService.categoriesInRange(
          RecordBookData.categories,
          SpendingAnalysisService.startOfDay(targetDate),
          SpendingAnalysisService.endOfDay(targetDate),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GraphDetailPage(
              title: 'Daily Comparison Details',
              periodLabel: _formatLongDate(targetDate),
              chartType: GraphDetailChartType.pie,
              categories: filteredCategories,
              total: total,
            ),
          ),
        );
      },
      child: SizedBox(
        height: 260,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 0,
            sectionsSpace: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: RecordBookData.revision,
      builder: (context, _, __) {
        final activeDate = RecordBookData.activeDate;
        final yesterdayDate = activeDate.subtract(const Duration(days: 1));
        final todayTotal = _sumForDay(activeDate);
        final yesterdayTotal = _sumForDay(yesterdayDate);
        final trend = _trendLabel(todayTotal, yesterdayTotal);
        final trendText =
            trend == 'remained' ? 'remained the same as the previous day' : '$trend than the previous day';

        final remainingBalance = math.max(RecordBookData.balance - todayTotal, 0.0);
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
              const SizedBox(height: 8),
              Text(
                'Active day: ${activeDate.month}/${activeDate.day}/${activeDate.year}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Text(
                'Current day:  ${_currency(todayTotal)}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Previous day:  ${_currency(yesterdayTotal)}',
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
                'Previous Day Analysis:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _buildYesterdayChart(context, yesterdayDate, yesterdayCategoryTotals),
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
      },
    );
  }
}
