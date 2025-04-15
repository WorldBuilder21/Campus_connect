import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/profile/model/profile_state.dart';
import 'package:campus_conn/profile/widgets/profile_action_buttons.dart';
import 'package:campus_conn/profile/widgets/profile_stats.dart';
import 'package:flutter/material.dart';

/// ProfileHeader displays the user's profile information including their
/// profile picture, username, bio, and statistics.
class ProfileHeader extends StatelessWidget {
  // Required parameters
  final Account user;
  final ProfileState state;
  final bool isCurrentUser;

  // Optional callback functions
  final VoidCallback? onEditProfile;
  final VoidCallback? onToggleFollow;
  final Function(Account)? onMessageTap;

  const ProfileHeader({
    Key? key,
    required this.user,
    required this.state,
    required this.isCurrentUser,
    this.onEditProfile,
    this.onToggleFollow,
    this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Avatar and Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture with improved styling
              _buildProfileAvatar(),
              const SizedBox(width: 20),

              // Stats (posts, followers, following)
              Expanded(
                child: ProfileStats(
                  postCount: state.posts.length,
                  followerCount: state.followerCount,
                  followingCount: state.followingCount,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Username with improved typography
          Text(
            user.username ?? 'User',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          // Bio with better spacing and formatting
          if (user.bio != null && user.bio!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                user.bio!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.3,
                ),
              ),
            ),

          // Email or additional info with subtle styling
          if (user.email != null)
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    user.email!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons with improved styling
          ProfileActionButtons(
            isCurrentUser: isCurrentUser,
            isFollowing: state.isFollowing,
            onEditProfile: onEditProfile,
            onToggleFollow: onToggleFollow,
            onMessageTap:
                onMessageTap != null ? () => onMessageTap!(user) : null,
          ),
        ],
      ),
    );
  }

  /// Builds a styled profile avatar with fallback to initials if no image
  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white],
            ),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
            // Improved shadow for depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(43),
            child: user.image_url != null
                ? CachedNetworkImage(
                    imageUrl: user.image_url!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildAvatarFallback(),
                  )
                : _buildAvatarFallback(),
          ),
        ),

        // If current user, add edit indicator with improved appearance
        if (isCurrentUser)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// Fallback widget when no profile image is available
  Widget _buildAvatarFallback() {
    // Get the first letter of username or 'U' as fallback
    final initial = (user.username?.isNotEmpty == true)
        ? user.username![0].toUpperCase()
        : 'U';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
