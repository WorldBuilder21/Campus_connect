import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/schema/message_schema.dart';
import 'package:campus_conn/messages/widgets/common/avatar_widget.dart';
import 'package:campus_conn/messages/widgets/common/message_timestamp.dart';
import 'package:campus_conn/messages/widgets/chat/document_preview.dart';
import 'package:campus_conn/messages/widgets/chat/media_preview.dart';
import 'package:campus_conn/messages/widgets/chat/audio_player_widget.dart';

/// A beautiful message bubble with support for text, media, and documents
class MessageBubble extends StatefulWidget {
  /// The message data
  final Message message;

  /// Whether this message was sent by the current user
  final bool isMe;

  /// Whether to show the sender's avatar
  final bool showAvatar;

  /// Whether this is the last message in a group
  final bool isLastInGroup;

  /// Whether this is the first message in a group
  final bool isFirstInGroup;

  /// Whether the day changed with this message
  final bool showDateSeparator;

  /// Sender's avatar URL
  final String? senderAvatarUrl;

  /// Whether the sender is verified
  final bool senderVerified;

  /// Callback for playing audio
  final Function(String)? onPlayAudio;

  /// Constructor
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.isLastInGroup = true,
    this.isFirstInGroup = true,
    this.showDateSeparator = false,
    this.senderAvatarUrl,
    this.senderVerified = false,
    this.onPlayAudio,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Track whether message has been seen for animation
  bool _hasBeenSeen = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Define scale animation for subtle pop-in effect
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start animation
    _animationController.forward();

    // Delay "seen" status for sent messages animation
    if (widget.isMe && widget.message.isRead && !_hasBeenSeen) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _hasBeenSeen = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate "seen" status change
    if (widget.isMe &&
        widget.message.isRead &&
        !oldWidget.message.isRead &&
        !_hasBeenSeen) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _hasBeenSeen = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date separator if needed
        if (widget.showDateSeparator) _buildDateSeparator(),

        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              alignment:
                  widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
            child: Row(
              mainAxisAlignment:
                  widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar (only for received messages)
                if (!widget.isMe && widget.showAvatar)
                  AvatarWidget(
                    imageUrl: widget.senderAvatarUrl,
                    radius: 16,
                    isVerified: widget.senderVerified,
                  )
                else if (!widget.isMe)
                  // Space placeholder when avatar is hidden but alignment needed
                  const SizedBox(width: 32),

                // Message content
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: EdgeInsets.only(
                      left: widget.isMe ? 0 : 8,
                      right: widget.isMe ? 8 : 0,
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build the date separator
  Widget _buildDateSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
              indent: 16,
              endIndent: 8,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: MessageTimestamp(
              timestamp: widget.message.timestamp,
              format: TimestampFormat.dateSeparator,
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
              indent: 8,
              endIndent: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the main message content based on type
  Widget _buildMessageContent() {
    // Background colors for message bubbles
    final backgroundColor =
        widget.isMe ? AppTheme.primaryColor : Colors.grey[200];

    // Different text colors for contrast
    final textColor = widget.isMe ? Colors.white : AppTheme.textPrimaryColor;

    // Border radius - different shape based on position in group
    final borderRadius = _getBubbleBorderRadius();

    // Check message type based on content
    Widget messageContent;

    if (widget.message.content.startsWith('🎵')) {
      // Audio message
      messageContent = AudioPlayerWidget(
        message: widget.message,
        isMe: widget.isMe,
        onPlayAudio: widget.onPlayAudio,
      );
    } else if (widget.message.imageUrl != null &&
        !widget.message.content.startsWith('📎')) {
      // Image message
      messageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaPreview(
            url: widget.message.imageUrl!,
            borderRadius: _getMediaBorderRadius(),
          ),
          if (widget.message.content.isNotEmpty &&
              !widget.message.content.startsWith('📸'))
            Padding(
              padding:
                  const EdgeInsets.only(top: 6, bottom: 6, left: 6, right: 6),
              child: Text(
                widget.message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
        ],
      );
    } else if (widget.message.imageUrl != null &&
        widget.message.content.startsWith('📎')) {
      // Document message
      messageContent = DocumentPreview(
        fileName: widget.message.content.replaceAll('📎 ', ''),
        fileUrl: widget.message.imageUrl!,
        isMe: widget.isMe,
      );
    } else {
      // Regular text message
      messageContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          widget.message.content,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            height: 1.3,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Message content (text, media, etc.)
          messageContent,

          // Time and read status
          _buildMessageFooter(textColor),
        ],
      ),
    );
  }

  /// Build message footer with time and read status
  Widget _buildMessageFooter(Color textColor) {
    // Skip footer for media messages - it's already in the content
    if ((widget.message.imageUrl != null &&
            !widget.message.content.startsWith('📎')) ||
        widget.message.content.startsWith('🎵')) {
      return const SizedBox.shrink();
    }

    // Footer with timestamp and read status
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 6, left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time
          MessageTimestamp(
            timestamp: widget.message.timestamp,
            color: widget.isMe ? textColor.withOpacity(0.7) : Colors.grey[600],
            style: const TextStyle(
              fontSize: 12,
            ),
          ),

          // Read status for sent messages
          if (widget.isMe) ...[
            const SizedBox(width: 4),
            _buildReadStatus(),
          ],
        ],
      ),
    );
  }

  /// Build the read status indicator with animation
  Widget _buildReadStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: widget.message.isRead
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(
                  opacity: _hasBeenSeen ? value : 0,
                  child: child,
                );
              },
              child: const Icon(
                Icons.done_all,
                size: 14,
                color: Colors.white70,
              ),
            )
          : const Icon(
              Icons.done,
              size: 14,
              color: Colors.white54,
            ),
    );
  }

  /// Get appropriate border radius based on position in message group
  BorderRadius _getBubbleBorderRadius() {
    // Base radius
    const double radius = 18;
    const double cornerRadius = 4;

    if (widget.isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(radius),
        bottomLeft: const Radius.circular(radius),
        topRight: widget.isFirstInGroup
            ? const Radius.circular(radius)
            : const Radius.circular(cornerRadius),
        bottomRight: widget.isLastInGroup
            ? const Radius.circular(cornerRadius)
            : const Radius.circular(radius),
      );
    } else {
      return BorderRadius.only(
        topRight: const Radius.circular(radius),
        bottomRight: const Radius.circular(radius),
        topLeft: widget.isFirstInGroup
            ? const Radius.circular(radius)
            : const Radius.circular(cornerRadius),
        bottomLeft: widget.isLastInGroup
            ? const Radius.circular(cornerRadius)
            : const Radius.circular(radius),
      );
    }
  }

  /// Get border radius for media content
  BorderRadius _getMediaBorderRadius() {
    // Smaller corner radius for media
    const double radius = 16;
    const double cornerRadius = 4;

    if (widget.isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(radius),
        bottomLeft: const Radius.circular(radius),
        topRight: widget.isFirstInGroup
            ? const Radius.circular(radius)
            : const Radius.circular(cornerRadius),
        bottomRight: widget.isLastInGroup
            ? const Radius.circular(cornerRadius)
            : const Radius.circular(radius),
      );
    } else {
      return BorderRadius.only(
        topRight: const Radius.circular(radius),
        bottomRight: const Radius.circular(radius),
        topLeft: widget.isFirstInGroup
            ? const Radius.circular(radius)
            : const Radius.circular(cornerRadius),
        bottomLeft: widget.isLastInGroup
            ? const Radius.circular(cornerRadius)
            : const Radius.circular(radius),
      );
    }
  }
}
