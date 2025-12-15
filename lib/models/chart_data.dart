import 'dart:ui';

/// Enum for different chart types
enum ChartType {
  pie,
  column,
  line,
}

/// Extension to parse ChartType from string
extension ChartTypeExtension on ChartType {
  static ChartType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'pie':
        return ChartType.pie;
      case 'column':
        return ChartType.column;
      case 'line':
        return ChartType.line;
      default:
        throw Exception('Unknown chart type: $type');
    }
  }

  String toJson() {
    return toString().split('.').last;
  }
}

/// Base class for all chart data
abstract class ChartData {
  final String title;

  ChartData({required this.title});

  Map<String, dynamic> toJson();

  static ChartData fromJson(Map<String, dynamic> json, ChartType type) {
    switch (type) {
      case ChartType.pie:
        return PieChartData.fromJson(json);
      case ChartType.column:
        return ColumnChartData.fromJson(json);
      case ChartType.line:
        return LineChartData.fromJson(json);
    }
  }
}

/// Pie Chart Data Model
class PieChartData extends ChartData {
  final List<PieChartSection> sections;

  PieChartData({
    required super.title,
    required this.sections,
  });

  factory PieChartData.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>? ?? [];
    return PieChartData(
      title: json['title'] as String? ?? '',
      sections: sectionsJson.asMap().entries.map((entry) {
        return PieChartSection.fromJson(
          entry.value as Map<String, dynamic>,
          entry.key, // Pass index for default color selection
        );
      }).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }
}

class PieChartSection {
  final String label;
  final double value;
  final String color; // Hex color string

  /// Default color palette for pie chart sections when API doesn't provide colors
  static const List<String> _defaultColors = [
    '#FF6B35', // Orange
    '#4ECDC4', // Teal
    '#45B7D1', // Sky Blue
    '#96CEB4', // Sage Green
    '#F39C12', // Amber
    '#9B59B6', // Purple
    '#1ABC9C', // Emerald
    '#E74C3C', // Red
    '#3498DB', // Blue
    '#2ECC71', // Green
  ];

  PieChartSection({
    required this.label,
    required this.value,
    required this.color,
  });

  factory PieChartSection.fromJson(Map<String, dynamic> json, [int index = 0]) {
    return PieChartSection(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ??
          _defaultColors[index % _defaultColors.length],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color,
    };
  }

  Color getColor() {
    return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
  }
}

/// Column Chart Data Model
class ColumnChartData extends ChartData {
  final String xAxisLabel;
  final String yAxisLabel;
  final List<ColumnChartBar> bars;

  ColumnChartData({
    required super.title,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.bars,
  });

  factory ColumnChartData.fromJson(Map<String, dynamic> json) {
    return ColumnChartData(
      title: json['title'] as String? ?? '',
      xAxisLabel: json['xAxisLabel'] as String? ?? '',
      yAxisLabel: json['yAxisLabel'] as String? ?? '',
      bars: (json['bars'] as List<dynamic>?)
              ?.map((e) => ColumnChartBar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'xAxisLabel': xAxisLabel,
      'yAxisLabel': yAxisLabel,
      'bars': bars.map((e) => e.toJson()).toList(),
    };
  }
}

class ColumnChartBar {
  final String label;
  final double value;

  ColumnChartBar({
    required this.label,
    required this.value,
  });

  factory ColumnChartBar.fromJson(Map<String, dynamic> json) {
    return ColumnChartBar(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}

/// Line Chart Data Model
class LineChartData extends ChartData {
  final String xAxisLabel;
  final String yAxisLabel;
  final List<LineChartLine> lines;

  LineChartData({
    required super.title,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.lines,
  });

  factory LineChartData.fromJson(Map<String, dynamic> json) {
    return LineChartData(
      title: json['title'] as String? ?? '',
      xAxisLabel: json['xAxisLabel'] as String? ?? '',
      yAxisLabel: json['yAxisLabel'] as String? ?? '',
      lines: (json['lines'] as List<dynamic>?)
              ?.map((e) => LineChartLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'xAxisLabel': xAxisLabel,
      'yAxisLabel': yAxisLabel,
      'lines': lines.map((e) => e.toJson()).toList(),
    };
  }
}

class LineChartLine {
  final String label;
  final String color; // Hex color string
  final List<LineChartPoint> points;

  LineChartLine({
    required this.label,
    required this.color,
    required this.points,
  });

  factory LineChartLine.fromJson(Map<String, dynamic> json) {
    return LineChartLine(
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '#FF6B35',
      points: (json['points'] as List<dynamic>?)
              ?.map((e) => LineChartPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'color': color,
      'points': points.map((e) => e.toJson()).toList(),
    };
  }

  Color getColor() {
    return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
  }
}

class LineChartPoint {
  final double x;
  final double y;

  LineChartPoint({
    required this.x,
    required this.y,
  });

  factory LineChartPoint.fromJson(Map<String, dynamic> json) {
    return LineChartPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}
