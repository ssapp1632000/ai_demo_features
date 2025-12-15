/// API Response Models for Report Summarizer
///
/// These models match the response schema from ChatDocs.md
/// Supporting both "answer" and "clarify" response types.

/// Main response wrapper from the Report Summarizer API
class ReportSummarizerResponse {
  final bool success;
  final String type; // "answer" | "clarify"
  final String sessionId;
  final String timestamp;
  final int? executionTimeMs;
  final String? error;

  // Data field - either AnswerResponseData or ClarifyResponseData
  final AnswerResponseData? answerData;
  final ClarifyResponseData? clarifyData;

  ReportSummarizerResponse({
    required this.success,
    required this.type,
    required this.sessionId,
    required this.timestamp,
    this.executionTimeMs,
    this.error,
    this.answerData,
    this.clarifyData,
  });

  /// Check if this is a clarification response
  bool get isClarification => type == 'clarify';

  /// Check if this is an answer response
  bool get isAnswer => type == 'answer';

  factory ReportSummarizerResponse.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'answer';
    final data = json['data'] as Map<String, dynamic>?;

    AnswerResponseData? answerData;
    ClarifyResponseData? clarifyData;

    if (data != null) {
      if (type == 'clarify') {
        clarifyData = ClarifyResponseData.fromJson(data);
      } else {
        answerData = AnswerResponseData.fromJson(data);
      }
    }

    return ReportSummarizerResponse(
      success: json['success'] as bool? ?? true,
      type: type,
      sessionId: json['session_id'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      executionTimeMs: json['execution_time_ms'] as int?,
      error: json['error'] as String?,
      answerData: answerData,
      clarifyData: clarifyData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'type': type,
      'session_id': sessionId,
      'timestamp': timestamp,
      if (executionTimeMs != null) 'execution_time_ms': executionTimeMs,
      if (error != null) 'error': error,
      if (answerData != null) 'data': answerData!.toJson(),
      if (clarifyData != null) 'data': clarifyData!.toJson(),
    };
  }
}

/// Data for "answer" type responses
class AnswerResponseData {
  final String message;
  final String? rawReport;
  final Map<String, dynamic>? context;
  final String? chartType; // "pie" | "bar" | "line" | "none"
  final Map<String, dynamic>? chartData;
  final List<String>? keyPoints;

  AnswerResponseData({
    required this.message,
    this.rawReport,
    this.context,
    this.chartType,
    this.chartData,
    this.keyPoints,
  });

  /// Check if response has chart data
  bool get hasChart =>
      chartType != null && chartType != 'none' && chartData != null;

  factory AnswerResponseData.fromJson(Map<String, dynamic> json) {
    return AnswerResponseData(
      message: json['message'] as String? ?? '',
      rawReport: json['raw_report'] as String?,
      context: json['context'] as Map<String, dynamic>?,
      chartType: json['chart_type'] as String?,
      chartData: json['chart_data'] as Map<String, dynamic>?,
      keyPoints: (json['key_points'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (rawReport != null) 'raw_report': rawReport,
      if (context != null) 'context': context,
      if (chartType != null) 'chart_type': chartType,
      if (chartData != null) 'chart_data': chartData,
      if (keyPoints != null) 'key_points': keyPoints,
    };
  }
}

/// Data for "clarify" type responses
class ClarifyResponseData {
  final List<ClarificationQuestion> questions;
  final String? contextHint;

  ClarifyResponseData({
    required this.questions,
    this.contextHint,
  });

  factory ClarifyResponseData.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return ClarifyResponseData(
      questions: questionsJson
          .map((q) => ClarificationQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      contextHint: json['context_hint'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((q) => q.toJson()).toList(),
      if (contextHint != null) 'context_hint': contextHint,
    };
  }
}

/// A single clarification question with choices
class ClarificationQuestion {
  final String question;
  final List<String> choices;

  ClarificationQuestion({
    required this.question,
    required this.choices,
  });

  factory ClarificationQuestion.fromJson(Map<String, dynamic> json) {
    return ClarificationQuestion(
      question: json['question'] as String? ?? '',
      choices: (json['choices'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'choices': choices,
    };
  }
}
