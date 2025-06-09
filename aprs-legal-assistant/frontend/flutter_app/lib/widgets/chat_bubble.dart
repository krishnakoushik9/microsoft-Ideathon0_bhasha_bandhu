import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final Color? userColor;
  final Color? userTextColor;
  final Color? assistantColor;
  final Color? assistantTextColor;

  ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    DateTime? timestamp,
    this.userColor,
    this.userTextColor,
    this.assistantColor,
    this.assistantTextColor,
  })  : timestamp = timestamp ?? DateTime.now(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors based on sender and theme
    final backgroundColor = isUser
        ? (userColor ?? theme.colorScheme.primary)
        : (assistantColor ?? (isDark ? Color(0xFF303030) : Color(0xFFE0E0E0)));

    final textColor = isUser
        ? (userTextColor ?? theme.colorScheme.onPrimary)
        : (assistantTextColor ?? (isDark ? Color(0xFFE0E0E0) : Color(0xFF121212)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? Radius.circular(0) : Radius.circular(16),
                bottomLeft: !isUser ? Radius.circular(0) : Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: _buildStyledText(message, theme, textColor),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatTime(timestamp)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                    if (isUser) ...[
                      SizedBox(width: 4),
                      Icon(
                        Icons.check,
                        size: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fade(duration: 300.ms)
          .slideX(begin: isUser ? 0.2 : -0.2, end: 0, duration: 300.ms),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  TextSpan _buildStyledText(String message, ThemeData theme, Color textColor) {
    // Parse **bold** segments and render accordingly
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: textColor,
      fontSize: 14,
    );
    final parts = message.split('**');
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: baseStyle?.copyWith(
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }
    return TextSpan(children: spans);
  }
}

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              thickness: 1,
              color: theme.colorScheme.onBackground.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _formatDate(date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              thickness: 1,
              color: theme.colorScheme.onBackground.withOpacity(0.2),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
