import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:flutter/material.dart';

/// PostGrid displays a grid of posts, similar to Instagram's profile grid view.
/// It handles both empty states and populated grids with proper spacing and styling.
class PostGrid extends StatelessWidget {
  final List<Post> posts;
  final bool isCurrentUserProfile;
  final Function(Post) onPostTap;
  final Function(Post)? onPostOptionsTap;
  final VoidCallback? onCreatePostTap;

  const PostGrid({
    Key? key,
    required this.posts,
    required this.isCurrentUserProfile,
    required this.onPostTap,
    this.onPostOptionsTap,
    this.onCreatePostTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildPostsGrid();
    }
  }

  /// Builds a visually appealing empty state when no posts are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Engaging empty state icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),

          // Informative message
          Text(
            'No Posts Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),

          // Supportive subtext
          Text(
            isCurrentUserProfile
                ? 'Share your first photo or video'
                : 'This user hasn\'t posted anything yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          // Action button for current user
          if (isCurrentUserProfile && onCreatePostTap != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: onCreatePostTap,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Create First Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a grid of posts with consistent spacing and loading states
  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(1), // Minimal padding for tight grid
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildGridItem(post);
      },
    );
  }

  /// Builds a single grid item with proper image loading and tap handling
  Widget _buildGridItem(Post post) {
    return GestureDetector(
      onTap: () => onPostTap(post),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Post image with loading/error states
          CachedNetworkImage(
            imageUrl: post.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),

          // Option button for current user's posts
          if (isCurrentUserProfile && onPostOptionsTap != null)
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => onPostOptionsTap!(post),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

          // Show indicators for posts with multiple items or comments
          if (post.comments > 0)
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),

          if (post.likes > 0)
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
