import 'package:flutter/material.dart';
import 'package:campus_conn/messages/screens/chat_list_screen.dart';
import 'package:campus_conn/messages/screens/chat_screen.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';

// Export all messaging components for easy imports
// This allows other modules to import just this file
export 'package:campus_conn/messages/screens/chat_list_screen.dart';
export 'package:campus_conn/messages/screens/chat_screen.dart';
export 'package:campus_conn/messages/schema/chat_schema.dart';
export 'package:campus_conn/messages/schema/message_schema.dart';
export 'package:campus_conn/messages/providers/chat_provider.dart';
export 'package:campus_conn/messages/providers/message_provider.dart';

/// Main entry point for the messaging module
/// This file provides exports and helper methods for working with messages
class Messaging {
  /// Navigate to the chat list screen
  static void navigateToChatList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatListScreen()),
    );
  }

  /// Navigate to a specific chat screen
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

  /// Check for unread messages count
  static int getUnreadMessagesCount(List<Chat> chats) {
    return chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }
}
