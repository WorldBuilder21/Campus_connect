import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// PostOptionsSheet displays a bottom sheet with actions
/// that can be taken on a post (edit, delete, etc.)
class PostOptionsSheet extends StatelessWidget {
  // Callback functions
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onCopyLinkTap;

  const PostOptionsSheet({
    Key? key,
    this.onEditTap,
    this.onDeleteTap,
    this.onShareTap,
    this.onReportTap,
    this.onCopyLinkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet header with drag handle
            _buildSheetHeader(),

            // Post action options
            _buildActionsList(),

            // Bottom padding
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Builds the sheet header with a drag handle
  Widget _buildSheetHeader() {
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        const Text(
          'Post Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Divider(
          height: 24,
          thickness: 0.5,
        ),
      ],
    );
  }

  /// Builds the list of action items
  Widget _buildActionsList() {
    return Column(
      children: [
        // Edit Post option
        if (onEditTap != null)
          _buildActionTile(
            icon: Icons.edit,
            title: 'Edit Post',
            onTap: onEditTap!,
          ),

        // Delete Post option (destructive)
        if (onDeleteTap != null)
          _buildActionTile(
            icon: Icons.delete_outline,
            title: 'Delete Post',
            onTap: onDeleteTap!,
            isDestructive: true,
          ),

        // Share Post option
        if (onShareTap != null)
          _buildActionTile(
            icon: Icons.share_outlined,
            title: 'Share Post',
            onTap: onShareTap!,
          ),

        // Copy Link option
        if (onCopyLinkTap != null)
          _buildActionTile(
            icon: Icons.link,
            title: 'Copy Link',
            onTap: onCopyLinkTap!,
          ),

        // Report Post option (destructive)
        if (onReportTap != null)
          _buildActionTile(
            icon: Icons.report_outlined,
            title: 'Report Post',
            onTap: onReportTap!,
            isDestructive: true,
          ),
      ],
    );
  }

  /// Builds a standard action tile with icon, title, and tap handler
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : null,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDestructive ? AppTheme.errorColor : null,
          fontWeight: isDestructive ? FontWeight.w500 : null,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      visualDensity: VisualDensity.comfortable,
    );
  }
}
