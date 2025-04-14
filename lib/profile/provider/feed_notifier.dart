import 'package:campus_conn/profile/api/post_repository.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider that gives access to the FeedNotifier
final feedProvider = Provider<FeedNotifier>((ref) {
  return FeedNotifier(ref);
});

// StateNotifierProvider that actually manages the feed state
final feedNotifier =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>((ref) {
  return FeedNotifier(ref)..loadFeed();
});

// Feed notifier
class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final Ref _ref;
  int _currentPage = 0;
  bool _hasMore = true;
  final int _postsPerPage = 10;
  bool _isLoading = false;
  bool _disposed = false;

  // Add cache timestamp to know when to refresh
  DateTime? _lastLoadTime;

  FeedNotifier(this._ref) : super(const AsyncValue.loading());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadFeed() async {
    // Prevent multiple simultaneous loads and avoid loading when disposed
    if (_isLoading || _disposed) return;

    _isLoading = true;

    // Always show loading state on complete refresh to avoid UI glitches
    if (!_disposed) {
      state = const AsyncValue.loading();
    }

    // Reset pagination
    _currentPage = 0;
    _hasMore = true;

    try {
      debugPrint('Loading feed from repository...');
      final postRepo = _ref.read(postRepositoryProvider);

      // Clear repository cache first to ensure fresh data
      postRepo.clearCaches();

      // Add try-finally to ensure _isLoading is reset
      try {
        final posts = await postRepo.getFeedPosts(
            page: _currentPage, limit: _postsPerPage);

        if (!_disposed) {
          // Keep reference alive
          _ref.keepAlive();

          debugPrint('Loaded ${posts.length} posts');
          _hasMore = posts.length == _postsPerPage;
          _currentPage++;

          // Update state
          state = AsyncValue.data(posts);

          // Update timestamp
          _lastLoadTime = DateTime.now();
        }
      } finally {
        _isLoading = false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading feed: $e');

      if (!_disposed) {
        state = AsyncValue.error(e, stackTrace);
      }

      _isLoading = false;
    }
  }

  Future<void> loadMorePosts() async {
    // Skip if we don't have more posts, are already loading, are in error state, or are disposed
    if (!_hasMore || _isLoading || state is AsyncError || _disposed) return;

    _isLoading = true;

    try {
      // Get current posts - only proceed if we have some
      final currentPosts = state.value ?? [];
      if (currentPosts.isEmpty) {
        _isLoading = false;
        return;
      }

      final postRepo = _ref.read(postRepositoryProvider);

      debugPrint('Loading more posts from page $_currentPage');
      final newPosts =
          await postRepo.getFeedPosts(page: _currentPage, limit: _postsPerPage);

      if (!_disposed) {
        debugPrint('Loaded ${newPosts.length} more posts');
        _hasMore = newPosts.length == _postsPerPage;
        _currentPage++;

        _ref.keepAlive();

        // Append new posts to existing posts
        state = AsyncValue.data([...currentPosts, ...newPosts]);
      }
    } catch (e, stackTrace) {
      // Keep existing posts on error
      if (!_disposed) {
        if (state.hasValue) {
          // Just log the error for pagination but don't update state
          debugPrint('Error loading more posts: $e');
        } else {
          state = AsyncValue.error(e, stackTrace);
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  // Check if feed needs a refresh based on time
  bool get needsRefresh {
    // Always refresh if never loaded or if it's been more than 1 minute
    return _lastLoadTime == null ||
        DateTime.now().difference(_lastLoadTime!) > const Duration(minutes: 1);
  }

  // Refresh feed, potentially keeping current posts if refresh fails
  Future<void> refreshFeed() async {
    if (_isLoading || _disposed) return;

    // Save current posts before refreshing for fallback
    final currentPosts = state.hasValue ? state.value! : <Post>[];

    _isLoading = true;

    // Don't change state to loading to avoid flicker
    // This way, current posts remain visible during refresh

    // Reset pagination
    _currentPage = 0;
    _hasMore = true;

    try {
      debugPrint('Refreshing feed...');
      final postRepo = _ref.read(postRepositoryProvider);

      // Clear caches first to ensure fresh data
      postRepo.clearCaches();

      final posts =
          await postRepo.getFeedPosts(page: _currentPage, limit: _postsPerPage);

      if (!_disposed) {
        // Keep reference alive
        _ref.keepAlive();

        debugPrint('Loaded ${posts.length} posts on refresh');
        _hasMore = posts.length == _postsPerPage;
        _currentPage++;

        // Update state with new posts
        state = AsyncValue.data(posts);

        // Update timestamp
        _lastLoadTime = DateTime.now();
      }
    } catch (e, stackTrace) {
      debugPrint('Error refreshing feed: $e');

      if (!_disposed) {
        // If we had posts before, keep them instead of showing error
        if (currentPosts.isNotEmpty) {
          // Keep current posts but still mark as needing refresh
          _lastLoadTime = null;
          debugPrint('Keeping current posts after refresh failure');
        } else {
          // Only show error if we had no posts before
          state = AsyncValue.error(e, stackTrace);
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  void toggleLike(String postId) {
    if (!state.hasValue || _disposed) return;

    final posts = [...state.value!];
    final index = posts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final post = posts[index];
    final isLiked = post.isLiked;

    // Optimistically update UI
    posts[index] = post.copyWith(
      isLiked: !isLiked,
      likes: isLiked ? post.likes - 1 : post.likes + 1,
    );

    if (!_disposed) {
      state = AsyncValue.data(posts);

      // Update in database
      _ref.read(postRepositoryProvider).toggleLike(postId).catchError((e) {
        // Revert on error
        if (!_disposed) {
          posts[index] = post;
          state = AsyncValue.data(posts);
          debugPrint('Error toggling like: $e');
        }
      });
    }
  }

  void toggleBookmark(String postId) {
    if (!state.hasValue || _disposed) return;

    final posts = [...state.value!];
    final index = posts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final post = posts[index];
    final isBookmarked = post.isBookmarked;

    // Optimistically update UI
    posts[index] = post.copyWith(
      isBookmarked: !isBookmarked,
    );

    if (!_disposed) {
      state = AsyncValue.data(posts);

      // Update in database
      _ref.read(postRepositoryProvider).toggleBookmark(postId).catchError((e) {
        // Revert on error
        if (!_disposed) {
          posts[index] = post;
          state = AsyncValue.data(posts);
          debugPrint('Error toggling bookmark: $e');
        }
      });
    }
  }

  // Add a new post to the feed (used after creating a post)
  void addPost(Post post) {
    if (!state.hasValue || _disposed) return;

    // Add to the beginning of the feed
    final currentPosts = state.value!;
    final updatedPosts = [post, ...currentPosts];

    if (!_disposed) {
      state = AsyncValue.data(updatedPosts);

      // Force a cache refresh immediately
      _lastLoadTime = null;
      debugPrint('Post added to feed and cache time reset');
    }
  }

  // Force a full refresh of feed on next check
  void invalidateCache() {
    _lastLoadTime = null;
    _ref.read(postRepositoryProvider).clearCaches();
    debugPrint('Feed cache explicitly invalidated');
  }
}
