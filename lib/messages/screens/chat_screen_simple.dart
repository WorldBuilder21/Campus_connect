import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';
import 'package:campus_conn/messages/providers/chat_provider.dart';
import 'package:campus_conn/messages/providers/message_provider.dart';

/// A simplified version of the chat screen
/// Use this if you're having issues with the full implementation
class SimpleChatScreen extends ConsumerWidget {
  final Chat chat;
  final String? recipientImageUrl;

  const SimpleChatScreen({
    Key? key,
    required this.chat,
    this.recipientImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageState = ref.watch(messageProvider(chat.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(chat.user.username ?? 'Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messageState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messageState.messages.isEmpty
                    ? Center(child: Text('No messages yet'))
                    : ListView.builder(
                        itemCount: messageState.messages.length,
                        itemBuilder: (context, index) {
                          final message = messageState.messages[index];
                          return ListTile(
                            title: Text(message.content),
                            subtitle: Text(message.timestamp.toString()),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        ref
                            .read(messageProvider(chat.id).notifier)
                            .sendMessage(text);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                  onPressed: () {
                    // Send button logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
