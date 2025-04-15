import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:campus_conn/auth/view/login/login_field.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/app_bar.dart';
import 'package:campus_conn/core/widget/loading_indicator.dart';
import 'package:campus_conn/home/screens/comment_screen.dart';
import 'package:campus_conn/messages/providers/chat_provider.dart';
import 'package:campus_conn/messages/screens/chat_screen.dart';
import 'package:campus_conn/profile/api/post_repository.dart';
import 'package:campus_conn/profile/components/post_options_sheet.dart';
import 'package:campus_conn/profile/components/profile_actions_sheet.dart';
import 'package:campus_conn/profile/provider/profile_provider.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:campus_conn/profile/screens/create_post_screen.dart';
import 'package:campus_conn/profile/screens/edit_post_screen.dart';
import 'package:campus_conn/profile/screens/edit_profile_screen.dart';
import 'package:campus_conn/profile/widgets/post_detail_modal.dart';
import 'package:campus_conn/profile/widgets/post_grid.dart';
import 'package:campus_conn/profile/widgets/profile_header.dart';
import 'package:campus_conn/profile/widgets/profile_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ProfileScreen displays a user's profile information and posts.
/// It follows Instagram's design patterns with tabs for posts and saved content.
class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool showBackBtn;

  const ProfileScreen({
    super.key,
    this.showBackBtn = false,
    required this.userId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Tab controller for posts/saved tabs
  late TabController _tabController;

  // Give _isCurrentUser a default value instead of making it late
  bool _isCurrentUser = false;
  bool _isCurrentUserInitialized = false;
  bool _disposed = false;

  // Store auth repository locally for use during logout
  AuthRepository? _authRepository;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 tabs: Posts and Saved
    _tabController = TabController(length: 2, vsync: this);

    // Initialize auth repository and current user status
    _initializeUserData();
  }

  // Safe initialization method
  Future<void> _initializeUserData() async {
    if (mounted) {
      try {
        // Save local reference to auth repository
        _authRepository = ref.read(authRepositoryProvider);

        // Initialize isCurrentUser by safely reading from profile provider
        final profileNotifier =
            ref.read(profileProvider(widget.userId).notifier);
        _isCurrentUser = profileNotifier.isCurrentUserProfile();
        _isCurrentUserInitialized = true;

        // Update UI if needed
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint('Error initializing profile data: $e');
        // Default to false for safety
        _isCurrentUser = false;
        _isCurrentUserInitialized = true;

        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure user data is initialized
    if (!_isCurrentUserInitialized) {
      _initializeUserData();

      // Show a loading indicator until initialization is complete
      return const Scaffold(
        body: Center(
          child: CircularLoadingIndicator(),
        ),
      );
    }

    // Watch profile state changes
    final profileState = ref.watch(profileProvider(widget.userId));

    // Auto-refresh follow status when screen is shown
    // This helps sync follow status between screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFollowStatus();
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'Profile',
        hasBackButton: widget.showBackBtn,
        actions: [
          // More options button
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showProfileOptions(),
          ),
        ],
      ),
      // Only show FAB when this is a standalone profile screen (not from bottom nav)
      floatingActionButton: profileState.when(
        data: (state) {
          // Use the cached value instead of calling the method
          // Only show FAB when accessed via back button (standalone screen)
          return widget.showBackBtn && _isCurrentUser
              ? _buildFloatingActionButton()
              : null;
        },
        loading: () => null,
        error: (_, __) => null,
      ),
      body: profileState.when(
        // Loading state
        loading: () => const Center(child: CircularLoadingIndicator()),

        // Error state
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Retry loading profile
                  if (!_disposed && mounted) {
                    ref
                        .read(profileProvider(widget.userId).notifier)
                        .refreshProfile();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),

        // Data loaded successfully
        data: (state) {
          if (state.user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }

          // Use NestedScrollView for collapsing header behavior
          return NestedScrollView(
            // Header sliver (profile info and tabs)
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Profile header section
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    user: state.user!,
                    state: state,
                    isCurrentUser: _isCurrentUser,
                    onEditProfile: () => _navigateToEditProfile(),
                    onToggleFollow: () => _toggleFollow(),
                    onMessageTap: (user) => _navigateToChat(user),
                  ),
                ),

                // Tab bar for posts/saved posts
                SliverPersistentHeader(
                  delegate: ProfileTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on)),
                        Tab(icon: Icon(Icons.bookmark_border)),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },

            // Tab view content
            body: TabBarView(
              controller: _tabController,
              children: [
                // Posts grid
                PostGrid(
                  posts: state.posts,
                  isCurrentUserProfile: _isCurrentUser,
                  onPostTap: (post) => _showPostDetails(post),
                  onPostOptionsTap:
                      _isCurrentUser ? (post) => _showPostOptions(post) : null,
                  onCreatePostTap:
                      _isCurrentUser ? () => _navigateToCreatePost() : null,
                ),

                // Saved posts grid
                PostGrid(
                  posts: state.savedPosts,
                  isCurrentUserProfile: _isCurrentUser,
                  onPostTap: (post) => _showPostDetails(post),
                  // No options button for saved posts
                  onCreatePostTap: null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Refresh follow status when entering the screen
  Future<void> _refreshFollowStatus() async {
    if (!_disposed && mounted) {
      try {
        await ref
            .read(profileProvider(widget.userId).notifier)
            .refreshFollowStatus();
        debugPrint('Follow status refreshed for profile ${widget.userId}');
      } catch (e) {
        debugPrint('Error refreshing follow status: $e');
      }
    }
  }

  /// Builds floating action button for creating new posts
  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        heroTag: 'profile_create_post_fab',
        elevation: 0,
        backgroundColor: Colors.transparent, // Use container's gradient
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  /// Shows profile options in a bottom sheet
  void _showProfileOptions() {
    if (!mounted || _disposed) return;

    final isFollowing =
        ref.read(profileProvider(widget.userId)).value?.isFollowing ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileActionsSheet(
        isCurrentUserProfile: _isCurrentUser,
        isFollowing: isFollowing,
        onEditProfileTap: () {
          Navigator.pop(context);
          _navigateToEditProfile();
        },
        onCreatePostTap: () {
          Navigator.pop(context);
          _navigateToCreatePost();
        },
        onLogoutTap: () {
          Navigator.pop(context);
          _logout();
        },
        onToggleFollowTap: () {
          Navigator.pop(context);
          _toggleFollow();
        },
        onMessageTap: () {
          Navigator.pop(context);
          final user = ref.read(profileProvider(widget.userId)).value?.user;
          if (user != null) {
            _navigateToChat(user);
          }
        },
      ),
    );
  }

  /// Shows post options for current user's posts
  void _showPostOptions(Post post) {
    if (!mounted || _disposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostOptionsSheet(
        onEditTap: () {
          Navigator.pop(context);
          _navigateToEditPost(post);
        },
        onDeleteTap: () {
          Navigator.pop(context);
          _confirmDeletePost(post.id);
        },
      ),
    );
  }

  /// Shows full post details in a modal bottom sheet
  void _showPostDetails(Post post) {
    if (!mounted || _disposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailModal(
        post: post,
        onPostLiked: (updatedPost) {
          if (!_disposed && mounted) {
            ref
                .read(profileProvider(widget.userId).notifier)
                .toggleLike(updatedPost.id);
          }
        },
        onPostBookmarked: (updatedPost) {
          if (!_disposed && mounted) {
            ref
                .read(profileProvider(widget.userId).notifier)
                .toggleBookmark(updatedPost.id);
          }
        },
        onCommentTap: () {
          Navigator.pop(context);
          if (!_disposed && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommentsScreen(post: post),
              ),
            );
          }
        },
      ),
    );
  }

  /// Shows confirmation dialog before deleting a post
  Future<void> _confirmDeletePost(String postId) async {
    if (!mounted || _disposed) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(postId);
              },
            ),
          ],
        );
      },
    );
  }

  /// Deletes a post with error handling
  Future<void> _deletePost(String postId) async {
    if (!mounted || _disposed) return;

    try {
      final postRepo = ref.read(postRepositoryProvider);
      await postRepo.deletePost(postId);

      // Remove post from UI
      if (!_disposed && mounted) {
        ref.read(profileProvider(widget.userId).notifier).removePost(postId);

        // Force a refresh after deletion to ensure UI consistency
        ref.read(profileProvider(widget.userId).notifier).refreshProfile();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (!_disposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Navigates to create post screen
  void _navigateToCreatePost() async {
    if (!mounted || _disposed) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );

    if (result != null && result is Post && !_disposed && mounted) {
      // Clear cache in post repository to force fresh data
      ref.read(postRepositoryProvider).clearCaches();

      // Add new post to the profile
      ref.read(profileProvider(widget.userId).notifier).addPost(result);

      // Schedule a background refresh after a delay to ensure DB consistency
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_disposed && mounted) {
          ref.read(profileProvider(widget.userId).notifier).refreshProfile();
        }
      });
    }
  }

  /// Navigates to edit post screen
  void _navigateToEditPost(Post post) async {
    if (!mounted || _disposed) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPostScreen(post: post)),
    );

    if (result != null && result is Post && !_disposed && mounted) {
      // Clear cache in post repository to force fresh data
      ref.read(postRepositoryProvider).clearCaches();

      // Update post in the profile
      ref.read(profileProvider(widget.userId).notifier).updatePost(result);

      // Schedule additional refresh after a delay to ensure DB consistency
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_disposed && mounted) {
          ref.read(profileProvider(widget.userId).notifier).refreshProfile();
        }
      });
    }
  }

  /// Navigates to edit profile screen
  void _navigateToEditProfile() async {
    if (!mounted || _disposed) return;

    final user = ref.read(profileProvider(widget.userId)).value?.user;
    if (user != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
      );

      // Refresh profile data
      if (!_disposed && mounted) {
        ref.read(profileProvider(widget.userId).notifier).refreshProfile();
      }
    }
  }

  /// Navigates to chat with user
  void _navigateToChat(dynamic user) async {
    if (!mounted || _disposed) return;

    try {
      // Create or get existing chat with this user
      final chat = await ref.read(chatProvider.notifier).createOrGetChat(user);

      if (chat != null && mounted && !_disposed) {
        // Navigate to chat screen with this chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: chat,
              recipientImageUrl: user.image_url,
            ),
          ),
        );
      } else {
        // Show error if chat couldn't be created
        if (mounted && !_disposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not start chat. Please try again later.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Toggles follow state for this profile
  void _toggleFollow() async {
    if (!mounted || _disposed) return;

    // Disable UI during follow/unfollow operation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating follow status...'),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await ref.read(profileProvider(widget.userId).notifier).toggleFollow();

      // Refresh follow status after a short delay to ensure DB consistency
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_disposed && mounted) {
          ref
              .read(profileProvider(widget.userId).notifier)
              .refreshFollowStatus();
        }
      });
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating follow status: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Logs out current user
  void _logout() async {
    if (!mounted || _disposed) return;

    // Store navigation context locally to avoid context issues
    final BuildContext navigatorContext = context;

    try {
      // Mark as disposed to prevent further UI updates
      _disposed = true;

      // Create a local variable to use for navigation
      final navigator = Navigator.of(navigatorContext);

      // Clear the post repository cache before logout
      ref.read(postRepositoryProvider).clearCaches();

      // Use the locally stored repository reference instead of accessing through provider
      if (_authRepository != null) {
        await _authRepository!.logout();
      } else {
        // If auth repository wasn't initialized, try to get it now
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.logout();
      }

      // Navigate to login screen
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginField()),
        (route) => false,
      );
    } catch (e) {
      // Reset disposed flag if error occurs
      _disposed = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
