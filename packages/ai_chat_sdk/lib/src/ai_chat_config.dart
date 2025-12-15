/// Configuration options for the AI Chat SDK
///
/// Use this class to customize behavior and display options.
///
/// Example usage:
/// ```dart
/// AiChatScreen(
///   config: AiChatConfig(
///     welcomeMessage: "Hi! How can I help you today?",
///     inputHint: "Ask me anything...",
///   ),
/// )
/// ```
class AiChatConfig {
  /// The welcome message shown when chat starts
  final String welcomeMessage;

  /// Placeholder text for the input field
  final String inputHint;

  /// Whether to show timestamps on messages
  final bool showTimestamps;

  /// Whether to enable markdown rendering for AI messages
  final bool enableMarkdown;

  /// Whether to show the app bar
  final bool showAppBar;

  /// Title shown in the app bar
  final String appBarTitle;

  /// Subtitle shown in the app bar (e.g., "Online")
  final String appBarSubtitle;

  /// Whether to enable chart sharing functionality
  final bool enableChartSharing;

  /// Whether to enable chart data download (CSV)
  final bool enableChartDownload;

  /// Request timeout duration
  final Duration requestTimeout;

  const AiChatConfig({
    this.welcomeMessage = "Hello! I'm your AI assistant. How can I help you today?",
    this.inputHint = "Type a message...",
    this.showTimestamps = true,
    this.enableMarkdown = true,
    this.showAppBar = true,
    this.appBarTitle = "AI Assistant",
    this.appBarSubtitle = "Online",
    this.enableChartSharing = true,
    this.enableChartDownload = true,
    this.requestTimeout = const Duration(minutes: 3),
  });

  /// Create a copy of this config with some values replaced
  AiChatConfig copyWith({
    String? welcomeMessage,
    String? inputHint,
    bool? showTimestamps,
    bool? enableMarkdown,
    bool? showAppBar,
    String? appBarTitle,
    String? appBarSubtitle,
    bool? enableChartSharing,
    bool? enableChartDownload,
    Duration? requestTimeout,
  }) {
    return AiChatConfig(
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      inputHint: inputHint ?? this.inputHint,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      showAppBar: showAppBar ?? this.showAppBar,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      appBarSubtitle: appBarSubtitle ?? this.appBarSubtitle,
      enableChartSharing: enableChartSharing ?? this.enableChartSharing,
      enableChartDownload: enableChartDownload ?? this.enableChartDownload,
      requestTimeout: requestTimeout ?? this.requestTimeout,
    );
  }
}
