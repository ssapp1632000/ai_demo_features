import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../themes.dart';
import '../models/chart_data.dart';
import '../models/api_response.dart';
import '../widgets/charts/pie_chart_widget.dart';
import '../widgets/charts/column_chart_widget.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/clarification_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../services/ai_navigation_service.dart';
import '../services/navigation_controller.dart';
import '../services/azure_speech_service.dart';
import '../services/report_summarizer_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChartType? chartType;
  final ChartData? chartData;
  final ClarifyResponseData? clarificationData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.chartType,
    this.chartData,
    this.clarificationData,
  });

  // Parse message from JSON (for AI responses with charts)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    ChartType? type;
    ChartData? data;

    if (json.containsKey('chartType') &&
        json.containsKey('chartData')) {
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
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      chartType: type,
      chartData: data,
    );
  }

  // Convert message to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      if (chartType != null)
        'chartType': chartType!.toJson(),
      if (chartData != null)
        'chartData': chartData!.toJson(),
    };
  }
}

class AIChatPage extends StatefulWidget {
  final Function(int)? onTabChange;
  final Function(int)? onSubTabChange;
  final GlobalKey? directoryPageKey;

  const AIChatPage({
    super.key,
    this.onTabChange,
    this.onSubTabChange,
    this.directoryPageKey,
  });

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController =
      ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int? _selectedMessageIndex; // Track which message is selected (for showing action buttons)
  bool _isRecording = false; // Track if voice recording is in progress
  final AzureSpeechService _azureSpeech = AzureSpeechService();

  // Session management for conversation continuity
  String? _currentSessionId;

  // Track if user is typing (to disable clarification choices)
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text:
            "👋 Hello! I'm your AI assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    // Listen for text changes to disable clarification choices when typing
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isTyping = _messageController.text.isNotEmpty;
    if (isTyping != _isUserTyping) {
      setState(() {
        _isUserTyping = isTyping;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _azureSpeech.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // Add user message
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isTyping = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Call Report Summarizer API with session_id for conversation continuity
      final response = await ReportSummarizerService.summarizeReport(
        query: text,
        sessionId: _currentSessionId,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;

          // Store session_id for conversation continuity
          _currentSessionId = response.sessionId;

          // Check if this is a clarification request
          if (response.isClarification && response.clarifyData != null) {
            // Add clarification message
            _messages.add(
              ChatMessage(
                text: response.clarifyData!.contextHint ?? 'I need some clarification:',
                isUser: false,
                timestamp: DateTime.now(),
                clarificationData: response.clarifyData,
              ),
            );
          } else if (response.answerData != null) {
            // Handle answer response
            final answerData = response.answerData!;

            // Parse chart data if present
            ChartType? chartType;
            ChartData? chartData;

            if (answerData.hasChart) {
              try {
                // Convert "bar" to "column" for our internal enum
                final chartTypeStr = answerData.chartType == 'bar'
                    ? 'column'
                    : answerData.chartType!;
                chartType = ChartTypeExtension.fromString(chartTypeStr);
                chartData = ChartData.fromJson(
                  answerData.chartData!,
                  chartType,
                );
              } catch (e) {
                debugPrint('Error parsing chart data: $e');
              }
            }

            // Add AI response with message and chart (only if API provides chart data)
            _messages.add(
              ChatMessage(
                text: answerData.message,
                isUser: false,
                timestamp: DateTime.now(),
                chartType: chartType,
                chartData: chartData,
              ),
            );
          } else {
            // Fallback for unexpected response
            _messages.add(
              ChatMessage(
                text: 'I received your message but couldn\'t process the response.',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      // On error, show error message
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: 'Sorry, I encountered an error: ${e.toString().replaceFirst('Exception: ', '')}',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  // Handle clarification choice selection
  void _handleClarificationChoice(String choice) {
    // Set the choice as the message and send it
    _messageController.text = choice;
    _sendMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Start voice recording
  void _startRecording() async {
    // Check if Azure is configured
    if (!AzureSpeechService.isConfigured()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Azure Speech Service not configured. Please add your API key.',
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isRecording = true;
    });

    try {
      // Start recording with Azure Speech Service
      final started = await _azureSpeech.startRecording();

      if (!started) {
        throw Exception(
          'Failed to start recording. Check microphone permissions.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Stop voice recording and convert to text
  void _stopRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
      });

      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                  ),
                ),
                SizedBox(width: 16),
                Text('Converting speech to text...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // Stop recording and convert to text using Azure
        final transcript = await _azureSpeech.stopRecordingAndConvert();

        if (!mounted) return;

        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (transcript != null && transcript.isNotEmpty) {
          setState(() {
            _messageController.text = transcript;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Voice converted to text successfully!',
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No speech detected. Please speak louder and try again.',
              ),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Get navigation controller with callbacks
  NavigationController _getNavigationController() {
    return NavigationController(
      context: context,
      onTabChange: widget.onTabChange ?? (index) {},
      onSubTabChange: widget.onSubTabChange,
      directoryPageKey: widget.directoryPageKey,
    );
  }

  // Handle AI navigation from text input
  Future<void> _handleAINavigation() async {
    final userText = _messageController.text.trim();

    // Validate input
    if (userText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Please enter a command'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: EdgeInsets.all(50),
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Processing your request...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Call AI backend
      final response = await AINavigationService.getNavigationCommand(userText);

      // Hide loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Execute navigation
      final controller = _getNavigationController();
      await controller.executeCommand(response);

      // Clear text field after successful execution
      _messageController.clear();
    } catch (e) {
      // Hide loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping anywhere on screen
          FocusScope.of(context).unfocus();
          // Clear selected message (hide action buttons)
          setState(() {
            _selectedMessageIndex = null;
          });
        },
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey[100],
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _messages.length +
                      (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length &&
                        _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(
                      _messages[index],
                      index,
                      theme,
                      isDark,
                    );
                  },
                ),
              ),
            ),
            // Message input
            _buildMessageInput(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    int messageIndex,
    ThemeData theme,
    bool isDark,
  ) {
    // Create GlobalKey for screenshot capture for messages with charts
    final repaintKey = message.chartData != null
        ? GlobalKey()
        : null;
    final isSelected =
        _selectedMessageIndex == messageIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // Avatar + Action buttons column
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                // Animated action buttons (shown on long press for chart messages)
                if (repaintKey != null) ...[
                  AnimatedSize(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(
                        milliseconds: 200,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          // Share button
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                        alpha: 0.2,
                                      ),
                                  blurRadius: 4,
                                  offset: const Offset(
                                    0,
                                    2,
                                  ),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.share,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _shareChartMessage(
                                  repaintKey,
                                  message,
                                );
                                setState(() {
                                  _selectedMessageIndex =
                                      null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Download button
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                        alpha: 0.2,
                                      ),
                                  blurRadius: 4,
                                  offset: const Offset(
                                    0,
                                    2,
                                  ),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.download,
                                size: 16,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              onPressed: () {
                                _downloadChartData(message);
                                setState(() {
                                  _selectedMessageIndex =
                                      null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress:
                  repaintKey != null && !message.isUser
                  ? () {
                      setState(() {
                        _selectedMessageIndex =
                            messageIndex;
                      });
                    }
                  : null,
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Wrap message content with RepaintBoundary if it has a chart
                  repaintKey != null
                      ? RepaintBoundary(
                          key: repaintKey,
                          child: Container(
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.grey[100],
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.cardDark
                                        : Colors.white,
                                    borderRadius:
                                        const BorderRadius.only(
                                          topLeft:
                                              Radius.circular(
                                                16,
                                              ),
                                          topRight:
                                              Radius.circular(
                                                16,
                                              ),
                                          bottomLeft:
                                              Radius.circular(
                                                4,
                                              ),
                                          bottomRight:
                                              Radius.circular(
                                                16,
                                              ),
                                        ),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors
                                                .primary,
                                            width: 2,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors
                                                  .primary
                                                  .withValues(
                                                    alpha:
                                                        0.3,
                                                  )
                                            : Colors.black
                                                  .withValues(
                                                    alpha:
                                                        0.1,
                                                  ),
                                        blurRadius:
                                            isSelected
                                            ? 8
                                            : 4,
                                        offset:
                                            const Offset(
                                              0,
                                              2,
                                            ),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      // Text content
                                      _buildMessageText(
                                        message.text,
                                        message.isUser,
                                        theme,
                                      ),
                                      // Chart content
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      _buildChart(
                                        message.chartType!,
                                        message.chartData!,
                                        isDark,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(
                                        left: 16,
                                        top: 4,
                                        bottom: 8,
                                      ),
                                  child: Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(
                                      message.timestamp,
                                    ),
                                    style: TextStyle(
                                      color: theme
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(
                                            alpha: 0.6,
                                          ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.cardDark
                                      : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft:
                                  const Radius.circular(16),
                              topRight:
                                  const Radius.circular(16),
                              bottomLeft: Radius.circular(
                                message.isUser ? 16 : 4,
                              ),
                              bottomRight: Radius.circular(
                                message.isUser ? 4 : 16,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: message.clarificationData != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text content (context hint or intro)
                                    if (message.text.isNotEmpty)
                                      _buildMessageText(
                                        message.text,
                                        message.isUser,
                                        theme,
                                      ),
                                    if (message.text.isNotEmpty)
                                      const SizedBox(height: 12),
                                    // Clarification widget
                                    ClarificationWidget(
                                      data: message.clarificationData!,
                                      isDarkMode: isDark,
                                      enabled: !_isUserTyping,
                                      onChoiceSelected: _handleClarificationChoice,
                                    ),
                                  ],
                                )
                              : _buildMessageText(
                                  message.text,
                                  message.isUser,
                                  theme,
                                ),
                        ),
                  // Timestamp for non-chart messages
                  if (repaintKey == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'h:mm a',
                      ).format(message.timestamp),
                      style: TextStyle(
                        color: theme
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(
                  alpha: 0.2,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.accent,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(
    ChartType chartType,
    ChartData chartData,
    bool isDark,
  ) {
    switch (chartType) {
      case ChartType.pie:
        return PieChartWidget(
          data: chartData as PieChartData,
          isDarkMode: isDark,
        );
      case ChartType.column:
        return ColumnChartWidget(
          data: chartData as ColumnChartData,
          isDarkMode: isDark,
        );
      case ChartType.line:
        return LineChartWidget(
          data: chartData as LineChartData,
          isDarkMode: isDark,
        );
    }
  }

  // Build message text content with markdown support
  Widget _buildMessageText(String text, bool isUser, ThemeData theme) {
    // Check if text contains markdown indicators
    bool hasMarkdown = _containsMarkdown(text);

    if (hasMarkdown && !isUser) {
      // Render markdown for AI responses
      return MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            height: 1.4,
          ),
          strong: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
          em: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
          h1: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          h2: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          h3: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          listBullet: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
          ),
          code: TextStyle(
            backgroundColor: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            color: theme.textTheme.bodyLarge?.color,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          codeblockDecoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: TextStyle(
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
            fontSize: 15,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else {
      // Regular text for user messages or non-markdown AI messages
      return Text(
        text,
        style: TextStyle(
          color: isUser
              ? Colors.white
              : theme.textTheme.bodyLarge?.color,
          fontSize: 15,
          height: 1.4,
        ),
      );
    }
  }

  // Check if text contains markdown formatting
  bool _containsMarkdown(String text) {
    // Check for common markdown patterns
    return text.contains('**') || // Bold
           text.contains('*') && !text.contains('**') || // Italic
           text.contains('# ') || // Headers
           text.contains('## ') ||
           text.contains('### ') ||
           text.contains('- ') || // Lists
           text.contains('* ') ||
           text.contains('1. ') ||
           text.contains('```') || // Code blocks
           text.contains('`') || // Inline code
           text.contains('> ') || // Blockquotes
           text.contains('[') && text.contains(']('); // Links
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness ==
                      Brightness.dark
                  ? AppColors.cardDark
                  : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.grey.withValues(
              alpha:
                  0.3 + (0.7 * ((value + index * 0.3) % 1)),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Navigation "Go" Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleAINavigation,
                icon: Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Go - Send to AI Navigation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Message input row
            Row(
              children: [
                // Microphone button (long press to record)
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? AppColors.error
                          : (isDark ? AppColors.cardDark : Colors.grey[300]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isRecording
                              ? AppColors.error.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mic,
                      color: _isRecording
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Text input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type message or use voice...',
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                      ),
                      maxLines: null,
                      textCapitalization:
                          TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button (for regular chat)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Share chart message as screenshot
  Future<void> _shareChartMessage(
    GlobalKey repaintKey,
    ChatMessage message,
  ) async {
    try {
      // Get the RenderRepaintBoundary from the GlobalKey
      RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Capture the widget as an image
      ui.Image image = await boundary.toImage(
        pixelRatio: 3.0,
      );

      // Convert to PNG bytes
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final imageBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Analytics Chart - ${DateFormat('MMM d, yyyy').format(message.timestamp)}',
      );
    } catch (e) {
      debugPrint('Error sharing chart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share chart: $e'),
          ),
        );
      }
    }
  }

  // Download chart data as CSV file
  Future<void> _downloadChartData(
    ChatMessage message,
  ) async {
    try {
      String csvData = '';
      final chartData = message.chartData!;

      // Format data based on chart type
      if (chartData is PieChartData) {
        csvData = 'Label,Value\n';
        for (var section in chartData.sections) {
          csvData += '${section.label},${section.value}\n';
        }
      } else if (chartData is ColumnChartData) {
        csvData =
            '${chartData.xAxisLabel},${chartData.yAxisLabel}\n';
        for (var bar in chartData.bars) {
          csvData += '${bar.label},${bar.value}\n';
        }
      } else if (chartData is LineChartData) {
        csvData = 'Series,X,Y\n';
        for (var line in chartData.lines) {
          for (var point in line.points) {
            csvData +=
                '${line.label},${point.x},${point.y}\n';
          }
        }
      }

      // Save to downloads directory
      final directory =
          await getApplicationDocumentsDirectory();
      final fileName =
          'chart_data_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chart data downloaded to: ${file.path}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading chart data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }
}
