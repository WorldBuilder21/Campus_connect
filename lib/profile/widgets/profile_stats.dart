import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// ProfileStats displays user statistics like post count, followers, and following
/// in a clean, Instagram-style layout.
class ProfileStats extends StatelessWidget {
  final int postCount;
  final int followerCount;
  final int followingCount;

  // Optional callback functions for when stats are tapped
  final VoidCallback? onPostsTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileStats({
    Key? key,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    this.onPostsTap,
    this.onFollowersTap,
    this.onFollowingTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Posts', _formatCount(postCount), onPostsTap),
        _buildVerticalDivider(),
        _buildStatColumn(
            'Followers', _formatCount(followerCount), onFollowersTap),
        _buildVerticalDivider(),
        _buildStatColumn(
            'Following', _formatCount(followingCount), onFollowingTap),
      ],
    );
  }

  /// Builds a single stat column with count and label
  Widget _buildStatColumn(String label, String count, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a subtle vertical divider between stats
  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  /// Formats numbers for better readability
  /// (e.g., 1000 -> 1K, 1000000 -> 1M)
  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    }
  }
}
