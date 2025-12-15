import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';

/// Service for AI Chat API communication
///
/// This service communicates with the report summarizer API to analyze
/// user questions and generate summaries from detailed reports.
/// Supports conversation memory via session_id and clarification flows.
class ChatService {
  // API Configuration
  static const String _baseUrl = 'https://ai.ssapp.site';
  static const String _summarizerEndpoint = '/api/v1/report-summarizer/summarize';

  // Timeout configuration
  static const Duration _defaultTimeout = Duration(minutes: 3);

  /// Sends a query to the report summarizer API
  ///
  /// Returns a [ReportSummarizerResponse] which can be either:
  /// - An answer (type="answer") with message, chart data, etc.
  /// - A clarification request (type="clarify") with questions and choices
  ///
  /// Use [sessionId] to maintain conversation context across requests.
  static Future<ReportSummarizerResponse> sendMessage({
    required String query,
    String? sessionId,
    DateTime? startDate,
    DateTime? endDate,
    bool returnContext = true,
    Duration? timeout,
  }) async {
    try {
      // Default date range if not provided (last 3 months)
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 90));

      final requestBody = {
        'query': query,
        'start_date': _formatDate(start),
        'end_date': _formatDate(end),
        'return_context': returnContext,
        if (sessionId != null) 'session_id': sessionId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl$_summarizerEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        timeout ?? _defaultTimeout,
        onTimeout: () {
          throw Exception('Request timeout - API took too long to respond');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ReportSummarizerResponse.fromJson(responseData);
      } else if (response.statusCode == 422) {
        throw Exception('Invalid request format. Please check your query.');
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to connect to API: $e');
    }
  }

  /// Format date to YYYY-MM-DD format
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
