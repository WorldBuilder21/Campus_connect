import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:flutter/material.dart';

/// PostDetailModal displays a full post view in a bottom sheet modal.
/// It mimics Instagram's post detail view with image, caption, comments, and action buttons.
class PostDetailModal extends StatefulWidget {
  final Post post;
  final Function(Post) onPostLiked;
  final Function(Post) onPostBookmarked;
  final VoidCallback? onCommentTap;

  const PostDetailModal({
    Key? key,
    required this.post,
    required this.onPostLiked,
    required this.onPostBookmarked,
    this.onCommentTap,
  }) : super(key: key);

  @override
  State<PostDetailModal> createState() => _PostDetailModalState();
}

class _PostDetailModalState extends State<PostDetailModal>
    with SingleTickerProviderStateMixin {
  // Local mutable post state for immediate UI updates
  late Post _post;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _post = widget.post;

    // Set up animation for like button
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle for better UX
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Modal header with user info and close button
          _buildHeader(),

          // Subtle divider for visual separation
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post image
                  _buildPostImage(),

                  // Action buttons (like, comment, bookmark)
                  _buildActionButtons(),

                  // Post content (likes count, caption, tags)
                  _buildPostContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header section with user avatar, username and close button
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // User avatar with subtle shadow and border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: _post.user.image_url != null
                  ? CachedNetworkImageProvider(_post.user.image_url!)
                  : null,
              child: _post.user.image_url == null
                  ? Text(
                      _post.user.username?.isNotEmpty == true
                          ? _post.user.username![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Username with navigation
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Close modal and navigate to user profile
                Navigator.of(context).pop();
                // Navigation to user profile would be handled by parent
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post.user.username ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_post.user.bio != null && _post.user.bio!.isNotEmpty)
                    Text(
                      _post.user.bio!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),

          // Close button
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the post image with appropriate styling and loading states
  Widget _buildPostImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.0, // Square aspect ratio like Instagram
        child: CachedNetworkImage(
          imageUrl: _post.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Image could not be loaded',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the action buttons row (like, comment, share, bookmark)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          // Like button with animation
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _post.isLiked ? _fadeAnimation.value : 1.0,
                child: IconButton(
                  icon: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _post.isLiked ? Colors.red : null,
                    size: 26,
                  ),
                  onPressed: _toggleLike,
                  splashRadius: 20,
                ),
              );
            },
          ),

          // Comment button
          IconButton(
            icon: const Icon(Icons.comment_outlined, size: 24),
            onPressed: widget.onCommentTap,
            splashRadius: 20,
          ),

          // Share button
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 24),
            onPressed: () {
              // Show share options (would implement sharing functionality)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing is not implemented yet'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            splashRadius: 20,
          ),

          const Spacer(),

          // Bookmark button
          IconButton(
            icon: Icon(
              _post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _post.isBookmarked ? AppTheme.primaryColor : null,
              size: 26,
            ),
            onPressed: _toggleBookmark,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  /// Builds the post content section (likes count, caption, tags, comments)
  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Likes count with proper formatting
          Text(
            '${_formatCount(_post.likes)} likes',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 10),

          // Caption with username and text
          if (_post.caption.isNotEmpty)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.black, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(
                    text: '${_post.user.username ?? 'User'} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: _post.caption),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Tags section with improved styling
          if (_post.tags.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: _post.tags.map((tag) => _buildTag(tag)).toList(),
              ),
            ),

          const SizedBox(height: 20),

          // Comments section header with clearer styling
          if (_post.comments > 0)
            GestureDetector(
              onTap: widget.onCommentTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[100],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.comment_outlined,
                        size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'View all ${_formatCount(_post.comments)} comments',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Posted time with subtle styling
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  // Dynamic timestamp based on post creation time
                  _post.createdAt != null
                      ? _formatTimestamp(_post.createdAt!)
                      : 'Recently',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format timestamp to show relative time (e.g. "2 hours ago")
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Builds a styled tag chip
  Widget _buildTag(String tag) {
    return GestureDetector(
      onTap: () {
        // Would navigate to tag search/results
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing posts with #$tag'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '#$tag',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Toggles the like state with animation
  void _toggleLike() {
    setState(() {
      _post = _post.copyWith(
        isLiked: !_post.isLiked,
        likes: _post.isLiked ? _post.likes - 1 : _post.likes + 1,
      );

      if (_post.isLiked) {
        _animationController.forward();
      }
    });

    // Call the parent callback
    widget.onPostLiked(_post);
  }

  /// Toggles the bookmark state with improved handling
  void _toggleBookmark() async {
    setState(() {
      _post = _post.copyWith(isBookmarked: !_post.isBookmarked);
    });

    // Call the parent callback to update the UI in the containing screen
    widget.onPostBookmarked(_post);

    // Log for debugging
    debugPrint(
        'Bookmark toggled for post ${_post.id}, isBookmarked: ${_post.isBookmarked}');
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
