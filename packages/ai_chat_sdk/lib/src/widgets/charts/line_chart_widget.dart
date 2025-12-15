import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/chart_data.dart' as models;

class LineChartWidget extends StatefulWidget {
  final models.LineChartData data;
  final bool isDarkMode;

  const LineChartWidget({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  List<int> touchedSpots = [];

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
          // Line Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.lineBarSpots == null) {
                        touchedSpots = [];
                        return;
                      }
                      touchedSpots = response.lineBarSpots!
                          .map((spot) => spot.spotIndex)
                          .toList();
                    });
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => widget.isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[700]!,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final line = widget.data.lines[barSpot.barIndex];
                        return LineTooltipItem(
                          '${line.label}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'X: ${barSpot.x.toInt()}, Y: ${barSpot.y.toInt()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: _getYInterval(),
                  verticalInterval: _getXInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: widget.isDarkMode
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: widget.isDarkMode
                          ? Colors.grey[700]!.withOpacity(0.5)
                          : Colors.grey[300]!.withOpacity(0.5),
                      strokeWidth: 1,
                    );
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getXInterval(),
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
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
                      interval: _getYInterval(),
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
                minX: _getMinX(),
                maxX: _getMaxX(),
                minY: 0,
                maxY: _getMaxY(),
                lineBarsData: _buildLineBarData(),
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

  double _getMinX() {
    if (widget.data.lines.isEmpty) return 0;
    double minX = double.infinity;
    for (var line in widget.data.lines) {
      if (line.points.isNotEmpty) {
        final lineMinX = line.points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
        if (lineMinX < minX) minX = lineMinX;
      }
    }
    return minX == double.infinity ? 0 : minX;
  }

  double _getMaxX() {
    if (widget.data.lines.isEmpty) return 10;
    double maxX = double.negativeInfinity;
    for (var line in widget.data.lines) {
      if (line.points.isNotEmpty) {
        final lineMaxX = line.points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
        if (lineMaxX > maxX) maxX = lineMaxX;
      }
    }
    return maxX == double.negativeInfinity ? 10 : maxX;
  }

  double _getMaxY() {
    if (widget.data.lines.isEmpty) return 100;
    double maxY = double.negativeInfinity;
    for (var line in widget.data.lines) {
      if (line.points.isNotEmpty) {
        final lineMaxY = line.points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
        if (lineMaxY > maxY) maxY = lineMaxY;
      }
    }
    // Add 20% padding to the top
    return maxY == double.negativeInfinity ? 100 : (maxY * 1.2).ceilToDouble();
  }

  double _getXInterval() {
    final range = _getMaxX() - _getMinX();
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    return (range / 5).ceilToDouble();
  }

  double _getYInterval() {
    final maxY = _getMaxY();
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    return (maxY / 5).ceilToDouble();
  }

  List<LineChartBarData> _buildLineBarData() {
    return widget.data.lines.asMap().entries.map((entry) {
      final line = entry.value;

      return LineChartBarData(
        spots: line.points.map((point) {
          return FlSpot(point.x, point.y);
        }).toList(),
        isCurved: true,
        color: line.getColor(),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final isTouched = touchedSpots.contains(index);
            return FlDotCirclePainter(
              radius: isTouched ? 6 : 4,
              color: line.getColor(),
              strokeWidth: isTouched ? 3 : 2,
              strokeColor: widget.isDarkMode ? Colors.white : Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: line.getColor().withOpacity(0.1),
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.data.lines.map((line) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: line.getColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              line.label,
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
