import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';

/// Service for AI Report Summarization
///
/// This service communicates with the report summarizer API to analyze
/// user questions and generate summaries from detailed reports.
/// Supports conversation memory via session_id and clarification flows.
class ReportSummarizerService {
  // API Configuration
  static const String _baseUrl = 'https://ai.ssapp.site';
  static const String _summarizerEndpoint = '/api/v1/report-summarizer/summarize';

  // Timeout configuration
  static const Duration _requestTimeout = Duration(minutes: 3);

  /// Sends a query to the report summarizer API
  ///
  /// Returns a [ReportSummarizerResponse] which can be either:
  /// - An answer (type="answer") with message, chart data, etc.
  /// - A clarification request (type="clarify") with questions and choices
  ///
  /// Use [sessionId] to maintain conversation context across requests.
  static Future<ReportSummarizerResponse> summarizeReport({
    required String query,
    String? sessionId,
    DateTime? startDate,
    DateTime? endDate,
    bool returnContext = true,
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

      print('🔵 [REPORT API] Sending query: $query');
      print('🔵 [REPORT API] Session ID: ${sessionId ?? "new session"}');
      print('🔵 [REPORT API] Date range: ${_formatDate(start)} to ${_formatDate(end)}');

      final response = await http.post(
        Uri.parse('$_baseUrl$_summarizerEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        _requestTimeout,
        onTimeout: () {
          throw Exception('Request timeout - Report API took too long to respond');
        },
      );

      print('🟢 [REPORT API] Response received: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final parsedResponse = ReportSummarizerResponse.fromJson(responseData);

        print('🟢 [REPORT API] Response type: ${parsedResponse.type}');
        if (parsedResponse.isClarification) {
          print('🟡 [REPORT API] Clarification needed - ${parsedResponse.clarifyData?.questions.length ?? 0} question(s)');
        } else {
          print('🟢 [REPORT API] Answer received');
        }

        return parsedResponse;
      } else if (response.statusCode == 422) {
        throw Exception('Invalid request format. Please check your query.');
      } else if (response.statusCode == 500) {
        throw Exception('Report server error. Please try again later.');
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REPORT API ERROR] Failed to get response: $e');
      if (e is Exception) rethrow;
      throw Exception('Failed to connect to report API: $e');
    }
  }

  /// Format date to YYYY-MM-DD format
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }
}
