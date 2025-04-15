import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// ProfileActionButtons displays the appropriate buttons based on whether
/// the profile belongs to the current user or another user.
///
/// For current user: "Edit Profile" button
/// For other users: "Follow/Unfollow" and "Message" buttons
class ProfileActionButtons extends StatelessWidget {
  // Required parameters
  final bool isCurrentUser;
  final bool isFollowing;

  // Optional callback functions
  final VoidCallback? onEditProfile;
  final VoidCallback? onToggleFollow;
  final VoidCallback? onMessageTap;

  const ProfileActionButtons({
    Key? key,
    required this.isCurrentUser,
    required this.isFollowing,
    this.onEditProfile,
    this.onToggleFollow,
    this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For current user - just show Edit Profile button
    if (isCurrentUser) {
      return _buildEditProfileButton();
    } else {
      // For other users - show Follow/Unfollow and Message buttons
      return Row(
        children: [
          // Follow/Unfollow button with expanded width
          Expanded(
            child: _buildFollowButton(),
          ),
          const SizedBox(width: 8),
          // Message button
          _buildMessageButton(),
        ],
      );
    }
  }

  /// Builds a full-width Edit Profile button with Instagram styling
  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onEditProfile,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        child: const Text('Edit Profile'),
      ),
    );
  }

  /// Builds a Follow/Unfollow button that changes appearance based on follow state
  Widget _buildFollowButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: isFollowing
          ? OutlinedButton(
              // Unfollow button (outlined style when already following)
              onPressed: onToggleFollow,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              child: const Text('Following'),
            )
          : ElevatedButton(
              // Follow button (filled style when not following)
              onPressed: onToggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              child: const Text('Follow'),
            ),
    );
  }

  /// Builds a Message button with icon
  Widget _buildMessageButton() {
    return OutlinedButton(
      onPressed: onMessageTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.message_outlined, size: 18),
          SizedBox(width: 8),
          Text(
            'Message',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
