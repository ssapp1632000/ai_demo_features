import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/chart_data.dart' as models;

class PieChartWidget extends StatefulWidget {
  final models.PieChartData data;
  final bool isDarkMode;

  const PieChartWidget({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Title
          if (widget.data.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.data.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          // Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildSections(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = widget.data.sections.fold<double>(
      0,
      (sum, section) => sum + section.value,
    );

    return widget.data.sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      final percentage = (section.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: section.getColor(),
        value: section.value,
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black45,
              blurRadius: 2,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.data.sections.map((section) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: section.getColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${section.label}: ${section.value}',
              style: TextStyle(
                fontSize: 13,
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
