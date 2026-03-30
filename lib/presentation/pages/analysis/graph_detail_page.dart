import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/services/record_export_service.dart';
import '../recordbook/recordbookpage.dart';

enum GraphDetailChartType { pie, bar }

class GraphDetailPage extends StatelessWidget {
  const GraphDetailPage({
    super.key,
    required this.title,
    required this.periodLabel,
    required this.chartType,
    required this.categories,
    required this.total,
    this.barDivisions = 0,
  });

  final String title;
  final String periodLabel;
  final GraphDetailChartType chartType;
  final List<SpendingCategory> categories;
  final double total;
  final int barDivisions;

  static final List<Color> _seriesColors = [
    const Color(0xFF66CDD0),
    const Color(0xFF46ACC6),
    const Color(0xFF368DBB),
    const Color(0xFF2A78A9),
    const Color(0xFF1F6398),
    const Color(0xFF165285),
  ];

  Color _colorForIndex(int index) => _seriesColors[index % _seriesColors.length];

  Future<void> _export(BuildContext context) async {
    try {
      await RecordExportService.exportComputedReportPdf(
        title: title,
        subtitle: periodLabel,
        balance: RecordBookData.balance,
        categories: categories,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $error')),
      );
    }
  }

  Widget _buildChart() {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No data available for this period.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ),
      );
    }

    if (chartType == GraphDetailChartType.pie) {
      var colorIndex = 0;
      final sections = categories.map((category) {
        final percent = total == 0 ? 0.0 : (category.total / total) * 100;
        final section = PieChartSectionData(
          color: _colorForIndex(colorIndex),
          value: category.total,
          title: '${percent.toStringAsFixed(1)}%',
          radius: 84,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        );
        colorIndex++;
        return section;
      }).toList();

      return SizedBox(
        height: 230,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 18,
            sectionsSpace: 0,
          ),
        ),
      );
    }

    final groups = <BarChartGroupData>[];
    for (var index = 0; index < categories.length; index++) {
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: categories[index].total <= 0 ? 0.01 : categories[index].total,
              width: 24,
              color: _colorForIndex(index),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= categories.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      categories[index].name,
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF004AAD),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E5EC6),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ),
          const SizedBox(height: 22),
          ...List.generate(categories.length, (index) {
            final category = categories[index];
            final percent = total == 0 ? 0.0 : (category.total / total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _colorForIndex(index),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  Text(
                    '${category.total.toStringAsFixed(2)}    (${percent.toStringAsFixed(percent.truncateToDouble() == percent ? 0 : 1)}%)',
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: Colors.white54, height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                total.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Underlying Records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...categories.map((category) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD7E1EF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      Text(
                        category.total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...category.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text(item.amount.toStringAsFixed(2)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF004AAD),
        actions: [
          IconButton(
            onPressed: () => _export(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Quick export',
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: Column(
              children: [
                Text(
                  periodLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                _buildChart(),
              ],
            ),
          ),
          _buildLegendCard(),
          _buildItemsSection(),
        ],
      ),
    );
  }
}
