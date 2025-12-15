import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../ai_chat_theme.dart';

/// Widget for displaying clarification questions with selectable choices
///
/// Used when the AI needs more information from the user.
/// Displays questions with tappable choice items in a vertical list.
class ClarificationWidget extends StatelessWidget {
  final ClarifyResponseData data;
  final bool isDarkMode;
  final bool enabled;
  final AiChatTheme theme;
  final Function(String selectedChoice) onChoiceSelected;

  const ClarificationWidget({
    super.key,
    required this.data,
    required this.isDarkMode,
    required this.theme,
    required this.onChoiceSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context hint (if present)
          if (data.contextHint != null && data.contextHint!.isNotEmpty) ...[
            _buildContextHint(),
            const SizedBox(height: 12),
          ],
          // Questions and choices
          ...data.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const SizedBox(height: 16),
                _buildQuestion(question),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Builds the context hint info box
  Widget _buildContextHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.infoColor.withOpacity(0.15)
            : theme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.infoColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.infoColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.contextHint!,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single question with its choices
  Widget _buildQuestion(ClarificationQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.help_outline,
              color: theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question.question,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Choice items
        ...question.choices.map((choice) => _buildChoiceItem(choice)),
      ],
    );
  }

  /// Builds a single choice item
  Widget _buildChoiceItem(String choice) {
    final backgroundColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];
    final disabledColor = isDarkMode ? Colors.grey[900] : Colors.grey[200];
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final disabledBorderColor =
        isDarkMode ? Colors.grey[800]! : Colors.grey[400]!;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final disabledTextColor = isDarkMode ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onChoiceSelected(choice) : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? backgroundColor : disabledColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled ? borderColor : disabledBorderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 18,
                  color: enabled ? theme.primaryColor : disabledTextColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled ? textColor : disabledTextColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: enabled
                      ? (isDarkMode ? Colors.white54 : Colors.black45)
                      : disabledTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
