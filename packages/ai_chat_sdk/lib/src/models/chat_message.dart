import 'package:flutter/foundation.dart';
import 'chart_data.dart';
import 'api_response.dart';

/// Represents a single chat message in the conversation
class ChatMessage {
  final String text;
  final String? rawReport; // Detailed raw report for "more details" toggle
  final bool isUser;
  final DateTime timestamp;
  final ChartType? chartType;
  final ChartData? chartData;
  final ClarifyResponseData? clarificationData;

  ChatMessage({
    required this.text,
    this.rawReport,
    required this.isUser,
    required this.timestamp,
    this.chartType,
    this.chartData,
    this.clarificationData,
  });

  /// Check if this message has a raw report for details view
  bool get hasRawReport => rawReport != null && rawReport!.isNotEmpty;

  /// Parse message from JSON (for AI responses with charts)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    ChartType? type;
    ChartData? data;

    if (json.containsKey('chartType') && json.containsKey('chartData')) {
      try {
        type = ChartTypeExtension.fromString(
          json['chartType'] as String,
        );
        data = ChartData.fromJson(
          json['chartData'] as Map<String, dynamic>,
          type,
        );
      } catch (e) {
        // If chart parsing fails, just show text
        debugPrint('Error parsing chart data: $e');
      }
    }

    return ChatMessage(
      text: json['text'] as String? ?? '',
      rawReport: json['rawReport'] as String?,
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      chartType: type,
      chartData: data,
    );
  }

  /// Convert message to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (rawReport != null) 'rawReport': rawReport,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      if (chartType != null) 'chartType': chartType!.toJson(),
      if (chartData != null) 'chartData': chartData!.toJson(),
    };
  }

  /// Check if this message has chart data
  bool get hasChart => chartType != null && chartData != null;

  /// Check if this message has clarification data
  bool get hasClarification => clarificationData != null;
}
