import 'package:flutter/material.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';
import 'package:campus_conn/messages/screens/chat_screen.dart';

/// Helper functions for navigation to diagnose issues
class NavigationHelper {
  /// Navigate to a chat screen from any widget
  static void navigateToChat(BuildContext context, Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chat: chat,
          recipientImageUrl: chat.user.image_url,
        ),
      ),
    );
  }
}
