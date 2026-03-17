import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../recordbook/recordbookpage.dart';

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

  double _getTotalSpent() {
    double total = 0;
    for (var c in RecordBookData.categories) {
      for (var i in c.items) {
        total += i.amount;
      }
    }
    return total;
  }

  double _getSpentInRange(DateTime start, DateTime end) {
    double total = 0;
    for (var c in RecordBookData.categories) {
      for (var i in c.items) {
        if (i.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
            i.date.isBefore(end.add(const Duration(seconds: 1)))) {
          total += i.amount;
        }
      }
    }
    return total;
  }

  Map<String, double> _getCategorySpentInRange(DateTime start, DateTime end) {
    final map = <String, double>{};
    for (var c in RecordBookData.categories) {
      double t = 0;
      for (var i in c.items) {
        if (i.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
            i.date.isBefore(end.add(const Duration(seconds: 1)))) {
          t += i.amount;
        }
      }
      if (t > 0) map[c.name] = t;
    }
    return map;
  }

  String _formatDailyDate(DateTime d) => '${_monthShort(d.month)} ${d.day}, ${d.year}';
  String _formatWeeklyDate(DateTime d) {
    final start = d.subtract(Duration(days: d.weekday % 7));
    final end = start.add(const Duration(days: 6));
    return '${_monthShort(start.month)}. ${start.day} - ${_monthShort(end.month)}. ${end.day}, ${start.year}';
  }
  String _formatMonthlyDate(DateTime d) => '${_monthLong(d.month)} ${d.year}';
  String _formatYearlyDate(DateTime d) => '${d.year}';
  
  String _monthShort(int m) => ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m-1];
  String _monthLong(int m) => ["January","February","March","April","May","June","July","August","September","October","November","December"][m-1];

  Widget _buildDateSelector(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildDailyPieChart(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final catData = _getCategorySpentInRange(start, end);
    
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

    return SizedBox(
      height: 120,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 20,
          sectionsSpace: 0,
        ),
      ),
    );
  }

  Widget _buildBarChart(DateTime start, DateTime end, int divisions) {
    final duration = end.difference(start);
    final divDuration = duration.inDays ~/ divisions;
    if (divDuration == 0) return const SizedBox(height: 150);
    
    List<BarChartGroupData> groups = [];
    final cats = RecordBookData.categories.map((c) => c.name).toList();
    final catColorMap = {for (var i=0; i<cats.length; i++) cats[i]: _getCategoryColor(i)};

    for (int i = 0; i < divisions; i++) {
        final dStart = start.add(Duration(days: i * divDuration));
        final dEnd = i == divisions - 1 ? end : dStart.add(Duration(days: divDuration - 1, hours: 23, minutes: 59));
        
        final cData = _getCategorySpentInRange(dStart, dEnd);
        
        List<BarChartRodStackItem> stackItems = [];
        double yAcc = 0;
        for (var c in cats) {
            double v = cData[c] ?? 0;
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
                        rodStackItems: stackItems.isNotEmpty ? stackItems : [BarChartRodStackItem(0, 0.01, Colors.transparent)],
                    )
                ]
            )
        );
    }
    
    return SizedBox(
        height: 150,
        child: BarChart(
            BarChartData(
                barGroups: groups,
                borderData: FlBorderData(show: false),
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
                                    child: Text('W${val.toInt()+1}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                );
                            }
                        )
                    )
                ),
                gridData: const FlGridData(show: false),
            )
        )
    );
  }

  Widget _buildComparisonRow({
    required Widget leftControl,
    required Widget leftChart,
    required String rightTitle,
    required Widget rightChart,
    required double leftTotal,
    required double rightTotal,
  }) {
    final diff = rightTotal - leftTotal;
    final isUp = diff >= 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                leftControl,
                const SizedBox(height: 16),
                leftChart,
              ],
            )
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(rightTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 4),
                    if (leftTotal > 0 || rightTotal > 0)
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isUp ? Colors.red : Colors.green,
                        size: 14,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                rightChart,
              ],
            )
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _getTotalSpent();
    final today = DateTime.now();

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spending Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('${totalSpent > 0 && RecordBookData.balance > 0 ? (totalSpent/RecordBookData.balance*100).toStringAsFixed(2) : 0}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                 Text('until ${_monthShort(RecordBookData.endDate.month)} ${RecordBookData.endDate.day}, ${RecordBookData.endDate.year}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: RecordBookData.balance > 0 ? (totalSpent / RecordBookData.balance).clamp(0.0, 1.0) : 0.0,
                minHeight: 10,
                backgroundColor: Colors.blue.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('${totalSpent.toStringAsFixed(2)} / ${RecordBookData.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
            const SizedBox(height: 32),
            const Text('Spending Comparison', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Daily
            _buildComparisonRow(
               leftControl: _buildDateSelector(_formatDailyDate(_dailyDate), () async {
                  final picked = await showDatePicker(context: context, initialDate: _dailyDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _dailyDate = picked);
               }),
               leftChart: _buildDailyPieChart(_dailyDate),
               rightTitle: 'Today',
               rightChart: _buildDailyPieChart(today),
               leftTotal: _getSpentInRange(DateTime(_dailyDate.year, _dailyDate.month, _dailyDate.day), DateTime(_dailyDate.year, _dailyDate.month, _dailyDate.day, 23, 59, 59)),
               rightTotal: _getSpentInRange(DateTime(today.year, today.month, today.day), DateTime(today.year, today.month, today.day, 23, 59, 59)),
            ),
            
            // Weekly
            Builder(builder: (context) {
              final selWeekStart = _weeklyDate.subtract(Duration(days: _weeklyDate.weekday % 7));
              final selWeekEnd = selWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
              final thisWeekStart = today.subtract(Duration(days: today.weekday % 7));
              final thisWeekEnd = thisWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
              
              return _buildComparisonRow(
                 leftControl: _buildDateSelector(_formatWeeklyDate(_weeklyDate), () async {
                    final picked = await showDatePicker(context: context, initialDate: _weeklyDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setState(() => _weeklyDate = picked);
                 }),
                 leftChart: _buildBarChart(selWeekStart, selWeekEnd, 7),
                 rightTitle: 'This Week',
                 rightChart: _buildBarChart(thisWeekStart, thisWeekEnd, 7),
                 leftTotal: _getSpentInRange(selWeekStart, selWeekEnd),
                 rightTotal: _getSpentInRange(thisWeekStart, thisWeekEnd),
              );
            }),

            // Monthly
            Builder(builder: (context) {
              final selMonthStart = DateTime(_monthlyDate.year, _monthlyDate.month, 1);
              final selMonthEnd = DateTime(_monthlyDate.year, _monthlyDate.month + 1, 0, 23, 59, 59);
              final thisMonthStart = DateTime(today.year, today.month, 1);
              final thisMonthEnd = DateTime(today.year, today.month + 1, 0, 23, 59, 59);
              
              return _buildComparisonRow(
                 leftControl: _buildDateSelector(_formatMonthlyDate(_monthlyDate), () async {
                    final picked = await showDatePicker(context: context, initialDate: _monthlyDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setState(() => _monthlyDate = picked);
                 }),
                 leftChart: _buildBarChart(selMonthStart, selMonthEnd, 4), // 4 weeks approximation
                 rightTitle: 'This Month',
                 rightChart: _buildBarChart(thisMonthStart, thisMonthEnd, 4),
                 leftTotal: _getSpentInRange(selMonthStart, selMonthEnd),
                 rightTotal: _getSpentInRange(thisMonthStart, thisMonthEnd),
              );
            }),

            // Yearly
            Builder(builder: (context) {
              final selYearStart = DateTime(_yearlyDate.year, 1, 1);
              final selYearEnd = DateTime(_yearlyDate.year, 12, 31, 23, 59, 59);
              final thisYearStart = DateTime(today.year, 1, 1);
              final thisYearEnd = DateTime(today.year, 12, 31, 23, 59, 59);
              
              return _buildComparisonRow(
                 leftControl: _buildDateSelector(_formatYearlyDate(_yearlyDate), () async {
                    // For yearly we could pick a full year. Using date picker is fine, we just use the year part.
                    final picked = await showDatePicker(context: context, initialDate: _yearlyDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setState(() => _yearlyDate = picked);
                 }),
                 leftChart: _buildBarChart(selYearStart, selYearEnd, 12), // 12 months
                 rightTitle: 'This Year',
                 rightChart: _buildBarChart(thisYearStart, thisYearEnd, 12),
                 leftTotal: _getSpentInRange(selYearStart, selYearEnd),
                 rightTotal: _getSpentInRange(thisYearStart, thisYearEnd),
              );
            }),
            
            const SizedBox(height: 100), // bottom spacing
          ],
        ),
      ),
    );
  }
}
