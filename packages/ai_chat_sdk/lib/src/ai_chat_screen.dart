import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:screenshot/screenshot.dart';
import 'package:printing/printing.dart';

import 'ai_chat_theme.dart';
import 'ai_chat_config.dart';
import 'models/chat_message.dart';
import 'models/chart_data.dart';
import 'services/chat_service.dart';
import 'services/pdf_generator.dart';
import 'widgets/clarification_widget.dart';
import 'widgets/charts/pie_chart_widget.dart';
import 'widgets/charts/column_chart_widget.dart';
import 'widgets/charts/line_chart_widget.dart';

/// The main AI Chat Screen widget
///
/// This is the primary widget of the AI Chat SDK. Simply drop it into your app:
///
/// ```dart
/// import 'package:ai_chat_sdk/ai_chat_sdk.dart';
///
/// // Basic usage
/// AiChatScreen()
///
/// // With customization
/// AiChatScreen(
///   theme: AiChatTheme(primaryColor: Colors.blue),
///   config: AiChatConfig(welcomeMessage: "Hi! How can I help?"),
/// )
/// ```
class AiChatScreen extends StatefulWidget {
  /// Theme configuration for colors and styling
  final AiChatTheme? theme;

  /// Configuration for behavior and display options
  final AiChatConfig? config;

  /// Callback when a message is sent
  final void Function(String message)? onMessageSent;

  /// Callback when a message is received
  final void Function(ChatMessage message)? onMessageReceived;

  /// Callback when an error occurs
  final void Function(Object error)? onError;

  const AiChatScreen({
    super.key,
    this.theme,
    this.config,
    this.onMessageSent,
    this.onMessageReceived,
    this.onError,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int? _selectedMessageIndex;
  String? _currentSessionId;
  bool _isUserTyping = false;
  final Set<int> _expandedMessages = {}; // Track which messages show raw report
  final Map<int, ScreenshotController> _chartScreenshotControllers = {}; // For PDF export

  // Resolved theme and config
  late AiChatTheme _theme;
  late AiChatConfig _config;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? AiChatTheme.light();
    _config = widget.config ?? const AiChatConfig();

    // Add welcome message
    _messages.add(
      ChatMessage(
        text: _config.welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    // Listen for text changes
    _messageController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != oldWidget.theme) {
      _theme = widget.theme ?? AiChatTheme.light();
    }
    if (widget.config != oldWidget.config) {
      _config = widget.config ?? const AiChatConfig();
    }
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
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
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

    // Notify callback
    widget.onMessageSent?.call(text);

    _scrollToBottom();

    try {
      final response = await ChatService.sendMessage(
        query: text,
        sessionId: _currentSessionId,
        timeout: _config.requestTimeout,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _currentSessionId = response.sessionId;

          ChatMessage newMessage;

          if (response.isClarification && response.clarifyData != null) {
            newMessage = ChatMessage(
              text: response.clarifyData!.contextHint ?? 'I need some clarification:',
              isUser: false,
              timestamp: DateTime.now(),
              clarificationData: response.clarifyData,
            );
          } else if (response.answerData != null) {
            final answerData = response.answerData!;

            ChartType? chartType;
            ChartData? chartData;

            if (answerData.hasChart) {
              try {
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

            // Debug: Check if raw_report is available
            debugPrint('=== RAW REPORT DEBUG ===');
            debugPrint('Has rawReport: ${answerData.rawReport != null}');
            debugPrint('rawReport length: ${answerData.rawReport?.length ?? 0}');
            if (answerData.rawReport != null && answerData.rawReport!.isNotEmpty) {
              final preview = answerData.rawReport!.length > 100
                  ? answerData.rawReport!.substring(0, 100)
                  : answerData.rawReport!;
              debugPrint('rawReport preview: $preview...');
            } else {
              debugPrint('rawReport is NULL or EMPTY - "More details" link will NOT appear');
            }

            newMessage = ChatMessage(
              text: answerData.message,
              rawReport: answerData.rawReport,
              isUser: false,
              timestamp: DateTime.now(),
              chartType: chartType,
              chartData: chartData,
            );
          } else {
            newMessage = ChatMessage(
              text: 'I received your message but couldn\'t process the response.',
              isUser: false,
              timestamp: DateTime.now(),
            );
          }

          _messages.add(newMessage);
          widget.onMessageReceived?.call(newMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
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
        widget.onError?.call(e);
        _scrollToBottom();
      }
    }
  }

  void _handleClarificationChoice(String choice) {
    _messageController.text = choice;
    _sendMessage();
  }

  void _toggleMessageDetails(int index) {
    setState(() {
      if (_expandedMessages.contains(index)) {
        _expandedMessages.remove(index);
      } else {
        _expandedMessages.add(index);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final isDark = materialTheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _config.showAppBar ? _buildAppBar() : null,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _selectedMessageIndex = null;
          });
        },
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? _theme.backgroundColor
                      : _theme.backgroundColor,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator(isDark);
                    }
                    return _buildMessageBubble(
                      _messages[index],
                      index,
                      materialTheme,
                      isDark,
                    );
                  },
                ),
              ),
            ),
            _buildMessageInput(materialTheme, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _theme.accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _config.appBarTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _config.appBarSubtitle,
                style: const TextStyle(
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
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    int messageIndex,
    ThemeData theme,
    bool isDark,
  ) {
    final repaintKey = message.chartData != null ? GlobalKey() : null;
    final isSelected = _selectedMessageIndex == messageIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _theme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                // Show action buttons after long-press for AI messages
                if (!message.isUser) ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          // Copy text button
                          _buildActionButton(
                            icon: Icons.copy,
                            color: isDark ? _theme.cardColorDark : Colors.grey[300]!,
                            iconColor: isDark ? Colors.white : Colors.black87,
                            onPressed: () {
                              _copyMessageText(message);
                              setState(() => _selectedMessageIndex = null);
                            },
                          ),
                          const SizedBox(height: 8),
                          // Share button
                          _buildActionButton(
                            icon: Icons.share,
                            color: _theme.primaryColor,
                            onPressed: () {
                              if (repaintKey != null) {
                                _shareChartMessage(repaintKey, message);
                              } else {
                                _shareTextMessage(message);
                              }
                              setState(() => _selectedMessageIndex = null);
                            },
                          ),
                          if (_config.enableChartDownload) ...[
                            const SizedBox(height: 8),
                            // PDF download button
                            _buildActionButton(
                              icon: Icons.picture_as_pdf,
                              color: isDark ? _theme.cardColorDark : Colors.grey[300]!,
                              iconColor: isDark ? Colors.white : Colors.black87,
                              onPressed: () {
                                _downloadMessageAsPdf(message, messageIndex);
                                setState(() => _selectedMessageIndex = null);
                              },
                            ),
                          ],
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
              onLongPress: !message.isUser
                  ? () => setState(() => _selectedMessageIndex = messageIndex)
                  : null,
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  repaintKey != null
                      ? _buildChartMessage(
                          repaintKey, message, theme, isDark, isSelected, messageIndex)
                      : _buildTextMessage(message, theme, isDark, messageIndex),
                  if (repaintKey == null && _config.showTimestamps) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(message.timestamp),
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color
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
                color: _theme.accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: _theme.accentColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: iconColor ?? Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildChartMessage(
    GlobalKey repaintKey,
    ChatMessage message,
    ThemeData theme,
    bool isDark,
    bool isSelected,
    int messageIndex,
  ) {
    // Create screenshot controller for this message if not exists
    _chartScreenshotControllers[messageIndex] ??= ScreenshotController();

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        color: isDark ? _theme.backgroundColor : _theme.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? _theme.cardColorDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: isSelected
                    ? Border.all(color: _theme.primaryColor, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? _theme.primaryColor.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageText(message.text, message.isUser, theme),
                  const SizedBox(height: 12),
                  // Screenshot wraps only the chart for PDF export
                  Screenshot(
                    controller: _chartScreenshotControllers[messageIndex]!,
                    child: _buildChart(message.chartType!, message.chartData!, isDark),
                  ),
                ],
              ),
            ),
              if (_config.showTimestamps)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                  child: Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
    );
  }

  Widget _buildTextMessage(
    ChatMessage message,
    ThemeData theme,
    bool isDark,
    int messageIndex,
  ) {
    final isExpanded = _expandedMessages.contains(messageIndex);
    final displayText = isExpanded && message.hasRawReport
        ? message.rawReport!
        : message.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser
            ? _theme.userBubbleColor
            : (isDark ? _theme.cardColorDark : _theme.aiBubbleColor),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isUser ? 16 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: message.clarificationData != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.text.isNotEmpty)
                  _buildMessageText(displayText, message.isUser, theme),
                if (message.text.isNotEmpty) const SizedBox(height: 12),
                ClarificationWidget(
                  data: message.clarificationData!,
                  isDarkMode: isDark,
                  theme: _theme,
                  enabled: !_isUserTyping,
                  onChoiceSelected: _handleClarificationChoice,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageText(displayText, message.isUser, theme),
                // "More details" / "Show less" toggle link
                if (!message.isUser && message.hasRawReport)
                  GestureDetector(
                    onTap: () => _toggleMessageDetails(messageIndex),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        isExpanded ? 'Show less' : 'More details',
                        style: TextStyle(
                          color: _theme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: _theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildMessageText(String text, bool isUser, ThemeData theme) {
    if (_config.enableMarkdown && _containsMarkdown(text) && !isUser) {
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
      return Text(
        text,
        style: _theme.messageTextStyle ??
            TextStyle(
              color: isUser ? _theme.userTextColor : _theme.aiTextColor,
              fontSize: 15,
              height: 1.4,
            ),
      );
    }
  }

  bool _containsMarkdown(String text) {
    return text.contains('**') ||
        text.contains('*') && !text.contains('**') ||
        text.contains('# ') ||
        text.contains('## ') ||
        text.contains('### ') ||
        text.contains('- ') ||
        text.contains('* ') ||
        text.contains('1. ') ||
        text.contains('```') ||
        text.contains('`') ||
        text.contains('> ') ||
        text.contains('[') && text.contains('](');
  }

  Widget _buildChart(ChartType chartType, ChartData chartData, bool isDark) {
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
          theme: _theme,
        );
      case ChartType.line:
        return LineChartWidget(
          data: chartData as LineChartData,
          isDarkMode: isDark,
        );
    }
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _theme.accentColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? _theme.cardColorDark : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
            color: Colors.grey.withValues(
              alpha: 0.3 + (0.7 * ((value + index * 0.3) % 1)),
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
        color: isDark ? _theme.surfaceColorDark : _theme.inputBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? _theme.cardColorDark : _theme.inputFieldColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _config.inputHint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _theme.sendButtonColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _theme.sendButtonColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareChartMessage(
    GlobalKey repaintKey,
    ChatMessage message,
  ) async {
    try {
      RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final imageBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Analytics Chart - ${DateFormat('MMM d, yyyy').format(message.timestamp)}',
      );
    } catch (e) {
      debugPrint('Error sharing chart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share chart: $e')),
        );
      }
    }
  }

  /// Copy message text to clipboard
  void _copyMessageText(ChatMessage message) {
    final textToCopy = message.rawReport ?? message.text;
    Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Share text message
  Future<void> _shareTextMessage(ChatMessage message) async {
    try {
      final textToShare = message.rawReport ?? message.text;
      await Share.share(
        textToShare,
        subject: 'AI Assistant Response - ${DateFormat('MMM d, yyyy').format(message.timestamp)}',
      );
    } catch (e) {
      debugPrint('Error sharing message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share message: $e')),
        );
      }
    }
  }

  /// Download message as PDF with optional chart image
  Future<void> _downloadMessageAsPdf(ChatMessage message, int messageIndex) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Generating PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Capture chart as image if present
      Uint8List? chartImage;
      if (message.hasChart && _chartScreenshotControllers.containsKey(messageIndex)) {
        chartImage = await _chartScreenshotControllers[messageIndex]!.capture();
      }

      // Get report text (prefer rawReport, fallback to text)
      final reportText = message.rawReport ?? message.text;

      // Generate PDF
      final pdfBytes = await PdfGenerator.generateReportPdf(
        reportText: reportText,
        chartImage: chartImage,
        title: 'AI Assistant Report',
      );

      // Share/save PDF
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'ai_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }
}
