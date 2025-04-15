import 'package:campus_conn/notifications/schemas/notification_schema.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/notifications/api/notification_repository.dart';

// Provider to get all notifications
final notificationsProvider = FutureProvider<List<Notification>>((ref) async {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

// Provider to get unread notifications count
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  return ref
      .watch(notificationRepositoryProvider)
      .getUnreadNotificationsCount();
});

// Stream provider for real-time notifications
final notificationsStreamProvider = StreamProvider<List<Notification>>((ref) {
  return ref.watch(notificationRepositoryProvider).notificationsStream();
});

// Provider to manage pagination state
final notificationsPaginationProvider = StateNotifierProvider<
    NotificationsPaginationNotifier, NotificationsPaginationState>((ref) {
  return NotificationsPaginationNotifier(
      ref.watch(notificationRepositoryProvider));
});

class NotificationsPaginationState {
  final List<Notification> notifications;
  final bool isLoading;
  final bool hasReachedEnd;
  final String? error;

  NotificationsPaginationState({
    required this.notifications,
    required this.isLoading,
    required this.hasReachedEnd,
    this.error,
  });

  NotificationsPaginationState copyWith({
    List<Notification>? notifications,
    bool? isLoading,
    bool? hasReachedEnd,
    String? error,
  }) {
    return NotificationsPaginationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      error: error,
    );
  }
}

class NotificationsPaginationNotifier
    extends StateNotifier<NotificationsPaginationState> {
  final NotificationRepository _repository;
  int _page = 0;
  static const int _limit = 20;

  NotificationsPaginationNotifier(this._repository)
      : super(NotificationsPaginationState(
          notifications: [],
          isLoading: false,
          hasReachedEnd: false,
        )) {
    loadMoreNotifications();
  }

  Future<void> loadMoreNotifications() async {
    if (state.isLoading || state.hasReachedEnd) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final newNotifications = await _repository.getNotifications(
        limit: _limit,
        offset: _page * _limit,
      );

      final hasReachedEnd = newNotifications.length < _limit;
      _page++;

      state = state.copyWith(
        notifications: [...state.notifications, ...newNotifications],
        isLoading: false,
        hasReachedEnd: hasReachedEnd,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> refreshNotifications() async {
    _page = 0;
    state = NotificationsPaginationState(
      notifications: [],
      isLoading: false,
      hasReachedEnd: false,
    );
    await loadMoreNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markNotificationAsRead(notificationId);

      // Update the state locally
      state = state.copyWith(
        notifications: state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return Notification(
              id: notification.id,
              userId: notification.userId,
              actorId: notification.actorId,
              actorUsername: notification.actorUsername,
              actorImageUrl: notification.actorImageUrl,
              type: notification.type,
              postId: notification.postId,
              commentId: notification.commentId,
              chatId: notification.chatId,
              messageId: notification.messageId,
              content: notification.content,
              isRead: true,
              createdAt: notification.createdAt,
            );
          }
          return notification;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mark notification as read: $e',
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllNotificationsAsRead();

      // Update the state locally
      state = state.copyWith(
        notifications: state.notifications.map((notification) {
          return Notification(
            id: notification.id,
            userId: notification.userId,
            actorId: notification.actorId,
            actorUsername: notification.actorUsername,
            actorImageUrl: notification.actorImageUrl,
            type: notification.type,
            postId: notification.postId,
            commentId: notification.commentId,
            chatId: notification.chatId,
            messageId: notification.messageId,
            content: notification.content,
            isRead: true,
            createdAt: notification.createdAt,
          );
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mark all notifications as read: $e',
      );
    }
  }
}
