import 'package:campus_conn/notifications/schemas/notification_schema.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

class NotificationRepository {
  final SupabaseClient _supabaseClient;

  NotificationRepository(this._supabaseClient);

  Future<List<Notification>> getNotifications(
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .select('''
            *,
            actor:actor_id(id, username, image_url)
          ''')
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      debugPrint('Notifications response: $response');

      return (response as List<dynamic>).map((item) {
        final actorData = item['actor'] as Map<String, dynamic>;

        return Notification(
          id: item['id'],
          userId: item['user_id'],
          actorId: item['actor_id'],
          actorUsername: actorData['username'],
          actorImageUrl: actorData['image_url'],
          type: _mapStringToNotificationType(item['type']),
          postId: item['post_id'],
          commentId: item['comment_id'],
          chatId: item['chat_id'],
          messageId: item['message_id'],
          content: item['content'],
          isRead: item['is_read'] ?? false,
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .count()
          .eq('is_read', false);

      return response;
    } catch (e) {
      debugPrint('Error getting unread notifications count: $e');
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabaseClient
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _supabaseClient
          .from('notifications')
          .update({'is_read': true}).eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Stream<List<Notification>> notificationsStream() {
    return _supabaseClient
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((event) {
          return event.map((item) {
            return Notification(
              id: item['id'],
              userId: item['user_id'],
              actorId: item['actor_id'],
              actorUsername: item['actor_username'] ?? 'Unknown',
              actorImageUrl: item['actor_image_url'],
              type: _mapStringToNotificationType(item['type']),
              postId: item['post_id'],
              commentId: item['comment_id'],
              chatId: item['chat_id'],
              messageId: item['message_id'],
              content: item['content'],
              isRead: item['is_read'] ?? false,
              createdAt: DateTime.parse(item['created_at']),
            );
          }).toList();
        });
  }

  NotificationType _mapStringToNotificationType(String type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.like;
    }
  }
}
