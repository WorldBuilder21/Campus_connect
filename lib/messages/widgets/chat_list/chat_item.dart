import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';
import 'package:campus_conn/messages/utils/message_formatter.dart';
import 'package:campus_conn/messages/widgets/common/avatar_widget.dart';
import 'package:campus_conn/messages/widgets/common/message_timestamp.dart';

/// A beautiful chat list item with smooth animations and modern design
class ChatItem extends StatefulWidget {
  /// The chat data
  final Chat chat;

  /// Callback for when the chat item is tapped
  final Function(Chat) onTap;

  /// Callback for when the chat item is long pressed
  final Function(Chat)? onLongPress;

  /// Animation delay duration (for staggered animations)
  final Duration animationDelay;

  /// Whether this chat is selected in multi-select mode
  final bool isSelected;

  /// Constructor
  const ChatItem({
    Key? key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.animationDelay = Duration.zero,
  }) : super(key: key);

  @override
  State<ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Define animations
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Run entry animation after delay
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extract data from chat
    final hasUnread = widget.chat.unreadCount > 0;

    // Message preview truncation and formatting
    final String messagePreview =
        _formatMessagePreview(widget.chat.lastMessage);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: widget.isSelected
            ? AppTheme.primaryColor.withOpacity(0.08)
            : Colors.transparent,
        child: InkWell(
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          highlightColor: AppTheme.primaryColor.withOpacity(0.05),
          onTap: () => widget.onTap(widget.chat),
          onLongPress: widget.onLongPress != null
              ? () => widget.onLongPress!(widget.chat)
              : null,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                // Avatar with verified status
                AvatarWidget(
                  imageUrl: widget.chat.user.image_url,
                  radius: 28,
                  isVerified: widget.chat.user.email_verified ?? false,
                  borderColor: widget.isSelected ? AppTheme.primaryColor : null,
                  borderWidth: 2,
                ),
                const SizedBox(width: 12),

                // Chat details (name, message preview)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Username
                      Text(
                        widget.chat.user.username ?? 'User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              hasUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Message preview
                      Text(
                        messagePreview,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasUnread
                              ? AppTheme.textPrimaryColor
                              : Colors.grey[600],
                          fontWeight:
                              hasUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right side (time + unread count)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Time
                    MessageTimestamp(
                      timestamp: widget.chat.lastMessageTime,
                      format: TimestampFormat.chatList,
                      color:
                          hasUnread ? AppTheme.primaryColor : Colors.grey[500],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Unread badge or status indicator
                    if (hasUnread)
                      Container(
                        padding:
                            EdgeInsets.all(widget.chat.unreadCount > 9 ? 6 : 8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          widget.chat.unreadCount > 99
                              ? '99+'
                              : widget.chat.unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.chat.unreadCount > 9 ? 11 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(height: 24), // Empty space for alignment
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format the message preview based on content type
  String _formatMessagePreview(String message) {
    // Check for specific message types to format them
    if (message.startsWith('🎵')) {
      return '🎵 Voice message';
    } else if (message.startsWith('📎')) {
      // Extract file name from document message
      final fileName = message.replaceAll('📎 ', '');
      return '📎 $fileName';
    } else if (message.startsWith('📸')) {
      return '📸 Photo';
    } else if (message.isEmpty) {
      return 'No messages yet';
    } else {
      return message;
    }
  }
}
