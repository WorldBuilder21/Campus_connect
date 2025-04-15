import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/providers/chat_provider.dart';
import 'package:campus_conn/messages/providers/message_provider.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';
import 'package:campus_conn/messages/schema/message_schema.dart';
import 'package:campus_conn/messages/utils/audio_utils.dart';
import 'package:campus_conn/messages/utils/message_formatter.dart';
import 'package:campus_conn/messages/widgets/chat/attachment_option_sheet.dart';
import 'package:campus_conn/messages/widgets/chat/chat_app_bar.dart';
import 'package:campus_conn/messages/widgets/chat/chat_options_sheet.dart';
import 'package:campus_conn/messages/widgets/chat/message_bubble.dart';
import 'package:campus_conn/messages/widgets/chat/message_input_field.dart';
import 'package:campus_conn/messages/widgets/common/loading_states.dart';
import 'package:campus_conn/profile/screens/profile_screen.dart';

/// A beautiful, modern chat screen with rich features
class ChatScreen extends ConsumerStatefulWidget {
  /// Chat data
  final Chat chat;

  /// Recipient's image URL
  final String? recipientImageUrl;

  /// Constructor
  const ChatScreen({
    Key? key,
    required this.chat,
    required this.recipientImageUrl,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _currentUserId;

  // Audio utilities
  final AudioUtils _audioUtils = AudioUtils();

  // Animation controllers
  late AnimationController _fadeAnimationController;

  @override
  void initState() {
    super.initState();

    // Get current user ID
    _currentUserId = _supabase.auth.currentUser?.id;

    // Initialize audio utilities
    _audioUtils.initialize();

    // Set up animation controllers
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Start entrance animation
    _fadeAnimationController.forward();

    // Mark chat as read
    _markAsRead();
  }

  @override
  void dispose() {
    // Dispose audio utilities
    _audioUtils.dispose();

    // Dispose animation controllers
    _fadeAnimationController.dispose();

    // Dispose scroll controller
    _scrollController.dispose();

    super.dispose();
  }

  /// Mark chat as read
  Future<void> _markAsRead() async {
    // Mark chat as read using ref
    ref.read(chatProvider.notifier).markChatAsRead(widget.chat.id);
  }

  /// Scroll to bottom of the message list
  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    }
  }

  /// Show chat options bottom sheet
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatOptionsSheet(
        chat: widget.chat,
        onViewProfile: _navigateToProfile,
        onDeleteChat: _deleteChat,
        onSearchChat: () {
          // TODO: Implement search in chat
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Navigate to profile screen
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userId: widget.chat.user.id!,
          showBackBtn: true,
        ),
      ),
    );
  }

  /// Delete chat
  Future<void> _deleteChat() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete chat
      final success =
          await ref.read(chatProvider.notifier).deleteChat(widget.chat.id);

      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          // Go back to chat list
          Navigator.pop(context);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show attachment options sheet
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttachmentOptionSheet(
        onImageSelected: (file, isCamera) {
          _handleImageSelected(file);
        },
        onDocumentSelected: (file) {
          _handleDocumentSelected(file);
        },
      ),
    );
  }

  /// Handle image selection
  void _handleImageSelected(File file) {
    ref.read(messageProvider(widget.chat.id).notifier).sendImageMessage(
          file.path,
          '',
        );
  }

  /// Handle document selection
  void _handleDocumentSelected(File file) {
    ref.read(messageProvider(widget.chat.id).notifier).sendDocumentMessage(
          file.path,
        );
  }

  /// Handle audio recording
  void _handleAudioRecording(String path) {
    ref.read(messageProvider(widget.chat.id).notifier).sendAudioMessage(
          path,
        );
  }

  /// Handle sending a text message
  void _handleSendMessage(String message) {
    if (message.trim().isEmpty) return;

    // Send message
    ref.read(messageProvider(widget.chat.id).notifier).sendMessage(message);

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  /// Handle playing audio
  void _handlePlayAudio(String messageId) {
    final messageState = ref.read(messageProvider(widget.chat.id));
    final message = messageState.messages.firstWhere((m) => m.id == messageId);

    if (message.imageUrl != null) {
      _audioUtils.playAudio(messageId, message.imageUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the message state for this specific chat
    final messageState = ref.watch(messageProvider(widget.chat.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatAppBar(
        user: widget.chat.user,
        onBack: () => Navigator.pop(context),
        onMenuPressed: _showChatOptions,
      ),
      body: SafeArea(
        bottom: false, // Let input field handle bottom safe area
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: messageState.isLoading
                  ? MessageLoadingStates.messageListLoading(context)
                  : _buildMessageList(messageState.messages),
            ),

            // Message input
            MessageInputField(
              onSendMessage: _handleSendMessage,
              onAttachmentTap: _showAttachmentOptions,
              onSendAudio: _handleAudioRecording,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the message list
  Widget _buildMessageList(List<Message> messages) {
    // If there are no messages, show empty state
    if (messages.isEmpty) {
      return _buildEmptyChat();
    }

    // Process messages to determine date separators, grouping, etc.
    final processedMessages = _processMessagesForDisplay(messages);

    return FadeTransition(
      opacity: _fadeAnimationController,
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard if tapped
          FocusScope.of(context).unfocus();
        },
        child: ListView.builder(
          controller: _scrollController,
          reverse: false, // Show newest messages at the bottom
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: processedMessages.length,
          itemBuilder: (context, index) {
            final item = processedMessages[index];

            if (item is _DateSeparator) {
              // Date separator
              return _buildDateSeparator(item.date);
            } else if (item is MessageGroup) {
              // Message group
              return _buildMessageGroup(item);
            } else {
              // Should never happen
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  /// Build empty chat state
  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.chat.user.image_url != null
                  ? NetworkImage(widget.chat.user.image_url!)
                  : null,
              child: widget.chat.user.image_url == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.chat.user.username ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first message!',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This is the beginning of your conversation with ${widget.chat.user.username ?? 'this user'}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a date separator
  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              MessageFormatter.formatMessageDate(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a message group
  Widget _buildMessageGroup(MessageGroup group) {
    return Column(
      children: group.messages.asMap().entries.map((entry) {
        final index = entry.key;
        final message = entry.value;
        final isMe = message.senderId == _currentUserId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: !isMe && index == group.messages.length - 1,
          isFirstInGroup: index == 0,
          isLastInGroup: index == group.messages.length - 1,
          showDateSeparator: false, // Handled separately
          senderAvatarUrl: widget.chat.user.image_url,
          senderVerified: widget.chat.user.email_verified ?? false,
          onPlayAudio: _handlePlayAudio,
        );
      }).toList(),
    );
  }

  /// Process messages for display - group by sender and add date separators
  List<_MessageDisplayItem> _processMessagesForDisplay(List<Message> messages) {
    if (messages.isEmpty) return [];

    // Final display items
    final List<_MessageDisplayItem> displayItems = [];

    // Temporary storage for current message group
    MessageGroup? currentGroup;
    DateTime? currentDate;

    // Process each message in chronological order
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final isMe = message.senderId == _currentUserId;

      // Check if we need to add a date separator
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      if (currentDate == null || messageDate != currentDate) {
        // Add existing group if any
        if (currentGroup != null) {
          displayItems.add(currentGroup);
          currentGroup = null;
        }

        // Add date separator
        displayItems.add(_DateSeparator(messageDate));
        currentDate = messageDate;
      }

      // Check if we need to start a new group
      if (currentGroup == null || currentGroup.senderId != message.senderId) {
        // Add existing group if any
        if (currentGroup != null) {
          displayItems.add(currentGroup);
        }

        // Start new group
        currentGroup = MessageGroup(
          senderId: message.senderId,
          messages: [message],
          isMe: isMe,
        );
      } else {
        // Add to current group if time difference is less than 2 minutes
        final prevMessage = currentGroup.messages.last;
        final timeDiff =
            message.timestamp.difference(prevMessage.timestamp).inMinutes;

        if (timeDiff < 2) {
          currentGroup.messages.add(message);
        } else {
          // Add existing group
          displayItems.add(currentGroup);

          // Start new group
          currentGroup = MessageGroup(
            senderId: message.senderId,
            messages: [message],
            isMe: isMe,
          );
        }
      }
    }

    // Add last group if any
    if (currentGroup != null) {
      displayItems.add(currentGroup);
    }

    return displayItems;
  }
}

/// Base class for message display items
abstract class _MessageDisplayItem {}

/// Date separator item
class _DateSeparator extends _MessageDisplayItem {
  final DateTime date;

  _DateSeparator(this.date);
}

/// Message group item - messages from the same sender in sequence
class MessageGroup extends _MessageDisplayItem {
  final String senderId;
  final List<Message> messages;
  final bool isMe;

  MessageGroup({
    required this.senderId,
    required this.messages,
    required this.isMe,
  });
}
