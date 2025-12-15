import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/chart_data.dart' as models;
import '../../themes.dart';

class ColumnChartWidget extends StatefulWidget {
  final models.ColumnChartData data;
  final bool isDarkMode;

  const ColumnChartWidget({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

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
          // Bar Chart with centered labels inside bars
          SizedBox(
            height: 250,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const leftAxisReserved = 40.0; // reservedSize for left axis
                final chartHeight = constraints.maxHeight - 20;
                final drawingWidth = constraints.maxWidth - leftAxisReserved;
                final maxY = _getMaxY();
                final barCount = widget.data.bars.length;

                return Stack(
                  children: [
                    // The bar chart
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        minY: 0,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchCallback: (FlTouchEvent event, barTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  barTouchResponse == null ||
                                  barTouchResponse.spot == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                            });
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            axisNameWidget: widget.data.xAxisLabel.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      widget.data.xAxisLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  )
                                : null,
                            sideTitles: const SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: widget.data.yAxisLabel.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      widget.data.yAxisLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  )
                                : null,
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: widget.isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: widget.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                            ),
                            bottom: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                            ),
                          ),
                        ),
                        barGroups: _buildBarGroups(),
                      ),
                    ),
                    // Centered labels inside each bar
                    ...widget.data.bars.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bar = entry.value;
                      final barHeightRatio = bar.value / maxY;
                      final barHeight = barHeightRatio * chartHeight;

                      // Skip label if bar too short
                      if (barHeight < 30) return const SizedBox.shrink();

                      // Calculate bar center using spaceAround formula
                      // spaceAround distributes: space-bar-space-bar-space
                      // Bar center = drawingWidth * (2*index + 1) / (2 * barCount)
                      final barCenterX = leftAxisReserved + drawingWidth * (2 * index + 1) / (2 * barCount);
                      const labelWidth = 20.0;
                      final left = barCenterX - labelWidth / 2;
                      final top = chartHeight - barHeight;

                      return Positioned(
                        left: left,
                        top: top,
                        width: labelWidth,
                        height: barHeight,
                        child: Container(
                          alignment: Alignment.center,
                          child: RotatedBox(
                            quarterTurns: -1,
                            child: Text(
                              bar.label,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (widget.data.bars.isEmpty) return 100;
    final maxValue = widget.data.bars
        .map((bar) => bar.value)
        .reduce((a, b) => a > b ? a : b);
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
            color: isTouched
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.8),
            width: isTouched ? 24 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: widget.isDarkMode
                  ? Colors.grey[800]!.withValues(alpha: 0.3)
                  : Colors.grey[300]!.withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    }).toList();
  }
}
