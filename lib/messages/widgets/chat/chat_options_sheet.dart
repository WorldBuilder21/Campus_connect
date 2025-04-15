import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';

/// A beautiful options sheet for chat actions
class ChatOptionsSheet extends StatefulWidget {
  /// Chat data
  final Chat chat;

  /// Callback for viewing profile
  final VoidCallback onViewProfile;

  /// Callback for deleting chat
  final VoidCallback onDeleteChat;

  /// Callback for blocking user (optional)
  final VoidCallback? onBlockUser;

  /// Callback for reporting user (optional)
  final VoidCallback? onReportUser;

  /// Callback for searching chat (optional)
  final VoidCallback? onSearchChat;

  /// Constructor
  const ChatOptionsSheet({
    Key? key,
    required this.chat,
    required this.onViewProfile,
    required this.onDeleteChat,
    this.onBlockUser,
    this.onReportUser,
    this.onSearchChat,
  }) : super(key: key);

  @override
  State<ChatOptionsSheet> createState() => _ChatOptionsSheetState();
}

class _ChatOptionsSheetState extends State<ChatOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Selected option tracking
  int? _selectedOption;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // User info
              _buildUserInfo(),

              const Divider(),

              // Options list
              ..._buildOptions(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build user info header
  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: widget.chat.user.image_url != null
                ? NetworkImage(widget.chat.user.image_url!)
                : null,
            child: widget.chat.user.image_url == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.user.username ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.chat.user.email != null)
                  Text(
                    widget.chat.user.email!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the options list
  List<Widget> _buildOptions() {
    // Define all options
    final options = [
      _ChatOptionItem(
        icon: Icons.person_outline,
        label: 'View Profile',
        onTap: () => _selectOption(0, widget.onViewProfile),
      ),
      if (widget.onSearchChat != null)
        _ChatOptionItem(
          icon: Icons.search,
          label: 'Search in Conversation',
          onTap: () => _selectOption(1, widget.onSearchChat!),
        ),
      const Divider(),
      _ChatOptionItem(
        icon: Icons.delete_outline,
        label: 'Delete Chat',
        color: Colors.red,
        onTap: () => _showDeleteConfirmation(),
      ),
      if (widget.onBlockUser != null)
        _ChatOptionItem(
          icon: Icons.block,
          label: 'Block User',
          color: Colors.red[700],
          onTap: () => _showBlockConfirmation(),
        ),
      if (widget.onReportUser != null)
        _ChatOptionItem(
          icon: Icons.flag_outlined,
          label: 'Report User',
          color: Colors.orange[700],
          onTap: () => _selectOption(4, widget.onReportUser!),
        ),
    ];

    return options;
  }

  /// Handle option selection with animation
  void _selectOption(int index, VoidCallback callback) {
    setState(() {
      _selectedOption = index;
    });

    // Add delay for visual feedback
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.pop(context);
      callback();
    });
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              widget.onDeleteChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Show block confirmation dialog
  void _showBlockConfirmation() {
    final username = widget.chat.user.username ?? 'this user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block $username'),
        content: Text(
          'Are you sure you want to block $username? They will not be able to message you anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              widget.onBlockUser!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}

/// Individual option item
class _ChatOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ChatOptionItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty && icon == Icons.space_bar) {
      // It's a divider
      return const Divider();
    }

    final textColor = color ?? AppTheme.textPrimaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight:
                      color != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
