import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/services/app_settings_controller.dart';
import '../../../data/services/spending_analysis_service.dart';
import '../analysis/graph_detail_page.dart';
import '../recordbook/recordbookpage.dart';

class _HomeAnalyticsBundle {
  const _HomeAnalyticsBundle({
    required this.todayCategories,
    required this.yesterdayCategories,
    required this.todayTotal,
    required this.yesterdayTotal,
    required this.yesterdayCategoryTotals,
  });

  final List<SpendingCategory> todayCategories;
  final List<SpendingCategory> yesterdayCategories;
  final double todayTotal;
  final double yesterdayTotal;
  final Map<String, double> yesterdayCategoryTotals;
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  static final List<Color> _pieColors = [
    const Color(0xFF66CDD0),
    const Color(0xFF46ACC6),
    const Color(0xFF368DBB),
    const Color(0xFF2A78A9),
    const Color(0xFF1F6398),
    const Color(0xFF165285),
  ];

  late Future<_HomeAnalyticsBundle> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _loadAnalytics();
  }

  Future<_HomeAnalyticsBundle> _loadAnalytics() async {
    final activeDate = RecordBookData.activeDate;
    final yesterdayDate = activeDate.subtract(const Duration(days: 1));
    final todayStart = SpendingAnalysisService.startOfDay(activeDate);
    final todayEnd = SpendingAnalysisService.endOfDay(activeDate);
    final yesterdayStart = SpendingAnalysisService.startOfDay(yesterdayDate);
    final yesterdayEnd = SpendingAnalysisService.endOfDay(yesterdayDate);

    final todayCategories =
        await SpendingAnalysisService.historicalCategoriesInRange(todayStart, todayEnd);
    final yesterdayCategories =
        await SpendingAnalysisService.historicalCategoriesInRange(yesterdayStart, yesterdayEnd);
    final todayTotal =
        await SpendingAnalysisService.historicalTotalInRange(todayStart, todayEnd);
    final yesterdayTotal =
        await SpendingAnalysisService.historicalTotalInRange(yesterdayStart, yesterdayEnd);
    final yesterdayCategoryTotals = await SpendingAnalysisService
        .historicalCategoryTotalsInRange(yesterdayStart, yesterdayEnd);

    return _HomeAnalyticsBundle(
      todayCategories: todayCategories,
      yesterdayCategories: yesterdayCategories,
      todayTotal: todayTotal,
      yesterdayTotal: yesterdayTotal,
      yesterdayCategoryTotals: yesterdayCategoryTotals,
    );
  }

  String _trendLabel(double today, double yesterday) {
    if (today > yesterday) {
      return 'increased';
    }
    if (today < yesterday) {
      return 'decreased';
    }
    return 'remained';
  }

  IconData _trendIcon(double today, double yesterday) {
    if (today > yesterday) {
      return Icons.arrow_upward;
    }
    if (today < yesterday) {
      return Icons.arrow_downward;
    }
    return Icons.remove;
  }

  Color _trendColor(double today, double yesterday) {
    if (today > yesterday) {
      return Colors.red;
    }
    if (today < yesterday) {
      return Colors.green;
    }
    return Colors.grey.shade600;
  }

  String _topCategory(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) {
      return 'N/A';
    }
    final top = categoryTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
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
      return 'No spending yet from yesterday. Save more records to unlock stronger insights.';
    }
    if (trend == 'increased' && ratio >= 0.30) {
      return '$topCategory spending increased drastically compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%.';
    }
    if (trend == 'increased') {
      return '$topCategory spending increased compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%.';
    }
    if (trend == 'decreased' && ratio >= 0.30) {
      return '$topCategory spending decreased drastically compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%.';
    }
    if (trend == 'decreased') {
      return '$topCategory spending decreased compared to yesterday by ${(ratio * 100).toStringAsFixed(1)}%.';
    }
    return '$topCategory stayed the same compared to yesterday.';
  }

  String _currency(double value, bool showSymbol) {
    final formatted = value.toStringAsFixed(2);
    return showSymbol ? '\$$formatted' : formatted;
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

  Widget _buildYesterdayChart(
    BuildContext context,
    DateTime targetDate,
    Map<String, double> categoryTotals,
    List<SpendingCategory> categories,
  ) {
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GraphDetailPage(
              title: 'Daily Comparison Details',
              periodLabel: _formatLongDate(targetDate),
              chartType: GraphDetailChartType.pie,
              categories: categories,
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
        _analyticsFuture = _loadAnalytics();
        final activeDate = RecordBookData.activeDate;
        final settings = AppSettingsController.instance.settings.value;
        final showCurrencySymbol = settings.personalization.showCurrencySymbol;
        final showQuickHints = settings.personalization.showQuickHints;
        final showActiveDateBadge = settings.tracking.showActiveDateBadge;

        return FutureBuilder<_HomeAnalyticsBundle>(
          future: _analyticsFuture,
          builder: (context, snapshot) {
            final bundle = snapshot.data;
            final todayTotal = bundle?.todayTotal ?? 0.0;
            final yesterdayTotal = bundle?.yesterdayTotal ?? 0.0;
            final remainingBalance = math.max(RecordBookData.balance - todayTotal, 0.0);
            final trend = _trendLabel(todayTotal, yesterdayTotal);
            final trendText = trend == 'remained'
                ? 'remained the same as the previous day'
                : '$trend than the previous day';
            final topCategory = _topCategory(bundle?.yesterdayCategoryTotals ?? const {});
            final insight = _insightPlaceholder(
              today: todayTotal,
              yesterday: yesterdayTotal,
              topCategory: topCategory,
            );
            final yesterdayDate = activeDate.subtract(const Duration(days: 1));

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
                  if (showActiveDateBadge)
                    Text(
                      'Active day: ${activeDate.month}/${activeDate.day}/${activeDate.year}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ))
                  else ...[
                    Text(
                      'Current day:  ${_currency(todayTotal, showCurrencySymbol)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Previous day:  ${_currency(yesterdayTotal, showCurrencySymbol)}',
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
                      'Remaining balance:  ${_currency(remainingBalance, showCurrencySymbol)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Previous Day Analysis:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    _buildYesterdayChart(
                      context,
                      yesterdayDate,
                      bundle?.yesterdayCategoryTotals ?? const {},
                      bundle?.yesterdayCategories ?? const [],
                    ),
                    if (showQuickHints) ...[
                      const SizedBox(height: 20),
                      Text(
                        insight,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 90),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
