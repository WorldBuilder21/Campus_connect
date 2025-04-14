import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// ProfileActionsSheet displays a bottom sheet with actions
/// that can be taken on a profile.
///
/// Different actions are shown based on whether the profile
/// belongs to the current user or another user.
class ProfileActionsSheet extends StatelessWidget {
  // Required parameters
  final bool isCurrentUserProfile;
  final bool isFollowing;

  // Optional callbacks
  final VoidCallback? onEditProfileTap;
  final VoidCallback? onCreatePostTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onToggleFollowTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onBlockUserTap;
  final VoidCallback? onReportUserTap;

  const ProfileActionsSheet({
    Key? key,
    required this.isCurrentUserProfile,
    required this.isFollowing,
    this.onEditProfileTap,
    this.onCreatePostTap,
    this.onLogoutTap,
    this.onToggleFollowTap,
    this.onMessageTap,
    this.onBlockUserTap,
    this.onReportUserTap,
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
            // Sheet header with divider
            _buildSheetHeader(),

            // Different actions based on whose profile it is
            if (isCurrentUserProfile)
              _buildCurrentUserActions()
            else
              _buildOtherUserActions(),
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
          'Options',
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

  /// Builds actions for current user's profile
  Widget _buildCurrentUserActions() {
    return Column(
      children: [
        // Edit Profile
        if (onEditProfileTap != null)
          _buildActionTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: onEditProfileTap!,
          ),

        // Create Post
        if (onCreatePostTap != null)
          _buildActionTile(
            icon: Icons.add_photo_alternate,
            title: 'Create Post',
            onTap: onCreatePostTap!,
          ),

        // Logout
        if (onLogoutTap != null)
          _buildActionTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: onLogoutTap!,
            isDestructive: true,
          ),
      ],
    );
  }

  /// Builds actions for other users' profiles
  Widget _buildOtherUserActions() {
    return Column(
      children: [
        // Follow/Unfollow
        if (onToggleFollowTap != null)
          _buildActionTile(
            icon: isFollowing
                ? Icons.person_remove_outlined
                : Icons.person_add_outlined,
            title: isFollowing ? 'Unfollow' : 'Follow',
            onTap: onToggleFollowTap!,
          ),

        // Message
        if (onMessageTap != null)
          _buildActionTile(
            icon: Icons.message_outlined,
            title: 'Message',
            onTap: onMessageTap!,
          ),

        // Block User (destructive action)
        if (onBlockUserTap != null)
          _buildActionTile(
            icon: Icons.block,
            title: 'Block User',
            onTap: onBlockUserTap!,
            isDestructive: true,
          ),

        // Report User (destructive action)
        if (onReportUserTap != null)
          _buildActionTile(
            icon: Icons.report_outlined,
            title: 'Report User',
            onTap: onReportUserTap!,
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
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.errorColor : null,
          fontWeight: isDestructive ? FontWeight.w500 : null,
        ),
      ),
      onTap: onTap,
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      visualDensity: VisualDensity.comfortable,
    );
  }
}
