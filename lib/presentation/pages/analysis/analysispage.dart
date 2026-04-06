import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/services/spending_analysis_service.dart';
import 'graph_detail_page.dart';
import '../recordbook/recordbookpage.dart';

class _RangeAnalytics {
  const _RangeAnalytics({
    required this.categories,
    required this.total,
    required this.categoryTotals,
  });

  final List<SpendingCategory> categories;
  final double total;
  final Map<String, double> categoryTotals;
}

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  DateTime _dailyDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _weeklyDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _monthlyDate = DateTime(DateTime.now().year, DateTime.now().month - 1);
  DateTime _yearlyDate = DateTime(DateTime.now().year - 1);

  final List<Color> _catColors = [
    const Color(0xFF4AC2D7),
    const Color(0xFF004EC4),
    const Color(0xFF388E3C),
    const Color(0xFFFBC02D),
    const Color(0xFFE64A19),
    const Color(0xFF7B1FA2),
  ];

  Color _getCategoryColor(int index) {
    return _catColors[index % _catColors.length];
  }

  Future<_RangeAnalytics> _loadRangeAnalytics(DateTime start, DateTime end) async {
    final categories =
        await SpendingAnalysisService.historicalCategoriesInRange(start, end);
    final total = await SpendingAnalysisService.historicalTotalInRange(start, end);
    final categoryTotals =
        await SpendingAnalysisService.historicalCategoryTotalsInRange(start, end);
    return _RangeAnalytics(
      categories: categories,
      total: total,
      categoryTotals: categoryTotals,
    );
  }

  String _formatDailyDate(DateTime d) => '${_monthShort(d.month)} ${d.day}, ${d.year}';

  String _formatWeeklyDate(DateTime d) {
    final start = d.subtract(Duration(days: d.weekday % 7));
    final end = start.add(const Duration(days: 6));
    return '${_monthShort(start.month)}. ${start.day} - ${_monthShort(end.month)}. ${end.day}, ${start.year}';
  }

  String _formatMonthlyDate(DateTime d) => '${_monthLong(d.month)} ${d.year}';
  String _formatYearlyDate(DateTime d) => '${d.year}';

  String _monthShort(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  String _monthLong(int m) => [
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
        'December'
      ][m - 1];

  Future<int?> _pickYear(int initialYear) async {
    int selectedYear = initialYear;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButton<int>(
                value: selectedYear,
                isExpanded: true,
                items: List.generate(31, (i) => 2020 + i)
                    .map((year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        ))
                    .toList(),
                onChanged: (year) {
                  if (year != null) {
                    setStateDialog(() => selectedYear = year);
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedYear),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<DateTime?> _pickMonthYear(DateTime initial) async {
    int selectedMonth = initial.month;
    int selectedYear = initial.year;
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (i) => i + 1)
                        .map((month) => DropdownMenuItem<int>(
                              value: month,
                              child: Text(_monthLong(month)),
                            ))
                        .toList(),
                    onChanged: (month) {
                      if (month != null) {
                        setStateDialog(() => selectedMonth = month);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: List.generate(31, (i) => 2020 + i)
                        .map((year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                    onChanged: (year) {
                      if (year != null) {
                        setStateDialog(() => selectedYear = year);
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, DateTime(selectedYear, selectedMonth, 1)),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  DateTime _weekStartFromYearAndWeek(int year, int week) {
    final firstDay = DateTime(year, 1, 1);
    final firstSunday = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    return firstSunday.add(Duration(days: (week - 1) * 7));
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final firstSunday = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    return ((date.difference(firstSunday).inDays) ~/ 7) + 1;
  }

  Future<DateTime?> _pickWeek(DateTime initial) async {
    int selectedYear = initial.year;
    int selectedWeek = _weekOfYear(initial).clamp(1, 53);
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Week'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: List.generate(31, (i) => 2020 + i)
                        .map((year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                    onChanged: (year) {
                      if (year != null) {
                        setStateDialog(() => selectedYear = year);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: selectedWeek,
                    isExpanded: true,
                    items: List.generate(53, (i) => i + 1)
                        .map((week) => DropdownMenuItem<int>(
                              value: week,
                              child: Text('Week $week'),
                            ))
                        .toList(),
                    onChanged: (week) {
                      if (week != null) {
                        setStateDialog(() => selectedWeek = week);
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _weekStartFromYearAndWeek(selectedYear, selectedWeek)),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF16304B),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF16304B)),
        ],
      ),
    );
  }

  void _openDetailPage({
    required String title,
    required String periodLabel,
    required GraphDetailChartType chartType,
    required _RangeAnalytics analytics,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GraphDetailPage(
          title: title,
          periodLabel: periodLabel,
          chartType: chartType,
          categories: analytics.categories,
          total: analytics.total,
        ),
      ),
    );
  }

  Widget _buildDailyPieChart(
    DateTime date,
    _RangeAnalytics analytics,
  ) {
    final catData = analytics.categoryTotals;
    if (catData.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('No spent', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    int i = 0;
    final sections = catData.entries.map((e) {
      final color = _getCategoryColor(i++);
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '',
        radius: 40,
      );
    }).toList();

    return InkWell(
      onTap: () => _openDetailPage(
        title: 'Daily Comparison Details',
        periodLabel: _formatDailyDate(date),
        chartType: GraphDetailChartType.pie,
        analytics: analytics,
      ),
        child: SizedBox(
          height: 120,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 20,
              sectionsSpace: 0,
              pieTouchData: PieTouchData(enabled: true),
            ),
          ),
        ),
    );
  }

  Widget _buildBarChart(
    DateTime start,
    DateTime end,
    int divisions,
    String detailLabel,
    _RangeAnalytics analytics,
  ) {
    final inclusiveDays = end.difference(start).inDays + 1;
    final divDuration = inclusiveDays ~/ divisions;
    if (divDuration == 0) {
      return const SizedBox(height: 150);
    }

    List<BarChartGroupData> groups = [];
    final cats = analytics.categories.map((c) => c.name).toList();
    final catColorMap = {for (var i = 0; i < cats.length; i++) cats[i]: _getCategoryColor(i)};

    for (int i = 0; i < divisions; i++) {
      final dStart = start.add(Duration(days: i * divDuration));
      final dEnd = i == divisions - 1
          ? end
          : dStart.add(Duration(days: divDuration - 1, hours: 23, minutes: 59));

      final cData = SpendingAnalysisService.categoryTotalsInRange(
        analytics.categories,
        dStart,
        dEnd,
      );

      List<BarChartRodStackItem> stackItems = [];
      double yAcc = 0;
      for (var c in cats) {
        final v = cData[c] ?? 0;
        if (v > 0) {
          stackItems.add(BarChartRodStackItem(yAcc, yAcc + v, catColorMap[c]!));
          yAcc += v;
        }
      }

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: yAcc > 0 ? yAcc : 0.01,
              width: 14,
              color: Colors.transparent,
              borderRadius: BorderRadius.zero,
              rodStackItems: stackItems.isNotEmpty
                  ? stackItems
                  : [BarChartRodStackItem(0, 0.01, Colors.transparent)],
            )
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openDetailPage(
        title: 'Comparison Details',
        periodLabel: detailLabel,
        chartType: GraphDetailChartType.bar,
        analytics: analytics,
      ),
      child: SizedBox(
        height: 150,
        child: BarChart(
          BarChartData(
            barGroups: groups,
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                getTooltipColor: (_) => const Color(0xFF16304B),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final segmentIndex = group.x.toInt().clamp(0, groups.length - 1);
                  final segmentStart = start.add(Duration(days: segmentIndex * divDuration));
                  final segmentEnd = segmentIndex == divisions - 1
                      ? end
                      : segmentStart.add(
                          Duration(days: divDuration - 1, hours: 23, minutes: 59),
                        );
                  return BarTooltipItem(
                    '${_monthShort(segmentStart.month)} ${segmentStart.day} - '
                    '${_monthShort(segmentEnd.month)} ${segmentEnd.day}\n'
                    '${rod.toY.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'W${val.toInt() + 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF4A6078),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required Widget leftControl,
    required Future<_RangeAnalytics> leftFuture,
    required String rightTitle,
    required Future<_RangeAnalytics> rightFuture,
    required Widget Function(_RangeAnalytics data) leftChartBuilder,
    required Widget Function(_RangeAnalytics data) rightChartBuilder,
    required Widget Function(double leftTotal, double rightTotal) trendBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: FutureBuilder<List<_RangeAnalytics>>(
        future: Future.wait([leftFuture, rightFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final leftData = snapshot.data![0];
          final rightData = snapshot.data![1];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    leftControl,
                    const SizedBox(height: 16),
                    leftChartBuilder(leftData),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rightTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF16304B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        trendBuilder(leftData.total, rightData.total),
                      ],
                    ),
                    const SizedBox(height: 16),
                    rightChartBuilder(rightData),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrendBadge(double leftTotal, double rightTotal) {
    final diff = rightTotal - leftTotal;
    final isDown = diff < 0;
    final isUp = diff > 0;
    final trendMessage = isUp
        ? 'Spending Increased'
        : isDown
            ? 'Spending Decreased'
            : 'No Changes';

    if (leftTotal <= 0 && rightTotal <= 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trendMessage),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Icon(
        isDown ? Icons.arrow_downward : Icons.arrow_upward,
        color: isDown ? Colors.green : Colors.red,
        size: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: RecordBookData.revision,
      builder: (context, _, __) {
        final totalSpent = RecordBookData.categories
            .expand((category) => category.items)
            .fold<double>(0.0, (sum, item) => sum + item.amount);
        final rawProgress =
            RecordBookData.balance > 0 ? totalSpent / RecordBookData.balance : 0.0;
        final clampedProgress = rawProgress.clamp(0.0, 1.0).toDouble();
        final progressPercent = (clampedProgress * 100).toStringAsFixed(2);
        final progressColor = clampedProgress >= 1.0 ? Colors.red : Colors.blue;
        final today = RecordBookData.activeDate;

        final dailyStart = DateTime(_dailyDate.year, _dailyDate.month, _dailyDate.day);
        final dailyEnd = DateTime(_dailyDate.year, _dailyDate.month, _dailyDate.day, 23, 59, 59);
        final activeDailyStart = DateTime(today.year, today.month, today.day);
        final activeDailyEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

        final selWeekStart = _weeklyDate.subtract(Duration(days: _weeklyDate.weekday % 7));
        final selWeekEnd = selWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
        final thisWeekStart = today.subtract(Duration(days: today.weekday % 7));
        final thisWeekEnd = thisWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59));

        final selMonthStart = DateTime(_monthlyDate.year, _monthlyDate.month, 1);
        final selMonthEnd = DateTime(_monthlyDate.year, _monthlyDate.month + 1, 0, 23, 59, 59);
        final thisMonthStart = DateTime(today.year, today.month, 1);
        final thisMonthEnd = DateTime(today.year, today.month + 1, 0, 23, 59, 59);

        final selYearStart = DateTime(_yearlyDate.year, 1, 1);
        final selYearEnd = DateTime(_yearlyDate.year, 12, 31, 23, 59, 59);
        final thisYearStart = DateTime(today.year, 1, 1);
        final thisYearEnd = DateTime(today.year, 12, 31, 23, 59, 59);

        return Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending Progress',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF16304B)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16304B)),
                    ),
                    Text(
                      'for ${_monthShort(today.month)} ${today.day}, ${today.year}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: clampedProgress,
                    minHeight: 10,
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${totalSpent.toStringAsFixed(2)} / ${RecordBookData.balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Spending Comparison',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF16304B)),
                ),
                const SizedBox(height: 24),
                _buildComparisonRow(
                  leftControl: _buildDateSelector(_formatDailyDate(_dailyDate), () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dailyDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _dailyDate = picked);
                    }
                  }),
                  leftFuture: _loadRangeAnalytics(dailyStart, dailyEnd),
                  rightTitle: 'Active Day',
                  rightFuture: _loadRangeAnalytics(activeDailyStart, activeDailyEnd),
                  leftChartBuilder: (data) => _buildDailyPieChart(_dailyDate, data),
                  rightChartBuilder: (data) => _buildDailyPieChart(today, data),
                  trendBuilder: _buildTrendBadge,
                ),
                _buildComparisonRow(
                  leftControl: _buildDateSelector(_formatWeeklyDate(_weeklyDate), () async {
                    final picked = await _pickWeek(_weeklyDate);
                    if (picked != null) {
                      setState(() => _weeklyDate = picked);
                    }
                  }),
                  leftFuture: _loadRangeAnalytics(selWeekStart, selWeekEnd),
                  rightTitle: 'Active Week',
                  rightFuture: _loadRangeAnalytics(thisWeekStart, thisWeekEnd),
                  leftChartBuilder: (data) =>
                      _buildBarChart(selWeekStart, selWeekEnd, 7, _formatWeeklyDate(_weeklyDate), data),
                  rightChartBuilder: (data) =>
                      _buildBarChart(thisWeekStart, thisWeekEnd, 7, _formatWeeklyDate(today), data),
                  trendBuilder: _buildTrendBadge,
                ),
                _buildComparisonRow(
                  leftControl: _buildDateSelector(_formatMonthlyDate(_monthlyDate), () async {
                    final picked = await _pickMonthYear(_monthlyDate);
                    if (picked != null) {
                      setState(() => _monthlyDate = picked);
                    }
                  }),
                  leftFuture: _loadRangeAnalytics(selMonthStart, selMonthEnd),
                  rightTitle: 'Active Month',
                  rightFuture: _loadRangeAnalytics(thisMonthStart, thisMonthEnd),
                  leftChartBuilder: (data) =>
                      _buildBarChart(selMonthStart, selMonthEnd, 4, _formatMonthlyDate(_monthlyDate), data),
                  rightChartBuilder: (data) =>
                      _buildBarChart(thisMonthStart, thisMonthEnd, 4, _formatMonthlyDate(today), data),
                  trendBuilder: _buildTrendBadge,
                ),
                _buildComparisonRow(
                  leftControl: _buildDateSelector(_formatYearlyDate(_yearlyDate), () async {
                    final pickedYear = await _pickYear(_yearlyDate.year);
                    if (pickedYear != null) {
                      setState(() => _yearlyDate = DateTime(pickedYear, 1, 1));
                    }
                  }),
                  leftFuture: _loadRangeAnalytics(selYearStart, selYearEnd),
                  rightTitle: 'Active Year',
                  rightFuture: _loadRangeAnalytics(thisYearStart, thisYearEnd),
                  leftChartBuilder: (data) =>
                      _buildBarChart(selYearStart, selYearEnd, 12, _formatYearlyDate(_yearlyDate), data),
                  rightChartBuilder: (data) =>
                      _buildBarChart(thisYearStart, thisYearEnd, 12, _formatYearlyDate(today), data),
                  trendBuilder: _buildTrendBadge,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }
}
