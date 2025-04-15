import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// Options menu for the chat list screen
class ChatOptionsMenu extends StatelessWidget {
  /// Callback for filter by unread option
  final VoidCallback onFilterByUnread;

  /// Callback for showing archived chats
  final VoidCallback onShowArchived;

  /// Callback for find new contacts
  final VoidCallback onFindNewContacts;

  /// Callback for settings
  final VoidCallback onSettings;

  /// Constructor
  const ChatOptionsMenu({
    Key? key,
    required this.onFilterByUnread,
    required this.onShowArchived,
    required this.onFindNewContacts,
    required this.onSettings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: const Offset(0, 48),
      onSelected: (value) {
        switch (value) {
          case 'unread':
            onFilterByUnread();
            break;
          case 'archived':
            onShowArchived();
            break;
          case 'contacts':
            onFindNewContacts();
            break;
          case 'settings':
            onSettings();
            break;
        }
      },
      elevation: 8,
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          value: 'unread',
          icon: Icons.mark_chat_unread_outlined,
          text: 'Unread chats',
        ),
        _buildPopupMenuItem(
          value: 'archived',
          icon: Icons.archive_outlined,
          text: 'Archived chats',
        ),
        _buildPopupMenuItem(
          value: 'contacts',
          icon: Icons.person_add_outlined,
          text: 'Find new contacts',
        ),
        _buildPopupMenuItem(
          value: 'settings',
          icon: Icons.settings_outlined,
          text: 'Chat settings',
        ),
      ],
      child: Icon(
        Icons.more_vert,
        color: Colors.grey[700],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String text,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.textPrimaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
