import 'package:campus_conn/profile/api/post_repository.dart';
import 'package:campus_conn/profile/model/profile_state.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

part 'profile_provider.g.dart';

// Profile provider that uses Riverpod's StateNotifier
@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isDisposed = false;

  @override
  FutureOr<ProfileState> build(String userId) {
    // Cache isCurrentUser to avoid disposal issues
    final currentUserId = _supabase.auth.currentUser?.id;
    _isCurrentUser = currentUserId == userId;
    _isDisposed = false;

    return _loadProfile(userId);
  }

  // Cache this value to avoid accessing Supabase during disposal
  bool _isCurrentUser = false;

  // Load profile data
  Future<ProfileState> _loadProfile(String userId) async {
    try {
      debugPrint('Loading profile for user: $userId');

      // Use the cached value to determine if this is the current user
      final currentUserId = _supabase.auth.currentUser?.id;

      // Fetch user data from Supabase
      final userResponse = await _supabase
          .from('accounts')
          .select('*')
          .eq('id', userId)
          .single();

      final user = Account.fromJson(userResponse);

      // Check if the current user is following this profile
      bool isFollowing = false;
      if (currentUserId != null && userId != currentUserId) {
        final followResponse = await _supabase.from('follows').select().match({
          'follower_id': currentUserId,
          'following_id': userId,
        }).maybeSingle();

        isFollowing = followResponse != null;
      }

      // Get follower count
      final followerCountResponse = await _supabase
          .from('follows')
          .select('*')
          .eq('following_id', userId);

      final followerCount = followerCountResponse.length ?? 0;

      // Get following count
      final followingCountResponse =
          await _supabase.from('follows').select('*').eq('follower_id', userId);

      final followingCount = followingCountResponse.length ?? 0;

      // Get post repository and load posts
      final postRepo = ref.read(postRepositoryProvider);

      // Force a cache clear to ensure fresh data
      postRepo.clearCaches();

      final posts = await postRepo.getUserPosts(userId);

      // Only load saved posts for current user
      List<Post> savedPosts = [];
      if (currentUserId == userId) {
        savedPosts = await postRepo.getSavedPosts();
        debugPrint('Loaded ${savedPosts.length} saved posts for current user');
      }

      ref.keepAlive();

      return ProfileState(
        user: user,
        posts: posts,
        savedPosts: savedPosts,
        isLoading: false,
        isFollowing: isFollowing,
        followerCount: followerCount,
        followingCount: followingCount,
        error: null,
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return ProfileState(
        posts: [],
        savedPosts: [],
        isLoading: false,
        isFollowing: false,
        followerCount: 0,
        followingCount: 0,
        error: e.toString(),
      );
    }
  }

  // Refresh only saved posts
  Future<void> refreshSavedPosts() async {
    if (state.value == null || _isDisposed) return;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || !_isCurrentUser) return;

    try {
      debugPrint('Refreshing saved posts specifically');
      final postRepo = ref.read(postRepositoryProvider);
      final savedPosts = await postRepo.getSavedPosts();

      // Update only the saved posts in the state
      if (_isDisposed) return;

      state = AsyncValue.data(state.value!.copyWith(
        savedPosts: savedPosts,
      ));

      debugPrint(
          'Successfully refreshed saved posts: ${savedPosts.length} posts');
    } catch (e) {
      debugPrint('Error refreshing saved posts: $e');
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    debugPrint('Refreshing profile for user: $userId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProfile(userId));
  }

  // Force refresh follow status independently
  Future<void> refreshFollowStatus() async {
    if (state.value == null || _isDisposed) return;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // Check follow status directly from database
      final followResponse = await _supabase.from('follows').select().match({
        'follower_id': currentUserId,
        'following_id': userId,
      }).maybeSingle();

      final isFollowing = followResponse != null;

      // Update follower count
      final followerCountResponse = await _supabase
          .from('follows')
          .select('*')
          .eq('following_id', userId);

      final followerCount = followerCountResponse.length;

      // Only update if we have a value and follow status changed
      if (state.value != null &&
          (state.value!.isFollowing != isFollowing ||
              state.value!.followerCount != followerCount)) {
        state = AsyncValue.data(state.value!.copyWith(
          isFollowing: isFollowing,
          followerCount: followerCount,
        ));

        debugPrint(
            'Follow status updated: isFollowing=$isFollowing, followerCount=$followerCount');
      }
    } catch (e) {
      debugPrint('Error refreshing follow status: $e');
    }
  }

  // Check if profile belongs to current user - now uses cached value
  bool isCurrentUserProfile() {
    return _isCurrentUser;
  }

  // Toggle follow status with improved handling
  Future<void> toggleFollow() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || state.value == null || _isDisposed) return;

    // Get current state values
    final isCurrentlyFollowing = state.value!.isFollowing;
    final currentFollowerCount = state.value!.followerCount;

    // Optimistically update UI
    state = AsyncValue.data(state.value!.copyWith(
      isFollowing: !isCurrentlyFollowing,
      followerCount: isCurrentlyFollowing
          ? currentFollowerCount - 1
          : currentFollowerCount + 1,
    ));

    try {
      if (!isCurrentlyFollowing) {
        // Follow user
        await _supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('User $currentUserId followed user $userId');
      } else {
        // Unfollow user
        await _supabase.from('follows').delete().match({
          'follower_id': currentUserId,
          'following_id': userId,
        });
        debugPrint('User $currentUserId unfollowed user $userId');
      }

      // Wait a moment for database to update
      await Future.delayed(const Duration(milliseconds: 300));

      // Force refresh follow status from database to ensure consistency
      await refreshFollowStatus();
    } catch (e) {
      debugPrint('Error toggling follow status: $e');
      // Revert on error
      state = AsyncValue.data(state.value!.copyWith(
        isFollowing: isCurrentlyFollowing,
        followerCount: currentFollowerCount,
        error: 'Failed to update follow status: $e',
      ));
    }
  }

  // Add a post to the profile's posts list with improved refresh
  Future<void> addPost(Post post) async {
    if (state.value == null || _isDisposed) return;

    debugPrint('Adding post to profile: ${post.id}');

    // Update local state immediately for a responsive UI
    state = AsyncValue.data(state.value!.copyWith(
      posts: [post, ...state.value!.posts],
    ));

    // Force a refresh to ensure the post is properly displayed
    // This is important because it will fetch fresh data from the database
    try {
      // Clear caches in post repository to ensure fresh data
      ref.read(postRepositoryProvider).clearCaches();

      // Small delay to ensure the database has time to update
      await Future.delayed(const Duration(milliseconds: 300));
      await refreshProfile();
      debugPrint('Profile refreshed after adding post');
    } catch (e) {
      debugPrint('Error refreshing after adding post: $e');
    }
  }

  // Update a post in the profile's posts list
  Future<void> updatePost(Post updatedPost) async {
    if (state.value == null || _isDisposed) return;

    debugPrint('Updating post in profile: ${updatedPost.id}');

    final updatedPosts = [...state.value!.posts];
    final index = updatedPosts.indexWhere((post) => post.id == updatedPost.id);

    if (index != -1) {
      updatedPosts[index] = updatedPost;
      state = AsyncValue.data(state.value!.copyWith(posts: updatedPosts));

      // Force a refresh to ensure the post is properly updated
      try {
        // Clear caches in post repository to ensure fresh data
        ref.read(postRepositoryProvider).clearCaches();

        // Small delay to ensure the database has time to update
        await Future.delayed(const Duration(milliseconds: 300));
        await refreshProfile();
        debugPrint('Profile refreshed after updating post');
      } catch (e) {
        debugPrint('Error refreshing after updating post: $e');
      }
    }
  }

  // Remove a post from the profile's posts list
  void removePost(String postId) {
    if (state.value == null || _isDisposed) return;

    debugPrint('Removing post from profile: $postId');

    final updatedPosts =
        state.value!.posts.where((post) => post.id != postId).toList();
    state = AsyncValue.data(state.value!.copyWith(posts: updatedPosts));
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId) async {
    if (state.value == null || _isDisposed) return;

    final postRepo = ref.read(postRepositoryProvider);
    final updatedPosts = [...state.value!.posts];
    final index = updatedPosts.indexWhere((post) => post.id == postId);

    // Also check saved posts
    final updatedSavedPosts = [...state.value!.savedPosts];
    final savedIndex =
        updatedSavedPosts.indexWhere((post) => post.id == postId);

    // Update in posts list
    if (index != -1) {
      final post = updatedPosts[index];
      final isCurrentlyLiked = post.isLiked;

      // Optimistically update UI
      updatedPosts[index] = post.copyWith(
        isLiked: !isCurrentlyLiked,
        likes: isCurrentlyLiked ? post.likes - 1 : post.likes + 1,
      );
    }

    // Also update in saved posts list if present
    if (savedIndex != -1) {
      final savedPost = updatedSavedPosts[savedIndex];
      final isCurrentlyLiked = savedPost.isLiked;

      updatedSavedPosts[savedIndex] = savedPost.copyWith(
        isLiked: !isCurrentlyLiked,
        likes: isCurrentlyLiked ? savedPost.likes - 1 : savedPost.likes + 1,
      );
    }

    // Update state with both changes
    state = AsyncValue.data(state.value!
        .copyWith(posts: updatedPosts, savedPosts: updatedSavedPosts));

    try {
      // Update in database
      await postRepo.toggleLike(postId);
    } catch (e) {
      // Revert on error - we need to revert both lists
      debugPrint('Error toggling like: $e');
      state = AsyncValue.data(state.value!.copyWith(
        posts: state.value!.posts,
        savedPosts: state.value!.savedPosts,
        error: 'Failed to update like status: $e',
      ));
    }
  }

  // Toggle bookmark on a post with improved handling for saved posts tab
  Future<void> toggleBookmark(String postId) async {
    if (state.value == null || _isDisposed) return;

    final postRepo = ref.read(postRepositoryProvider);

    // Check if this is in posts list or saved posts list
    var updatedPosts = [...state.value!.posts];
    var postsIndex = updatedPosts.indexWhere((post) => post.id == postId);

    var updatedSavedPosts = [...state.value!.savedPosts];
    var savedPostsIndex =
        updatedSavedPosts.indexWhere((post) => post.id == postId);

    Post? postToUpdate;
    bool currentlyBookmarked = false;

    if (postsIndex != -1) {
      postToUpdate = updatedPosts[postsIndex];
      currentlyBookmarked = postToUpdate.isBookmarked;

      // Update in posts list
      updatedPosts[postsIndex] = postToUpdate.copyWith(
        isBookmarked: !currentlyBookmarked,
      );

      debugPrint(
          'Toggling bookmark for post $postId in posts list. Was bookmarked: $currentlyBookmarked');
    }

    // Handle saved posts tab updates
    if (savedPostsIndex != -1) {
      postToUpdate = updatedSavedPosts[savedPostsIndex];
      currentlyBookmarked = true;

      // Remove from saved posts list if unbookmarking
      debugPrint('Removing post $postId from saved posts list (unbookmarking)');
      updatedSavedPosts.removeAt(savedPostsIndex);
    } else if (postsIndex != -1 && !currentlyBookmarked) {
      // Add to saved posts if bookmarking
      debugPrint('Adding post $postId to saved posts list (bookmarking)');
      updatedSavedPosts.add(postToUpdate!.copyWith(isBookmarked: true));
    }

    // Update UI immediately
    state = AsyncValue.data(state.value!.copyWith(
      posts: updatedPosts,
      savedPosts: updatedSavedPosts,
    ));

    try {
      // Update in database
      await postRepo.toggleBookmark(postId);

      // Refresh saved posts from server after a short delay
      // This ensures our local state matches the server state
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isDisposed) return;
        refreshSavedPosts();
      });
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');

      // Revert UI on error
      state = AsyncValue.data(state.value!.copyWith(
        posts: state.value!.posts,
        savedPosts: state.value!.savedPosts,
        error: 'Failed to update bookmark status: $e',
      ));
    }
  }

  // Add post to saved posts directly
  Future<void> addToSavedPosts(Post post) async {
    if (state.value == null || !_isCurrentUser || _isDisposed) return;

    final updatedSavedPosts = [...state.value!.savedPosts];

    // Only add if not already in saved posts
    if (!updatedSavedPosts.any((p) => p.id == post.id)) {
      // Make sure the post is marked as bookmarked
      final postWithBookmark = post.copyWith(isBookmarked: true);
      updatedSavedPosts.add(postWithBookmark);

      // Update UI immediately
      state = AsyncValue.data(state.value!.copyWith(
        savedPosts: updatedSavedPosts,
      ));

      debugPrint('Added post ${post.id} directly to saved posts tab');
    }
  }

  // Remove post from saved posts directly
  Future<void> removeFromSavedPosts(String postId) async {
    if (state.value == null || !_isCurrentUser || _isDisposed) return;

    final updatedSavedPosts = [...state.value!.savedPosts];
    final index = updatedSavedPosts.indexWhere((p) => p.id == postId);

    if (index != -1) {
      updatedSavedPosts.removeAt(index);

      // Update UI immediately
      state = AsyncValue.data(state.value!.copyWith(
        savedPosts: updatedSavedPosts,
      ));

      debugPrint('Removed post $postId directly from saved posts tab');
    }
  }
}
