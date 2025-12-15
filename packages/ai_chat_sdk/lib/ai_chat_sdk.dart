/// AI Chat SDK - A customizable AI chat widget for Flutter apps
///
/// This library provides a drop-in AI chat screen with support for:
/// - Text messaging with markdown rendering
/// - Chart visualization (pie, column, line)
/// - Clarification flows
/// - Theming and customization
library ai_chat_sdk;

// Main widget
export 'src/ai_chat_screen.dart' show AiChatScreen;

// Configuration
export 'src/ai_chat_theme.dart' show AiChatTheme;
export 'src/ai_chat_config.dart' show AiChatConfig;

// Models (for advanced usage)
export 'src/models/chat_message.dart' show ChatMessage;
export 'src/models/chart_data.dart';
