import 'package:flutter/material.dart';
import 'package:campus_conn/messages/utils/message_formatter.dart';

/// A reusable widget for displaying formatted timestamps in messages
class MessageTimestamp extends StatelessWidget {
  /// The timestamp to display
  final DateTime timestamp;

  /// Text color
  final Color? color;

  /// Text style
  final TextStyle? style;

  /// Format type for the timestamp
  final TimestampFormat format;

  /// Optional builder for custom formatting
  final String Function(DateTime)? customFormatter;

  /// Constructor
  const MessageTimestamp({
    Key? key,
    required this.timestamp,
    this.color,
    this.style,
    this.format = TimestampFormat.message,
    this.customFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use default text style based on context if none provided
    final defaultStyle = DefaultTextStyle.of(context).style.copyWith(
          fontSize: 11,
          color: color ?? Colors.grey[600],
          fontWeight: FontWeight.w400,
        );

    // Combine default with provided style
    final textStyle = style != null ? defaultStyle.merge(style) : defaultStyle;

    return Text(
      _getFormattedTime(),
      style: textStyle,
    );
  }

  /// Get the formatted time string based on the specified format
  String _getFormattedTime() {
    if (customFormatter != null) {
      return customFormatter!(timestamp);
    }

    switch (format) {
      case TimestampFormat.chatList:
        return MessageFormatter.formatChatListTime(timestamp);
      case TimestampFormat.message:
        return MessageFormatter.formatShortTime(timestamp);
      case TimestampFormat.dateSeparator:
        return MessageFormatter.formatMessageDate(timestamp);
      case TimestampFormat.fullTimestamp:
        return MessageFormatter.formatMessageTime(timestamp);
    }
  }
}

/// Format types for timestamps
enum TimestampFormat {
  /// For chat list items (e.g., "2m ago", "Yesterday")
  chatList,

  /// For message bubbles (e.g., "14:30")
  message,

  /// For date separators (e.g., "Today", "Monday, April 14")
  dateSeparator,

  /// Full timestamp with date if not today (e.g., "14:30" or "14/04/2025")
  fullTimestamp,
}
