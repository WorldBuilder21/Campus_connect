import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/home/model/comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final String postId;
  final SupabaseClient _supabase = Supabase.instance.client;

  CommentsNotifier(this.postId) : super(const AsyncValue.loading()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();

    try {
      // Fetch comments for this post with user relationships
      final response = await _supabase.from('comments').select('''
            *,
            user:user_id(
              id, 
              username, 
              email, 
              image_url, 
              email_verified, 
              created_at
            )
          ''').eq('post_id', postId).order('created_at', ascending: true);

      final currentUserId = _supabase.auth.currentUser?.id;
      final List<Comment> comments = [];

      for (final commentData in response) {
        final userData = commentData['user'] as Map<String, dynamic>;
        final user = Account.fromJson(userData);
        final commentId = commentData['id'];

        // Handle likes count and user like status
        int likesCount = 0;
        bool isLiked = false;

        try {
          // Get likes count
          final likesResponse = await _supabase
              .from('comment_likes')
              .select('*')
              .eq('comment_id', commentId);
          likesCount = likesResponse.length ?? 0;

          // Check if user liked this comment
          if (currentUserId != null) {
            final likeCheckResponse = await _supabase
                .from('comment_likes')
                .select()
                .eq('comment_id', commentId)
                .eq('user_id', currentUserId);
            isLiked = likeCheckResponse.isNotEmpty;
          }
        } catch (e) {
          // If the table doesn't exist or any other error, proceed with 0 likes
          debugPrint('Error getting likes: $e');
        }

        comments.add(Comment(
          id: commentId,
          postId: commentData['post_id'],
          user: user,
          content: commentData['content'],
          createdAt: DateTime.parse(commentData['created_at']),
          likes: likesCount,
          isLiked: isLiked,
        ));
      }

      state = AsyncValue.data(comments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addComment(String content) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Add comment to database
      final response = await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'content': content,
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
            )
          ''').single();

      // Get user data from response
      final userData = response['user'] as Map<String, dynamic>;
      final user = Account.fromJson(userData);

      // Create comment object
      final newComment = Comment(
        id: response['id'],
        postId: response['post_id'],
        user: user,
        content: response['content'],
        createdAt: DateTime.parse(response['created_at']),
        likes: 0,
        isLiked: false,
      );

      // Update state
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newComment]);
      } else {
        state = AsyncValue.data([newComment]);
      }

      // Update comments count on post
      try {
        await _supabase.rpc('increment_comments_count', params: {
          'post_id': postId,
        });
      } catch (e) {
        debugPrint('Failed to increment comments count: $e');
        // Continue anyway as this is not critical
      }
    } catch (e, stackTrace) {
      // If we already have comments, keep the current state and just report the error
      if (!state.hasValue) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow; // Let the UI handle the error display
    }
  }

  Future<void> toggleLike(String commentId) async {
    if (!state.hasValue) return;

    // Find the comment in our state
    final comments = [...state.value!];
    final index = comments.indexWhere((comment) => comment.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final isLiked = comment.isLiked;

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // First perform the database operation before updating the UI
      if (isLiked) {
        // Unlike
        await _supabase
            .from('comment_likes')
            .delete()
            .match({'user_id': currentUserId, 'comment_id': commentId});
      } else {
        // Like
        await _supabase
            .from('comment_likes')
            .insert({'user_id': currentUserId, 'comment_id': commentId});
      }

      // After successful DB operation, update the UI
      comments[index] = Comment(
        id: comment.id,
        postId: comment.postId,
        user: comment.user,
        content: comment.content,
        createdAt: comment.createdAt,
        likes: isLiked ? comment.likes - 1 : comment.likes + 1,
        isLiked: !isLiked,
      );

      state = AsyncValue.data(comments);
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // We don't need to revert the UI since we haven't updated it yet
    }
  }

  Future<void> deleteComment(String commentId) async {
    if (!state.hasValue) return;

    final comments = [...state.value!];
    final index = comments.indexWhere((comment) => comment.id == commentId);
    if (index == -1) return;

    // Store deleted comment for potential reverting
    final deletedComment = comments[index];

    try {
      // First delete from database
      await _supabase.from('comments').delete().eq('id', commentId);

      // Try to decrement comment count
      try {
        await _supabase.rpc('decrement_comments_count', params: {
          'post_id': postId,
        });
      } catch (e) {
        debugPrint('Failed to decrement comments count: $e');
        // Continue anyway as this is not critical
      }

      // After successful DB operation, update the UI
      comments.removeAt(index);
      state = AsyncValue.data(comments);
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      // We don't need to revert the UI since we haven't updated it yet
    }
  }
}
