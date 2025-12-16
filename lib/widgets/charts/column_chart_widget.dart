import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/chart_data.dart' as models;
import '../../themes.dart';

class ColumnChartWidget extends StatefulWidget {
  final models.ColumnChartData data;
  final bool isDarkMode;

  const ColumnChartWidget({super.key, required this.data, required this.isDarkMode});

  @override
  State<ColumnChartWidget> createState() => _ColumnChartWidgetState();
}

class _ColumnChartWidgetState extends State<ColumnChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          // Bar Chart with labels below x-axis
          SizedBox(
            height: 400,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: false,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    // Only handle tap up events (completed taps)
                    if (event is! FlTapUpEvent) return;

                    setState(() {
                      if (barTouchResponse == null || barTouchResponse.spot == null) {
                        return;
                      }
                      final tappedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                      // Toggle: if same bar tapped, hide; otherwise show new one
                      if (touchedIndex == tappedIndex) {
                        touchedIndex = -1;
                      } else {
                        touchedIndex = tappedIndex;
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: widget.data.xAxisLabel.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.data.xAxisLabel,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          )
                        : null,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 100,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.bars.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              widget.data.bars[index].label,
                              style: TextStyle(fontSize: 11, color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: widget.data.yAxisLabel.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              widget.data.yAxisLabel,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          )
                        : null,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 11, color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxY() / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                    bottom: BorderSide(color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                  ),
                ),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (widget.data.bars.isEmpty) return 100;
    final maxValue = widget.data.bars.map((bar) => bar.value).reduce((a, b) => a > b ? a : b);
    // Add 20% padding to the top
    return (maxValue * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _buildBarGroups() {
    return widget.data.bars.asMap().entries.map((entry) {
      final index = entry.key;
      final bar = entry.value;
      final isTouched = index == touchedIndex;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: bar.value,
            color: isTouched ? AppColors.primary : AppColors.primary.withValues(alpha: 0.8),
            width: isTouched ? 24 : 20,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: widget.isDarkMode ? Colors.grey[800]!.withValues(alpha: 0.3) : Colors.grey[300]!.withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    }).toList();
  }
}
