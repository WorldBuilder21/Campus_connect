import 'dart:async';
import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/utils/audio_utils.dart';
import 'package:campus_conn/messages/widgets/chat/audio_recorder_widget.dart';

/// A beautiful message input field with typing animations and rich features
class MessageInputField extends StatefulWidget {
  /// Callback for sending a text message
  final Function(String) onSendMessage;

  /// Callback for opening attachments
  final VoidCallback onAttachmentTap;

  /// Callback for sending an audio message
  final Function(String) onSendAudio;

  /// Callback for typing status changes
  final Function(bool)? onTypingStatusChanged;

  /// Hint text to display when empty
  final String hintText;

  /// Constructor
  const MessageInputField({
    Key? key,
    required this.onSendMessage,
    required this.onAttachmentTap,
    required this.onSendAudio,
    this.onTypingStatusChanged,
    this.hintText = 'Type a message...',
  }) : super(key: key);

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;
  late final Animation<double> _sendButtonAnimation;

  // State flags
  bool _isComposing = false;
  bool _isRecording = false;
  bool _typingNotified = false;
  Timer? _typingTimer;

  // Audio utils
  final AudioUtils _audioUtils = AudioUtils();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _sendButtonAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Listen for text changes
    _textController.addListener(_handleTextChanged);

    // Initialize audio utility
    _audioUtils.initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  /// Handle text changes and update UI
  void _handleTextChanged() {
    final text = _textController.text;
    final isComposing = text.isNotEmpty;

    // Update animation state
    if (isComposing && !_isComposing) {
      _animationController.forward();
    } else if (!isComposing && _isComposing) {
      _animationController.reverse();
    }

    // Update composing state
    setState(() {
      _isComposing = isComposing;
    });

    // Handle typing status notification
    if (widget.onTypingStatusChanged != null) {
      // Notify of typing start
      if (isComposing && !_typingNotified) {
        _typingNotified = true;
        widget.onTypingStatusChanged!(true);

        // Set a timer to reset typing status after 2 seconds of inactivity
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (_typingNotified) {
            _typingNotified = false;
            widget.onTypingStatusChanged!(false);
          }
        });
      }

      // Refresh timer on each keystroke
      if (isComposing) {
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (_typingNotified) {
            _typingNotified = false;
            widget.onTypingStatusChanged!(false);
          }
        });
      }
    }
  }

  /// Send the text message
  void _handleSendPressed() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    widget.onSendMessage(message);

    // Clear input and reset state
    _textController.clear();

    // Explicitly reset typing status
    if (widget.onTypingStatusChanged != null && _typingNotified) {
      _typingNotified = false;
      widget.onTypingStatusChanged!(false);
    }

    // Keep focus on the input field after sending
    FocusScope.of(context).requestFocus(_focusNode);
  }

  /// Handle long press on the mic button to start recording
  void _handleRecordingStarted() {
    // Release text focus
    _focusNode.unfocus();

    setState(() {
      _isRecording = true;
    });
  }

  /// Handle audio recording completed
  void _handleRecordingCompleted(String path) {
    setState(() {
      _isRecording = false;
    });

    // Send the audio message
    widget.onSendAudio(path);
  }

  /// Handle audio recording cancelled
  void _handleRecordingCancelled() {
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: _isRecording
            ? AudioRecorderWidget(
                onCancel: _handleRecordingCancelled,
                onComplete: _handleRecordingCompleted,
              )
            : _buildInputBar(),
      ),
    );
  }

  /// Build the main input bar
  Widget _buildInputBar() {
    return Row(
      children: [
        // Attachment button
        _buildAttachmentButton(),

        // Text input field
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppTheme.primaryColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (text) {
                      if (_isComposing) {
                        _handleSendPressed();
                      }
                    },
                  ),
                ),

                // Emojis button (optional)
                if (_focusNode.hasFocus)
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                    splashRadius: 20,
                    onPressed: () {
                      // TODO: Implement emoji picker
                    },
                  ),
              ],
            ),
          ),
        ),

        // Send/mic button
        _buildSendButton(),
      ],
    );
  }

  /// Build the attachment button
  Widget _buildAttachmentButton() {
    return Container(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          onTap: widget.onAttachmentTap,
          child: Center(
            child: Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.grey[700],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  /// Build the send or microphone button
  Widget _buildSendButton() {
    return GestureDetector(
      onLongPress: _handleRecordingStarted,
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedBuilder(
          animation: _sendButtonAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Microphone button (hidden when composing)
                Opacity(
                  opacity: 1 - _sendButtonAnimation.value,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _handleRecordingStarted,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.mic,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Send button (visible when composing)
                Opacity(
                  opacity: _sendButtonAnimation.value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * _sendButtonAnimation.value),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: _isComposing ? _handleSendPressed : null,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
