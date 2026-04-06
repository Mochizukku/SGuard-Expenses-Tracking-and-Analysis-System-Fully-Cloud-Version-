import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/services/record_export_service.dart';
import '../recordbook/recordbookpage.dart';

enum GraphDetailChartType { pie, bar }

class GraphDetailPage extends StatefulWidget {
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

  @override
  State<GraphDetailPage> createState() => _GraphDetailPageState();
}

class _GraphDetailPageState extends State<GraphDetailPage> {
  int _touchedIndex = -1;

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
        title: widget.title,
        subtitle: widget.periodLabel,
        balance: RecordBookData.balance,
        categories: widget.categories,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $error')),
      );
    }
  }

  Widget _buildChart() {
    if (widget.categories.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No data available for this period.',
            style: TextStyle(color: Color(0xFF4A6078), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (widget.chartType == GraphDetailChartType.pie) {
      final sections = <PieChartSectionData>[];
      for (var index = 0; index < widget.categories.length; index++) {
        final category = widget.categories[index];
        final percent = widget.total == 0 ? 0.0 : (category.total / widget.total) * 100;
        final isSelected = _touchedIndex == index;
        sections.add(
          PieChartSectionData(
            color: _colorForIndex(index),
            value: category.total,
            title: '${percent.toStringAsFixed(1)}%',
            radius: isSelected ? 92 : 82,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        );
      }

      return SizedBox(
        height: 230,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 18,
            sectionsSpace: 2,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions ||
                    response?.touchedSection == null) {
                  setState(() => _touchedIndex = -1);
                  return;
                }
                setState(
                  () => _touchedIndex =
                      response!.touchedSection!.touchedSectionIndex,
                );
              },
            ),
          ),
        ),
      );
    }

    final groups = <BarChartGroupData>[];
    for (var index = 0; index < widget.categories.length; index++) {
      groups.add(
        BarChartGroupData(
          x: index,
          showingTooltipIndicators: _touchedIndex == index ? [0] : const [],
          barRods: [
            BarChartRodData(
              toY: widget.categories[index].total <= 0 ? 0.01 : widget.categories[index].total,
              width: 24,
              color: _colorForIndex(index),
              borderRadius: BorderRadius.circular(6),
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: widget.total <= 0 ? 1 : widget.total / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFD9E4F2),
              strokeWidth: 1,
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipColor: (_) => const Color(0xFF16304B),
              getTooltipItem: (group, _, rod, __) {
                final category = widget.categories[group.x.toInt()];
                return BarTooltipItem(
                  '${category.name}\n${category.total.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                );
              },
            ),
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions ||
                  response?.spot == null) {
                setState(() => _touchedIndex = -1);
                return;
              }
              setState(() => _touchedIndex = response!.spot!.touchedBarGroupIndex);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= widget.categories.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.categories[index].name,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF4A6078),
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildSelectionCard() {
    if (_touchedIndex < 0 || _touchedIndex >= widget.categories.length) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD7E1EF)),
        ),
        child: const Text(
          'Tap a chart section to inspect a category.',
          style: TextStyle(color: Color(0xFF324A64), fontWeight: FontWeight.w600),
        ),
      );
    }

    final category = widget.categories[_touchedIndex];
    final percent = widget.total == 0 ? 0.0 : (category.total / widget.total) * 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E1EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _colorForIndex(_touchedIndex),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${category.name}: ${category.total.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)',
              style: const TextStyle(
                color: Color(0xFF16304B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E1EF)),
      ),
      child: Column(
        children: [
          ...List.generate(widget.categories.length, (index) {
            final category = widget.categories[index];
            final percent = widget.total == 0 ? 0.0 : (category.total / widget.total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _colorForIndex(index),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: Color(0xFF16304B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${category.total.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      color: Color(0xFF324A64),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: Color(0xFFD7E1EF), height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Color(0xFF16304B),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                widget.total.toStringAsFixed(2),
                style: const TextStyle(
                  color: Color(0xFF16304B),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Underlying Records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF16304B)),
          ),
          const SizedBox(height: 12),
          ...widget.categories.map((category) {
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF16304B),
                          ),
                        ),
                      ),
                      Text(
                        category.total.toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF16304B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...category.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Color(0xFF324A64),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            item.amount.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Color(0xFF324A64),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
        title: Text(widget.title),
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
                  widget.periodLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16304B),
                  ),
                ),
                const SizedBox(height: 18),
                _buildChart(),
                const SizedBox(height: 16),
                _buildSelectionCard(),
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
