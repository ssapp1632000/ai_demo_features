import 'package:flutter/material.dart';

/// Theme configuration for the AI Chat SDK
///
/// Use this class to customize colors, fonts, and styling of the chat screen.
///
/// Example usage:
/// ```dart
/// AiChatScreen(
///   theme: AiChatTheme(
///     primaryColor: Colors.blue,
///     userBubbleColor: Colors.blue,
///   ),
/// )
/// ```
class AiChatTheme {
  /// Primary color used for buttons and accents
  final Color primaryColor;

  /// Accent color used for secondary elements
  final Color accentColor;

  /// Background color of the user's message bubble
  final Color userBubbleColor;

  /// Background color of the AI's message bubble
  final Color aiBubbleColor;

  /// Text color for user messages
  final Color userTextColor;

  /// Text color for AI messages
  final Color aiTextColor;

  /// Background color of the chat area
  final Color backgroundColor;

  /// Background color of the input area
  final Color inputBackgroundColor;

  /// Background color of the text field
  final Color inputFieldColor;

  /// Color of the send button
  final Color sendButtonColor;

  /// Dark mode background colors
  final Color cardColorDark;
  final Color surfaceColorDark;

  /// Status colors
  final Color errorColor;
  final Color successColor;
  final Color warningColor;
  final Color infoColor;

  /// Border radius for message bubbles
  final double bubbleBorderRadius;

  /// Custom text style for messages (optional)
  final TextStyle? messageTextStyle;

  /// Custom text style for timestamps (optional)
  final TextStyle? timestampTextStyle;

  const AiChatTheme({
    this.primaryColor = Colors.deepOrangeAccent,
    this.accentColor = Colors.orangeAccent,
    this.userBubbleColor = Colors.deepOrangeAccent,
    this.aiBubbleColor = Colors.white,
    this.userTextColor = Colors.white,
    this.aiTextColor = Colors.black87,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.inputBackgroundColor = Colors.white,
    this.inputFieldColor = const Color(0xFFF5F5F5),
    this.sendButtonColor = Colors.deepOrangeAccent,
    this.cardColorDark = const Color(0xFF2A2A2A),
    this.surfaceColorDark = const Color(0xFF1E1E1E),
    this.errorColor = Colors.red,
    this.successColor = Colors.green,
    this.warningColor = Colors.orange,
    this.infoColor = Colors.blue,
    this.bubbleBorderRadius = 16.0,
    this.messageTextStyle,
    this.timestampTextStyle,
  });

  /// Create a light theme with default values
  factory AiChatTheme.light() {
    return const AiChatTheme();
  }

  /// Create a dark theme
  factory AiChatTheme.dark() {
    return const AiChatTheme(
      backgroundColor: Color(0xFF121212),
      inputBackgroundColor: Color(0xFF1E1E1E),
      inputFieldColor: Color(0xFF2A2A2A),
      aiBubbleColor: Color(0xFF2A2A2A),
      aiTextColor: Colors.white,
    );
  }

  /// Create theme from an existing MaterialApp theme
  factory AiChatTheme.fromMaterialTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return AiChatTheme(
      primaryColor: theme.colorScheme.primary,
      accentColor: theme.colorScheme.secondary,
      userBubbleColor: theme.colorScheme.primary,
      aiBubbleColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      userTextColor: theme.colorScheme.onPrimary,
      aiTextColor: isDark ? Colors.white : Colors.black87,
      backgroundColor: theme.scaffoldBackgroundColor,
      inputBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      inputFieldColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      sendButtonColor: theme.colorScheme.primary,
      errorColor: theme.colorScheme.error,
    );
  }

  /// Create a copy of this theme with some values replaced
  AiChatTheme copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? userBubbleColor,
    Color? aiBubbleColor,
    Color? userTextColor,
    Color? aiTextColor,
    Color? backgroundColor,
    Color? inputBackgroundColor,
    Color? inputFieldColor,
    Color? sendButtonColor,
    Color? cardColorDark,
    Color? surfaceColorDark,
    Color? errorColor,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    double? bubbleBorderRadius,
    TextStyle? messageTextStyle,
    TextStyle? timestampTextStyle,
  }) {
    return AiChatTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      aiBubbleColor: aiBubbleColor ?? this.aiBubbleColor,
      userTextColor: userTextColor ?? this.userTextColor,
      aiTextColor: aiTextColor ?? this.aiTextColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      inputFieldColor: inputFieldColor ?? this.inputFieldColor,
      sendButtonColor: sendButtonColor ?? this.sendButtonColor,
      cardColorDark: cardColorDark ?? this.cardColorDark,
      surfaceColorDark: surfaceColorDark ?? this.surfaceColorDark,
      errorColor: errorColor ?? this.errorColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      bubbleBorderRadius: bubbleBorderRadius ?? this.bubbleBorderRadius,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      timestampTextStyle: timestampTextStyle ?? this.timestampTextStyle,
    );
  }
}
