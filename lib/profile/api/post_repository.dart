import 'dart:io';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:path/path.dart';

part 'post_repository.g.dart';

@Riverpod(keepAlive: true)
PostRepository postRepository(PostRepositoryRef _) => PostRepository();

class PostRepository {
  final _client = Supabase.instance.client;

  // Cache control
  bool _needsFreshData = true; // Start with fresh data by default
  Map<String, List<Post>> _cachedUserPosts = {};
  Map<String, DateTime> _lastCacheTime = {};
  DateTime _lastGlobalRefresh = DateTime.now()
      .subtract(const Duration(minutes: 10)); // Force initial refresh

  // Clear all caches
  void clearCaches() {
    _cachedUserPosts.clear();
    _lastCacheTime.clear();
    _needsFreshData = true;
    _lastGlobalRefresh = DateTime.now();
    debugPrint('PostRepository: All caches cleared');
  }

  // Get posts from user feed
  Future<List<Post>> getFeedPosts({int page = 0, int limit = 10}) async {
    try {
      // Always check if we need fresh data
      final isTimeToRefresh = DateTime.now().difference(_lastGlobalRefresh) >
          const Duration(minutes: 2);

      if (isTimeToRefresh) {
        _needsFreshData = true;
        _lastGlobalRefresh = DateTime.now();
        debugPrint('PostRepository: Feed cache expired, refreshing data');
      }

      final currentUserId = _client.auth.currentUser?.id;

      // First get the posts with basic info
      final response = await _client
          .from('posts')
          .select('''
          *,
          user:user_id(
            id, 
            username, 
            email, 
            image_url, 
            email_verified, 
            created_at
          ),
          likes(count)
        ''')
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      debugPrint('Found ${response.length} feed posts');

      // Prepare a list to hold the processed posts
      List<Post> processedPosts = [];

      // Process each post individually
      for (final json in response) {
        final postId = json['id'] as String;

        // Parse user data
        final userData = json['user'] as Map<String, dynamic>;
        final user = Account.fromJson(userData);

        // Extract likes count
        int likesCount = 0;
        if (json['likes'] != null && (json['likes'] as List).isNotEmpty) {
          likesCount = (json['likes'][0]['count'] as int?) ?? 0;
        }

        // Check if current user liked this post
        bool isLiked = false;
        if (currentUserId != null) {
          final likesResponse = await _client
              .from('likes')
              .select('id')
              .eq('post_id', postId)
              .eq('user_id', currentUserId)
              .limit(1);
          isLiked = likesResponse.isNotEmpty;
        }

        // Check if current user bookmarked this post
        bool isBookmarked = false;
        if (currentUserId != null) {
          final bookmarksResponse = await _client
              .from('bookmarks')
              .select('id')
              .eq('post_id', postId)
              .eq('user_id', currentUserId)
              .limit(1);
          isBookmarked = bookmarksResponse.isNotEmpty;
        }

        // Extract tags
        List<String> tags = [];
        if (json['tags'] != null) {
          tags = List<String>.from(json['tags']);
        } else {
          // Extract hashtags from caption
          final regex = RegExp(r'#(\w+)');
          final matches = regex.allMatches(json['caption'] as String);
          tags = matches.map((match) => match.group(1)!).toList();
        }

        // Extract comments count (if available)
        int commentsCount = json['comments'] ?? 0;

        processedPosts.add(Post(
          id: postId,
          caption: json['caption'],
          imageUrl: json['image_url'],
          user: user,
          createdAt: DateTime.parse(json['created_at']),
          likes: likesCount,
          comments: commentsCount,
          tags: tags,
          isLiked: isLiked,
          isBookmarked: isBookmarked,
        ));
      }

      // Reset the fresh data flag since we've just loaded fresh data
      _needsFreshData = false;
      return processedPosts;
    } catch (e) {
      debugPrint('Error getting feed posts: $e');
      throw Exception('Failed to get feed posts: $e');
    }
  }

  // Get posts by user ID
  Future<List<Post>> getUserPosts(String userId) async {
    // Always check if we need fresh data first
    final isTimeToRefresh = DateTime.now().difference(_lastGlobalRefresh) >
        const Duration(minutes: 2);

    if (isTimeToRefresh) {
      _needsFreshData = true;
      _lastGlobalRefresh = DateTime.now();
      debugPrint('PostRepository: Global cache expired, refreshing user posts');
    }

    // Return cached posts if available and recent (not older than 1 minute)
    // and if we don't need fresh data
    if (!_needsFreshData &&
        _cachedUserPosts.containsKey(userId) &&
        _lastCacheTime.containsKey(userId) &&
        DateTime.now().difference(_lastCacheTime[userId]!) <
            const Duration(seconds: 30)) {
      debugPrint(
          'Returning cached posts for user $userId (cache age: ${DateTime.now().difference(_lastCacheTime[userId]!).inSeconds}s)');
      return _cachedUserPosts[userId]!;
    }

    try {
      debugPrint('Fetching fresh posts for user $userId');
      final currentUserId = _client.auth.currentUser?.id;

      // First get posts without likes check
      final response = await _client.from('posts').select('''
          *,
          user:user_id(
            id, 
            username, 
            email, 
            image_url, 
            email_verified, 
            created_at
          ),
          likes(count)
        ''').eq('user_id', userId).order('created_at', ascending: false);

      debugPrint('Found ${response.length} posts for user $userId');

      // Prepare a list to hold the processed posts
      List<Post> processedPosts = [];

      // Process each post individually
      for (final json in response) {
        final postId = json['id'] as String;

        // Parse user data
        final userData = json['user'] as Map<String, dynamic>;
        final user = Account.fromJson(userData);

        // Extract likes count
        int likesCount = 0;
        if (json['likes'] != null && (json['likes'] as List).isNotEmpty) {
          likesCount = (json['likes'][0]['count'] as int?) ?? 0;
        }

        // Check if current user liked this post
        bool isLiked = false;
        if (currentUserId != null) {
          final likesResponse = await _client
              .from('likes')
              .select('id')
              .eq('post_id', postId)
              .eq('user_id', currentUserId)
              .limit(1);
          isLiked = likesResponse.isNotEmpty;
        }

        // Check if current user bookmarked this post
        bool isBookmarked = false;
        if (currentUserId != null) {
          final bookmarksResponse = await _client
              .from('bookmarks')
              .select('id')
              .eq('post_id', postId)
              .eq('user_id', currentUserId)
              .limit(1);
          isBookmarked = bookmarksResponse.isNotEmpty;
        }

        // Extract tags
        List<String> tags = [];
        if (json['tags'] != null) {
          tags = List<String>.from(json['tags']);
        } else {
          // Extract hashtags from caption
          final regex = RegExp(r'#(\w+)');
          final matches = regex.allMatches(json['caption'] as String);
          tags = matches.map((match) => match.group(1)!).toList();
        }

        processedPosts.add(Post(
          id: postId,
          caption: json['caption'],
          imageUrl: json['image_url'],
          user: user,
          createdAt: DateTime.parse(json['created_at']),
          likes: likesCount,
          comments: json['comments'] ?? 0,
          tags: tags,
          isLiked: isLiked,
          isBookmarked: isBookmarked,
        ));
      }

      // Update cache
      _cachedUserPosts[userId] = processedPosts;
      _lastCacheTime[userId] = DateTime.now();
      _needsFreshData = false;

      return processedPosts;
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      throw Exception('Failed to get user posts: $e');
    }
  }

  // Get saved posts with improved handling
  Future<List<Post>> getSavedPosts() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        return [];
      }

      debugPrint('Fetching saved posts for user $currentUserId');

      final response = await _client.from('bookmarks').select('''
            post_id,
            post:posts(
              *,
              user:user_id(
                id, 
                username, 
                email, 
                image_url, 
                email_verified, 
                created_at
              ),
              likes(count),
              comments(count)
            )
          ''').eq('user_id', currentUserId);

      if (response.isEmpty) {
        debugPrint('No saved posts found');
        return [];
      }

      final List<Post> posts = [];

      // Process each bookmark
      for (final json in response) {
        if (json['post'] == null) continue;

        final postData = json['post'] as Map<String, dynamic>;
        try {
          final post = _parseSinglePost(postData, isBookmarked: true);
          posts.add(post);
        } catch (e) {
          debugPrint('Error parsing saved post: $e');
          // Continue to next post
        }
      }

      debugPrint('Successfully fetched ${posts.length} saved posts');
      return posts;
    } catch (e) {
      debugPrint('Error getting saved posts: $e');
      throw Exception('Failed to get saved posts: $e');
    }
  }

  // Process posts with user's like/bookmark information
  Future<List<Post>> _processPostsWithUserInfo(List<dynamic> postsData) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      return _parsePosts(postsData, [], []);
    }

    try {
      // Get all post IDs
      final postIds = postsData.map((post) => post['id'] as String).toList();

      // If no posts, return empty list
      if (postIds.isEmpty) {
        return [];
      }

      // Get likes by current user
      List<dynamic> userLikes = [];
      if (postIds.isNotEmpty) {
        userLikes = await _client
            .from('likes')
            .select('post_id')
            .eq('user_id', currentUserId)
            .eq('post_id', postIds);
      }

      // Get bookmarks by current user
      List<dynamic> userBookmarks = [];
      if (postIds.isNotEmpty) {
        userBookmarks = await _client
            .from('bookmarks')
            .select('post_id')
            .eq('user_id', currentUserId)
            .eq('post_id', postIds);
      }

      // Parse posts with user info
      return _parsePosts(postsData, userLikes, userBookmarks);
    } catch (e) {
      debugPrint('Error processing posts with user info: $e');
      // Return posts without user info as fallback
      return _parsePosts(postsData, [], []);
    }
  }

  // Create a new post
  Future<Post> createPost({
    required String caption,
    required File imageFile,
    List<String> tags = const [],
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Extract tags if not provided
      if (tags.isEmpty) {
        final extractedTags = _extractTagsFromCaption(caption);
        tags = extractedTags;
      }

      // Upload image
      final imageUrl = await _uploadPostImage(imageFile);

      // Create post in database
      final response = await _client.from('posts').insert({
        'user_id': userId,
        'caption': caption,
        'image_url': imageUrl,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
      }).select('''
            *,
            user:user_id(
              id, 
              username, 
              email, 
              image_url, 
              email_verified, 
              created_at
            ),
            likes(count),
            comments(count)
          ''').single();

      // Completely clear all caches to force fresh data
      clearCaches();

      debugPrint('Post created successfully, all caches cleared for refresh');

      return _parseSinglePost(response, isBookmarked: false);
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // Edit an existing post
  Future<Post> editPost({
    required String postId,
    required String caption,
    List<String> tags = const [],
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Extract tags if not provided
      if (tags.isEmpty) {
        final extractedTags = _extractTagsFromCaption(caption);
        tags = extractedTags;
      }

      // Update post in database
      final response = await _client
          .from('posts')
          .update({
            'caption': caption,
            'tags': tags,
          })
          .eq('id', postId)
          .eq('user_id', userId) // Ensure user owns the post
          .select('''
            *,
            user:user_id(
              id, 
              username, 
              email, 
              image_url, 
              email_verified, 
              created_at
            ),
            likes(count),
            comments(count)
          ''')
          .single();

      // Check if post is bookmarked
      final bookmarkResponse = await _client
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId);
      final isBookmarked = bookmarkResponse.isNotEmpty;

      // Clear all caches completely
      clearCaches();

      debugPrint('Post edited successfully, all caches cleared for refresh');

      return _parseSinglePost(response, isBookmarked: isBookmarked);
    } catch (e) {
      debugPrint('Error editing post: $e');
      throw Exception('Failed to edit post: $e');
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Delete post from database
      await _client
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId); // Ensure user owns the post

      // Clear all caches completely
      clearCaches();

      debugPrint('Post deleted successfully, all caches cleared for refresh');
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already liked
      final likeResponse = await _client
          .from('likes')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId);

      final isLiked = likeResponse.isNotEmpty;

      if (isLiked) {
        // Unlike
        await _client
            .from('likes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
      } else {
        // Like
        await _client.from('likes').insert({
          'user_id': userId,
          'post_id': postId,
        });
      }

      // Force fresh data on next feed/profile load
      _needsFreshData = true;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Toggle bookmark on a post with improved handling
  Future<void> toggleBookmark(String postId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Toggling bookmark for post $postId by user $userId');

      // Check if already bookmarked
      final bookmarkResponse = await _client
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId);

      final isBookmarked = bookmarkResponse.isNotEmpty;
      debugPrint('Is post currently bookmarked? $isBookmarked');

      if (isBookmarked) {
        // Remove bookmark
        await _client
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
        debugPrint('Bookmark removed');
      } else {
        // Add bookmark
        await _client.from('bookmarks').insert({
          'user_id': userId,
          'post_id': postId,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Bookmark added');
      }

      // Force fresh data on next feed/profile load
      _needsFreshData = true;
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  // Upload post image
  Future<String> _uploadPostImage(File imageFile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final imageExtension = imageFile.path.split('.').last.toLowerCase();
      final imageId =
          '${basename(imageFile.path)}_${DateTime.now().millisecondsSinceEpoch}';
      final imagePath = '$userId/$imageId';

      await _client.storage.from('posts').uploadBinary(
            imagePath,
            imageFile.readAsBytesSync(),
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$imageExtension',
            ),
          );

      final imageUrl = _client.storage.from('posts').getPublicUrl(imagePath);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Extract tags from caption
  List<String> _extractTagsFromCaption(String caption) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(caption);
    return matches.map((match) => match.group(1)!).toList();
  }

  // Parse multiple posts with user interaction info
  List<Post> _parsePosts(
    List<dynamic> postsData,
    List<dynamic> userLikes,
    List<dynamic> userBookmarks,
  ) {
    // Convert user likes and bookmarks to sets for faster lookup
    final likedPostIds =
        userLikes.map((like) => like['post_id'] as String).toSet();
    final bookmarkedPostIds =
        userBookmarks.map((bookmark) => bookmark['post_id'] as String).toSet();

    return postsData.map<Post>((json) {
      final postId = json['id'] as String;

      // Parse user data
      final userData = json['user'] as Map<String, dynamic>;
      final user = Account.fromJson(userData);

      // Extract likes count
      int likesCount = 0;
      if (json['likes'] != null && (json['likes'] as List).isNotEmpty) {
        likesCount = (json['likes'][0]['count'] as int?) ?? 0;
      }

      // Extract comments count
      int commentsCount = 0;
      if (json['comments'] != null && (json['comments'] as List).isNotEmpty) {
        commentsCount = (json['comments'][0]['count'] as int?) ?? 0;
      }

      // Extract tags
      List<String> tags = [];
      if (json['tags'] != null) {
        tags = List<String>.from(json['tags']);
      } else {
        // Extract hashtags from caption
        final regex = RegExp(r'#(\w+)');
        final matches = regex.allMatches(json['caption'] as String);
        tags = matches.map((match) => match.group(1)!).toList();
      }

      return Post(
        id: postId,
        caption: json['caption'],
        imageUrl: json['image_url'],
        user: user,
        createdAt: DateTime.parse(json['created_at']),
        likes: likesCount,
        comments: commentsCount,
        tags: tags,
        isLiked: likedPostIds.contains(postId),
        isBookmarked: bookmarkedPostIds.contains(postId),
      );
    }).toList();
  }

  // Parse single post
  Post _parseSinglePost(Map<String, dynamic> json,
      {required bool isBookmarked}) {
    // Parse user data
    final userData = json['user'] as Map<String, dynamic>;
    final user = Account.fromJson(userData);

    // Extract likes count
    int likesCount = 0;
    if (json['likes'] != null && (json['likes'] as List).isNotEmpty) {
      likesCount = (json['likes'][0]['count'] as int?) ?? 0;
    }

    // Extract comments count
    int commentsCount = 0;
    if (json['comments'] != null && (json['comments'] as List).isNotEmpty) {
      commentsCount = (json['comments'][0]['count'] as int?) ?? 0;
    }

    // Extract tags
    List<String> tags = [];
    if (json['tags'] != null) {
      tags = List<String>.from(json['tags']);
    } else {
      // Extract hashtags from caption
      final regex = RegExp(r'#(\w+)');
      final matches = regex.allMatches(json['caption'] as String);
      tags = matches.map((match) => match.group(1)!).toList();
    }

    // Check if current user liked this post
    bool isLiked = false;
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId != null) {
      // We'll need to check this separately since we can't use inner joins
      // This would be done in the _processPostsWithUserInfo method for multiple posts
    }

    return Post(
      id: json['id'],
      caption: json['caption'],
      imageUrl: json['image_url'],
      user: user,
      createdAt: DateTime.parse(json['created_at']),
      likes: likesCount,
      comments: commentsCount,
      tags: tags,
      isLiked: isLiked,
      isBookmarked: isBookmarked,
    );
  }
}
