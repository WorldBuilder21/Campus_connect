import 'package:flutter/material.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/widgets/common/avatar_widget.dart';

/// A beautiful custom app bar for the chat screen
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// User account of the chat recipient
  final Account user;

  /// Optional user online status
  final bool isOnline;

  /// Optional typing status
  final bool isTyping;

  /// Optional last seen time
  final DateTime? lastSeen;

  /// Back button action
  final VoidCallback onBack;

  /// Optional menu button action
  final VoidCallback? onMenuPressed;

  /// Constructor
  const ChatAppBar({
    Key? key,
    required this.user,
    this.isOnline = false,
    this.isTyping = false,
    this.lastSeen,
    required this.onBack,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Back button with improved tap area
              _buildBackButton(context),

              // Avatar
              AvatarWidget(
                imageUrl: user.image_url,
                radius: 18,
                isVerified: user.email_verified ?? false,
              ),

              const SizedBox(width: 12),

              // User details with status
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to user profile
                    // This could be implemented based on your navigation structure
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Username
                      Text(
                        user.username ?? 'User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Status text
                      _buildStatusText(),
                    ],
                  ),
                ),
              ),

              // Menu button
              if (onMenuPressed != null)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMenuPressed,
                  splashRadius: 24,
                  color: Colors.grey[700],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build back button with ripple effect
  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onBack,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
    );
  }

  /// Build status text based on typing, online, or last seen status
  Widget _buildStatusText() {
    // Show different status text based on user state
    if (isTyping) {
      return Row(
        children: [
          // Typing animation
          _buildTypingDots(),
          const SizedBox(width: 4),
          Text(
            'Typing...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
            ),
          ),
        ],
      );
    } else if (isOnline) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    } else if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);

      String lastSeenText;
      if (difference.inMinutes < 1) {
        lastSeenText = 'Just now';
      } else if (difference.inHours < 1) {
        lastSeenText = '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        lastSeenText = '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        lastSeenText = '${difference.inDays}d ago';
      } else {
        lastSeenText = 'Long time ago';
      }

      return Text(
        lastSeenText,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      );
    } else {
      // Default status
      return const SizedBox.shrink();
    }
  }

  /// Build animated typing dots
  Widget _buildTypingDots() {
    return SizedBox(
      width: 20,
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _TypingDot(delay: Duration(milliseconds: 300 * index));
        }),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Animated typing dot
class _TypingDot extends StatefulWidget {
  final Duration delay;

  const _TypingDot({required this.delay});

  @override
  _TypingDotState createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
