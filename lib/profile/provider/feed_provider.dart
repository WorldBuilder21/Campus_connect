import 'package:campus_conn/profile/api/post_repository.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final feedProvider = Provider<FeedNotifier>((ref) {
  return FeedNotifier(ref);
});

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

  FeedNotifier(this._ref) : super(const AsyncValue.loading());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadFeed() async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    if (!_disposed) {
      state = const AsyncValue.loading();
    }
    _currentPage = 0;
    _hasMore = true;

    try {
      debugPrint('Loading feed from repository...');
      final postRepo = _ref.read(postRepositoryProvider);
      final posts =
          await postRepo.getFeedPosts(page: _currentPage, limit: _postsPerPage);

      if (!_disposed) {
        _ref.keepAlive();
        debugPrint('Loaded ${posts.length} posts');
        _hasMore = posts.length == _postsPerPage;
        _currentPage++;
        state = AsyncValue.data(posts);
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading feed: $e');
      if (!_disposed) {
        state = AsyncValue.error(e, stackTrace);
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (!_hasMore || _isLoading || state is AsyncError || _disposed) return;

    _isLoading = true;

    try {
      final currentPosts = state.value ?? [];
      final postRepo = _ref.read(postRepositoryProvider);

      debugPrint('Loading more posts from page $_currentPage');
      final newPosts =
          await postRepo.getFeedPosts(page: _currentPage, limit: _postsPerPage);

      if (!_disposed) {
        debugPrint('Loaded ${newPosts.length} more posts');
        _hasMore = newPosts.length == _postsPerPage;
        _currentPage++;

        _ref.keepAlive();

        state = AsyncValue.data([...currentPosts, ...newPosts]);
      }
    } catch (e, stackTrace) {
      // Keep existing posts on error
      if (!_disposed) {
        if (state.hasValue) {
          // Just log the error for pagination
          debugPrint('Error loading more posts: $e');
        } else {
          state = AsyncValue.error(e, stackTrace);
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refreshFeed() async {
    return loadFeed();
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
}
